import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:get/get.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hbb/utils/xconnect_tcp_manager.dart'; // Ensure this import path is correct

class Device {
  final String ip;
  final int port;

  // Rx types for reactivity
  final RxnString sessionId;
  final RxnString password;
  final RxnString deviceId;
  final RxnString name;
  final RxString tcpStatus;
  final Rx<DateTime> lastSeen;

  Device({
    required this.ip,
    required this.port,
    String? sessionId,
    String? password,
    String? deviceId,
    String? name,
    String initialTcpStatus = 'Ready',
  })  : sessionId = RxnString(sessionId),
        password = RxnString(password),
        deviceId = RxnString(deviceId),
        name = RxnString(name),
        tcpStatus = initialTcpStatus.obs,
        lastSeen = DateTime.now().obs;

  factory Device.fromJson(Map<String, dynamic> json, String ip, int port) {
    return Device(
      ip: ip,
      port: port,
      sessionId: json['session_id'],
      password: json['password'],
      deviceId: json['device_id'],
      name: json['name'],
      initialTcpStatus: 'Ready',
    );
  }

  // Efficiently update existing device instead of replacing object
  void updateFromJson(Map<String, dynamic> json) {
    sessionId.value = json['session_id'];
    password.value = json['password'];
    deviceId.value = json['device_id'];
    name.value = json['name'];
    // CRITICAL: Always update timestamp to prevent removal
    lastSeen.value = DateTime.now();
  }

  String get schoolName {
    if (deviceId.value != null && deviceId.value!.length > 6) {
      return deviceId.value!.substring(0, deviceId.value!.length);
    }
    return deviceId.value ?? name.value ?? ip;
  }
}

class DeviceDiscoveryController extends GetxController {
  static const _nativeChannel = MethodChannel('mChannel');

  RxList<Device> discoveredDevices = <Device>[].obs;
  RxBool isLoading = false.obs;
  RxString statusText = 'Initializing...'.obs;

  RawDatagramSocket? _broadcastSocket;
  StreamSubscription? _messageSubscription;

  Timer? _broadcastTimer;
  Timer? _livenessTimer;

  // --- CONFIGURATION ---
  final int _sharedPort = 64546;
  final String _broadcastAddress = '255.255.255.255';
  final String _anybodyAliveMessage = '{"type": "anybody_alive"}';

  // TIMING STRATEGY: Fast Pulse, Slow Decay
  // 1. Send requests frequently (every 2s) so devices respond often.
  final Duration _broadcastInterval = const Duration(seconds: 2);

  // 2. Check for dead devices often (every 3s).
  final Duration _checkInterval = const Duration(seconds: 3);

  // 3. Wait longer before removing (8s).
  // This allows missing ~3 packets before the device disappears from UI.
  final int _deviceTimeoutSeconds = 8;

  @override
  void onInit() {
    super.onInit();
    debugPrint('[UI] DeviceDiscoveryController initialized');

    // Listen for replies from devices (via TCP Manager)
    _messageSubscription =
        XConnectTcpManager.to.messageStream.listen((message) {
      if (message['type'] == 'iam_alive') {
        _handleIamAlive(message, message['remoteIp']);
      }
    });

    // Reactive status text
    discoveredDevices.listen((devices) {
      if (devices.isEmpty) {
        if (!isLoading.value) statusText.value = 'No devices available';
      } else {
        statusText.value = '';
        isLoading.value = false;
      }
    });

    // Start the janitor process to remove old devices
    _livenessTimer =
        Timer.periodic(_checkInterval, (timer) => _checkDeviceLiveness());
  }

  void clearDevices() {
    discoveredDevices.clear();
  }

  void refreshDiscovery() async {
    clearDevices();
    await startDiscovery();
  }

  Future<void> startDiscovery() async {
    if (isLoading.value) return;
    isLoading.value = true;
    statusText.value = 'Finding devices...';
    clearDevices();

    // Android specific: Acquire Multicast Lock to allow UDP broadcast reception
    if (Platform.isAndroid) {
      try {
        await _nativeChannel.invokeMethod('acquire_multicast_lock');
        debugPrint('[Android] Multicast lock acquired successfully.');
      } catch (e) {
        debugPrint('[Android] ❌ Failed to acquire multicast lock: $e');
      }
    }

    await _startDiscoveryService();
  }

