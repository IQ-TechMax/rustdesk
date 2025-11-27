import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:get/get.dart';

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
      return 'Device ID: ${deviceId.value!.substring(deviceId.value!.length - 6)}';
    }
    return deviceId.value ?? name.value ?? ip;
  }
  
}

class DeviceDiscoveryController extends GetxController {
  RxList<Device> discoveredDevices = <Device>[].obs;
  RxBool isLoading = false.obs;
  RxString statusText = 'Initializing...'.obs;
  RawDatagramSocket? _broadcastSocket;
  RawDatagramSocket? _listenSocket;
  Timer? _broadcastTimer;
  Timer? _livenessTimer;
  final int _udpBroadcastPort = 64545;
  final int _udpListenPort = 64546;
  final String _broadcastAddress = '255.255.255.255';
  final String _anybodyAliveMessage = '{"type": "anybody_alive"}';

  @override
  void onInit() {
    super.onInit();
    debugPrint('[UI] DeviceDiscoveryController initialized');
    // Add a listener to update UI based on device discovery
    discoveredDevices.listen((devices) {
      if (devices.isEmpty) {
        if (!isLoading.value) {
          statusText.value = 'No devices available';
        }
      } else {
        statusText.value = ''; // Clear status text when devices are found
        isLoading.value = false; // Stop loading indicator
      }
    });
    _livenessTimer =
        Timer.periodic(const Duration(seconds: 10), (_) => _checkDeviceLiveness());
  }

  void clearDevices() {
    discoveredDevices.clear();
    debugPrint('[UI] Cleared previously found devices');
  }

  void refreshDiscovery() async {
    debugPrint('[UDP] Manual refresh → restarting discovery');
    clearDevices();
    await startDiscovery();
    debugPrint('[UI] Discovery started (manual refresh)');
  }

  Future<void> startDiscovery() async {
    if (isLoading.value) {
      debugPrint('[UI] Discovery already in progress, skipping new request.');
      return;
    }
    debugPrint('[UI] Device discovery is loading');
    isLoading.value = true;
    statusText.value = 'Finding devices...';
    clearDevices();
    await _startUdpDiscoveryWindows();
  }

  Future<void> _startUdpDiscoveryWindows() async {
    debugPrint('[UDP] Discovery started');
    await _initializeSockets();
    _startBroadcasting();
    // The listener will now handle status updates, so we can simplify this.
    // We just need to handle the initial loading state.
    Future.delayed(const Duration(seconds: 10), () {
      if (isLoading.value) {
        isLoading.value = false;
        if (discoveredDevices.isEmpty) {
          statusText.value = 'No devices available';
        }
      }
    });
  }

  Future<void> _initializeSockets() async {
    if (_listenSocket == null) {
      try {
        _listenSocket = await RawDatagramSocket.bind(
            InternetAddress.anyIPv4, _udpListenPort);
        debugPrint(
            '[UDP] Listening socket bound to anyIPv4:$_udpListenPort');
        _listenForDevices(); // Attach listener only once
      } catch (e) {
        debugPrint(
            '[UDP] Failed to bind listening socket to anyIPv4, trying loopback: $e');
        try {
          _listenSocket = await RawDatagramSocket.bind(
              InternetAddress.loopbackIPv4, _udpListenPort);
          debugPrint(
              '[UDP] Listening socket bound to loopback:$_udpListenPort');
          _listenForDevices(); // Attach listener only once
        } catch (e) {
          debugPrint('[UDP] Failed to bind listening socket: $e');
          _updateStatusOnError('Failed to start listener.');
          return;
        }
      }
    }

    if (_broadcastSocket == null) {
  try {
    // Bind explicitly to your broadcast port
    _broadcastSocket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, _udpBroadcastPort);
    _broadcastSocket?.broadcastEnabled = true;
    debugPrint('[UDP] Broadcast socket created and bound to port $_udpBroadcastPort');
  } catch (e) {
    debugPrint('[UDP] Failed to create broadcast socket on $_udpBroadcastPort: $e, falling back to port 0');
    // Keep fallback in case the port is busy
    _broadcastSocket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    _broadcastSocket?.broadcastEnabled = true;
  }
}
  }

  void _startBroadcasting() {
  _broadcastTimer?.cancel();
  _broadcastTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
    // Change _udpBroadcastPort to _udpListenPort
    debugPrint( '[UDP] 🛰️ Broadcasting anybody_alive to $_broadcastAddress:$_udpListenPort');
    _broadcastSocket?.send(
      utf8.encode(_anybodyAliveMessage),
      InternetAddress(_broadcastAddress),
      _udpListenPort,
    );
  });
  // Initial broadcast
  // Change _udpBroadcastPort to _udpListenPort
  debugPrint( '[UDP] 🛰️ Broadcasting anybody_alive to $_broadcastAddress:$_udpListenPort');
  _broadcastSocket?.send(
    utf8.encode(_anybodyAliveMessage),
    InternetAddress(_broadcastAddress),
    _udpListenPort,
  );
}

  void _listenForDevices() {
    debugPrint('[UDP] 👂 Listening for iam_alive responses on port $_udpListenPort...');
    _listenSocket?.listen((RawSocketEvent event) {
      if (event == RawSocketEvent.read) {
        Datagram? datagram = _listenSocket?.receive();
        if (datagram != null) {
          try {
            final String receivedMessage = utf8.decode(datagram.data);
            final Map<String, dynamic> json = jsonDecode(receivedMessage);

            if (json['type'] == 'iam_alive') {
              final deviceId = json['device_id'];
              final existingDeviceIndex = discoveredDevices
                  .indexWhere((d) => d.deviceId == deviceId);

              if (existingDeviceIndex != -1) {
                // Device already exists, update it
                discoveredDevices[existingDeviceIndex] = Device.fromJson(
                    json, datagram.address.address, 12345); 

                debugPrint('[UDP] Received iam_alive from existing device with ip address = ${datagram.address.address} and password = ${json['password']}');
                // Optional: refresh the list to notify listeners of the change
                discoveredDevices.refresh();
                
              } else {
                // New device, add it to the list
                debugPrint(
                    '[UDP] Received iam_alive from ${datagram.address.address}:${datagram.port} with password = ${json['password']}');
                final newDevice = Device.fromJson(
                    json, datagram.address.address, 12345); // Use TCP port
                discoveredDevices.add(newDevice);
                debugPrint(
                    '[UI] Device discovered → {ip: ${newDevice.ip}, device_id: ${newDevice.deviceId}}');
              }
            }
          } catch (e) {
            debugPrint('[UDP] Error processing received data: $e');
          }
        }
      }
    });
  }

  void _checkDeviceLiveness() {
    final now = DateTime.now();
    discoveredDevices.removeWhere((device) {
      final isStale = now.difference(device.lastSeen.value).inSeconds > 30;
      if (isStale) {
        debugPrint(
            '[UI] Removing stale device → {ip: ${device.ip}, device_id: ${device.deviceId}}');
      }
      return isStale;
    });
  }

  void _updateStatusOnError(String message) {
    isLoading.value = false;
    statusText.value = 'Error: $message';
    debugPrint('[UI] Discovery error: $message');
    _broadcastSocket?.close();
    _listenSocket?.close();
    _broadcastTimer?.cancel();
  }

  @override
  void onClose() {
    _broadcastTimer?.cancel();
    _livenessTimer?.cancel();
    _broadcastSocket?.close();
    _listenSocket?.close();
    debugPrint('[UI] DeviceDiscoveryController closed');
    super.onClose();
  }
}