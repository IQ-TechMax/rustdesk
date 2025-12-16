import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:get/get.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hbb/utils/xconnect_tcp_manager.dart';

class Device {
  // IP and port are final because they define the device's identity/endpoint
  // and are unlikely to change during a session.
  final String ip;
  final int port;

  // Make all mutable properties observable using Rx types.
  // Use RxnString for nullable strings.
  final RxnString sessionId;
  final RxnString password;
  final RxnString deviceId;
  final RxnString name;
  final RxString tcpStatus;
  final Rx<DateTime> lastSeen; // Use Rx<DateTime> for the DateTime object

  Device({
    required this.ip,
    required this.port,
    String? sessionId,
    String? password,
    String? deviceId,
    String? name,
    String initialTcpStatus = 'Ready',
  })  : this.sessionId = RxnString(sessionId),
        this.password = RxnString(password),
        this.deviceId = RxnString(deviceId),
        this.name = RxnString(name),
        this.tcpStatus = initialTcpStatus.obs,
        this.lastSeen = DateTime.now().obs; //

// The factory constructor remains the same for creating new instances.
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

  // **NEW**: Add an update method to change property values.
  // This is much more efficient than creating a new Device object.
  void updateFromJson(Map<String, dynamic> json) {
    // Update the values of the observable properties.
    // This will automatically trigger UI updates in widgets that are listening.
    sessionId.value = json['session_id'];
    password.value = json['password'];
    deviceId.value = json['device_id'];
    name.value = json['name'];
    lastSeen.value = DateTime.now(); // Always update lastSeen on new data
  }

  String get schoolName {
    // No changes needed here, but note that this getter is not reactive by itself.
    // The UI will update because it depends on deviceId, which IS reactive.
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

  RawDatagramSocket? _broadcastSocket; // Only for sending UDP
  StreamSubscription? _messageSubscription;

  Timer? _broadcastTimer;
  Timer? _livenessTimer;

  final int _sharedPort = 64546; // UDP Send Port AND TCP Listen Port
  final String _broadcastAddress = '255.255.255.255';
  final String _anybodyAliveMessage = '{"type": "anybody_alive"}';

  @override
  void onInit() {
    super.onInit();
    debugPrint('[UI] DeviceDiscoveryController initialized');

    _messageSubscription =
        XConnectTcpManager.to.messageStream.listen((message) {
      if (message['type'] == 'iam_alive') {
        _handleIamAlive(message, message['remoteIp']);
      }
    });

    // Status listener
    discoveredDevices.listen((devices) {
      if (devices.isEmpty) {
        if (!isLoading.value) statusText.value = 'No devices available';
      } else {
        statusText.value = '';
        isLoading.value = false;
      }
    });

    _livenessTimer = Timer.periodic(
        const Duration(seconds: 10), (timer) => _checkDeviceLiveness());
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
    // 1. Start UDP Broadcast (To shout "Anybody out there?")
    await _startUdpBroadcaster();

    // 2. UI Timeout logic
    Future.delayed(const Duration(seconds: 10), () {
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
      // Update existing
      discoveredDevices[existingIndex].updateFromJson(json);
      discoveredDevices.refresh(); // Trigger UI update
      debugPrint('[Discovery] Updated device: $deviceIp');
    } else {
      // Add new
      final newDevice = Device.fromJson(json, deviceIp,
          12345); // Port 12345 is standard, or read from json['port']
      discoveredDevices.add(newDevice);
      debugPrint('[Discovery] Found new device: $deviceIp ($deviceId)');
    }
  }

  // --- UDP BROADCASTER (Sends Requests) ---
  Future<void> _startUdpBroadcaster() async {
    if (_broadcastSocket != null) return;

    try {
      _broadcastSocket =
          await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      _broadcastSocket?.broadcastEnabled = true;
      debugPrint('[UDP] Broadcast socket ready.');
    } catch (e) {
      debugPrint('[UDP] Failed to create broadcast socket: $e');
      return;
    }

    _broadcastTimer?.cancel();
    _broadcastTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _sendBroadcast();
    });
    _sendBroadcast(); // Send immediately
  }

  void _sendBroadcast() {
    if (_broadcastSocket == null) return;
    try {
      debugPrint(
          '[UDP] 🛰️ Sending "anybody_alive" to $_broadcastAddress:$_sharedPort');
      _broadcastSocket?.send(
        utf8.encode(_anybodyAliveMessage),
        InternetAddress(_broadcastAddress),
        _sharedPort, // Destination Port (Linux is listening here)
      );
    } catch (e) {
      debugPrint('[UDP] Send error: $e');
    }
  }

  void _checkDeviceLiveness() {
    final now = DateTime.now();
    discoveredDevices.removeWhere((device) {
      // If we haven't seen them in 10 seconds, remove them
      return now.difference(device.lastSeen.value).inSeconds > 10;
    });
  }

  void _updateStatusOnError(String message) {
    isLoading.value = false;
    statusText.value = 'Error: $message';
  }

  @override
  void onClose() {
    // Release the lock when the controller is closed
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