  Future<void> _startDiscoveryService() async {
    // 1. Start UDP Broadcast
    await _startUdpBroadcaster();

    // 2. Initial UI Timeout logic
    // Just to turn off the "Loading" spinner if nothing is found initially
    Future.delayed(const Duration(seconds: 6), () {
      if (isLoading.value) {
        isLoading.value = false;
        if (discoveredDevices.isEmpty) {
          statusText.value = 'No devices available';
        }
      }
    });
  }

  void _handleIamAlive(Map<String, dynamic> json, String remoteIp) {
    final deviceId = json['device_id'];
    // Linux might send 0.0.0.0, so we use the actual TCP socket address
    final deviceIp =
        (json['ip'] == '0.0.0.0' || json['ip'] == null) ? remoteIp : json['ip'];

    final existingIndex = discoveredDevices.indexWhere((d) => d.ip == deviceIp);

    if (existingIndex != -1) {
      // Update existing device (refreshes lastSeen timestamp)
      discoveredDevices[existingIndex].updateFromJson(json);
      discoveredDevices.refresh();
      // debugPrint('[Discovery] Updated device: $deviceIp');
    } else {
      // Add new device
      final newDevice = Device.fromJson(json, deviceIp, 12345);
      discoveredDevices.add(newDevice);
      debugPrint('[Discovery] Found new device: $deviceIp ($deviceId)');
    }
  }

  // --- UDP BROADCASTER ---
  Future<void> _startUdpBroadcaster() async {
    if (_broadcastSocket != null) return;

    try {
      _broadcastSocket =
          await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      _broadcastSocket?.broadcastEnabled = true;
      debugPrint('[UDP] Broadcast socket ready.');
    } catch (e) {
      debugPrint('[UDP] Failed to create broadcast socket: $e');
      _updateStatusOnError('UDP Socket Error');
      return;
    }

    _broadcastTimer?.cancel();
    _broadcastTimer = Timer.periodic(_broadcastInterval, (timer) {
      _sendBroadcast();
    });

    // BURST MODE: Send 3 packets rapidly at start to ensure immediate discovery
    _sendBroadcast();
    Future.delayed(const Duration(milliseconds: 400), _sendBroadcast);
    Future.delayed(const Duration(milliseconds: 800), _sendBroadcast);
  }

  void _sendBroadcast() {
    if (_broadcastSocket == null) return;
    try {
      // debugPrint('[UDP] 🛰️ Ping...');
      _broadcastSocket?.send(
        utf8.encode(_anybodyAliveMessage),
        InternetAddress(_broadcastAddress),
        _sharedPort,
      );
    } catch (e) {
      debugPrint('[UDP] Send error: $e');
    }
  }

  void _checkDeviceLiveness() {
    final now = DateTime.now();
    bool removedAny = false;

    discoveredDevices.removeWhere((device) {
      final diff = now.difference(device.lastSeen.value).inSeconds;
      // Use the 8-second threshold
      if (diff > _deviceTimeoutSeconds) {
        debugPrint(
            '[Discovery] Removing inactive device: ${device.ip} (Inactive for ${diff}s)');
        removedAny = true;
        return true;
      }
      return false;
    });

    if (removedAny && discoveredDevices.isEmpty) {
      statusText.value = 'No devices available';
    }
  }

  void _updateStatusOnError(String message) {
    isLoading.value = false;
    statusText.value = 'Error: $message';
  }

  @override
  void onClose() {
    if (Platform.isAndroid) {
      try {
        _nativeChannel.invokeMethod('release_multicast_lock');
        debugPrint('[Android] Multicast lock released.');
      } catch (e) {
        debugPrint('[Android] ❌ Failed to release multicast lock: $e');
      }
    }

    _messageSubscription?.cancel();
    _broadcastTimer?.cancel();
    _livenessTimer?.cancel();
    _broadcastSocket?.close();
    super.onClose();
  }
}
