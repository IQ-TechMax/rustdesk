import 'dart:async'; // Import for Timer
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;

class NetworkMonitor {
  static const String _apiUrl =
      'https://dev.xwall.io/public/api/updateRemoteDetails';
  static Timer? _debounceTimer; // Debounce timer for network changes

  static Future<void> _sendPostRequest(
      String sessionId, String password, String deviceId) async {
    final Map<String, String> requestBody = {
      "serialnumber": deviceId, // Using deviceId for serialNumber
      "sessionid": sessionId,
      "password": password,
      "status": "online"
    };
    print('Sending POST request with:');
    print('  URL: $_apiUrl');
    print('  Session ID: $sessionId');
    print('  Password: $password');
    print('  Request Body: $requestBody');
    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        print('POST Request Successful:');
        print('  URL: $_apiUrl');
        print('  Method: POST');
        print('  Request Body: $requestBody');
      } else {
        print('POST Request Failed with status: ${response.statusCode}');
      }
    } catch (e) {
      print('Error sending POST request: $e');
    }
  }

  static void startNetworkMonitoring(
      String sessionId, String password, String deviceId) {
    if (kIsWeb) {
      print('Network monitoring is disabled for web platform.');
      return;
    }
    // Removed Platform.isLinux restriction as per user feedback.
    // Now runs on all platforms except web.

    Connectivity()
        .onConnectivityChanged
        .listen((ConnectivityResult result) async {
      if (result != ConnectivityResult.none) {
        print('Internet connection available. Debouncing POST request...');
        _debounceTimer?.cancel(); // Cancel any existing timer
        _debounceTimer = Timer(const Duration(seconds: 1), () async {
          await _sendPostRequest(sessionId, password, deviceId);
        });
      } else {
        print('Internet connection lost. Waiting for connection...');
        _debounceTimer
            ?.cancel(); // Cancel any pending request if connection is lost
      }
    });
  }
}
