import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:get/get.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hbb/utils/multi_window_manager.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter_hbb/consts.dart';

enum ConnectionType { incoming, outgoing }

class Device {
  final String ip;
  final int port;

  // Rx types for reactivity
  final RxnString deviceId;
  final RxnBool isConnected;
  final Rx<ConnectionType?> connectionType;
  final RxnString sessionId;
  final Rx<DateTime> lastSeen;

  Device({
    required this.ip,
    required this.port,
    String? deviceId,
    ConnectionType? connectionType,
    bool? isConnected,
    String? sessionId,
  })  : deviceId = RxnString(deviceId),
        lastSeen = DateTime.now().obs,
        isConnected = RxnBool(isConnected ?? false),
        connectionType = Rx<ConnectionType?>(connectionType),
        sessionId = RxnString(sessionId);

  factory Device.fromJson(Map<String, dynamic> json, String ip, int port) {
    return Device(
      ip: ip,
      port: port,
      deviceId: json['device_id'],
      isConnected: json['is_connected'] == true ? true : false,
      connectionType: json['connection_type'] == 'incoming'
          ? ConnectionType.incoming
          : json['connection_type'] == 'outgoing'
              ? ConnectionType.outgoing
              : null,
      sessionId: json['session_id'],
    );
  }

  // Efficiently update existing device instead of replacing object
  void updateFromJson(Map<String, dynamic> json) {
    deviceId.value = json['device_id'];
    isConnected.value = json['is_connected'] == true ? true : false;
    connectionType.value = json['connection_type'] == 'incoming'
        ? ConnectionType.incoming
        : json['connection_type'] == 'outgoing'
            ? ConnectionType.outgoing
            : null;
    sessionId.value = json['session_id'];
    // CRITICAL: Always update timestamp to prevent removal
    lastSeen.value = DateTime.now();
  }

  String get schoolName {
    if (deviceId.value != null && deviceId.value!.length > 6) {
      return deviceId.value!.substring(0, deviceId.value!.length);
    }
    return deviceId.value ?? ip;
  }
}

class DeviceDiscoveryController extends GetxController {
  static const _nativeChannel = MethodChannel('mChannel');

  RxList<Device> discoveredDevices = <Device>[].obs;
  RxBool isLoading = false.obs;
  RxString statusText = 'Initializing...'.obs;

  RawDatagramSocket? _broadcastSocket;
  ServerSocket? _tcpListenerSocket;

  Timer? _broadcastTimer;
  Timer? _livenessTimer;

  // --- CONFIGURATION ---
  final int _sharedPort = 64546;
  final String _broadcastAddress = '255.255.255.255';
  final String _anybodyAliveMessage = '{"type": "anybody_alive"}';

  // TIMING STRATEGY: Fast Pulse, Slow Decay
  // 1. Send requests frequently (every 2s) so devices respond often.
  final Duration _broadcastInterval = const Duration(seconds: 2);

  // 2. Check for dead devices often (every 2s).
  final Duration _checkInterval = const Duration(seconds: 2);

  // 3. Wait longer before removing (5s).
  // This allows missing ~2 packets before the device disappears from UI.
  final int _deviceTimeoutSeconds = 5;

  @override
  void onInit() {
    super.onInit();
    debugPrint('[UI] DeviceDiscoveryController initialized');

    // Listen for replies from devices (via TCP Manager)
    _startTCPListener();

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

  Future<void> _startTCPListener() async {
    try {
      _tcpListenerSocket = await ServerSocket.bind(
          InternetAddress.anyIPv4, _sharedPort,
          shared: true);
      debugPrint('✅ TCP Server listening on port $_sharedPort');

      _tcpListenerSocket!.listen((Socket client) {
        debugPrint(
            'Receiving self originated TCP request from client: ${client.remoteAddress.address}');
        client.listen(
          (data) {
            try {
              final responseStr = utf8.decode(data);
              final Map<String, dynamic> json = jsonDecode(responseStr);
              // Main server only handles broadcast-like messages
              if (json['transaction_id'] == null) {
                _handleIamAlive(json);
              }

              debugPrint('Received TCP message details : $json');
            } catch (e) {
              debugPrint('‼️ Error parsing data: $e');
            }
          },
          onDone: () {
            debugPrint('Successfully Received message from client');
            client.destroy();
          },
          onError: (error) {
            debugPrint('‼️ Socket error: $error');
            client.destroy();
          },
        );
      });
    } catch (e) {
      debugPrint('‼️ FATAL: Could not bind server to port $_sharedPort: $e');
    }
  }

  void _handleIamAlive(Map<String, dynamic> json) async {
    final deviceId = json['device_id'];
    // Linux might send 0.0.0.0, so we use the actual TCP socket address
    final deviceIp = json['ip'];
    final devicePort = json['port'];

    final existingIndex = discoveredDevices.indexWhere((d) => d.ip == deviceIp);

    if (json['is_connected'] == true) {
      json['is_connected'] = true;
      json['connection_type'] = 'incoming';
      json['session_id'] = null;
    } else if (Platform.isWindows || Platform.isLinux) {
      // Check if connected via remote window ( outgoing connection )
      var connectedRemoteIps = [];
      var sessionIdLookup = {};
      try {
        final sessionIdList = await DesktopMultiWindow.invokeMethod(
            WindowType.RemoteDesktop.index, kWindowEventGetSessionIdList, null);

        debugPrint('All sub window Session IDs: $sessionIdList');

        if (sessionIdList == null || sessionIdList.isEmpty) {
          throw 'No remote windows found';
        }

        for (final peerIdAndSessionId in sessionIdList.split(';')) {
          final parts = peerIdAndSessionId.split(',');
          sessionIdLookup[parts[0]] = parts[1];
          connectedRemoteIps.add(parts[0]);
        }
      } catch (e) {
        debugPrint('Error listing windows: $e');
      }

      final isConnected = connectedRemoteIps.contains('$deviceIp:$devicePort');
      if (isConnected) {
        debugPrint(
            '[Discovery] Device $deviceIp is connected via remote window.');
        json['is_connected'] = true;
        json['connection_type'] = 'outgoing';
        json['session_id'] = sessionIdLookup['$deviceIp:$devicePort'] ?? null;
      }
    }

    if (existingIndex != -1) {
      // Update existing device (refreshes lastSeen timestamp)
      discoveredDevices[existingIndex].updateFromJson(json);
      discoveredDevices.refresh();
      // debugPrint('[Discovery] Updated device: $deviceIp');
    } else {
      // Add new device
      final newDevice = Device.fromJson(json, deviceIp, devicePort);
      discoveredDevices.add(newDevice);
      debugPrint('[Discovery] Found new device: $deviceIp ($deviceId)');
    }
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
    Future.delayed(const Duration(seconds: 5), () {
      if (isLoading.value) {
        isLoading.value = false;
        if (discoveredDevices.isEmpty) {
          statusText.value = 'No devices available';
        }
      }
    });
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

    _broadcastTimer?.cancel();
    _livenessTimer?.cancel();
    _broadcastSocket?.close();
    _tcpListenerSocket?.close();
    super.onClose();
  }
}
