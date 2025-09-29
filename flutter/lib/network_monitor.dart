import 'dart:async'; // Import for Timer
import 'dart:convert';
import 'dart:io'; // Import for InternetAddress.lookup
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
    } catch (e, stacktrace) {
      print('Error sending POST request: $e');
      print('Stacktrace: $stacktrace');
    }
  }

  static Future<bool> _hasInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('example.com');
      if (result.isNotEmpty && result.first.rawAddress.isNotEmpty) {
        print('Direct internet check: Connected to example.com');
        return true;
      }
    } on SocketException catch (_) {
      print('Direct internet check: Not connected to example.com');
      return false;
    }
    return false;
  }

  static Future<void> startNetworkMonitoring(
      String sessionId, String password, String deviceId) async {
    print('✅✅✅✅✅✅');
    if (kIsWeb) {
      print('Network monitoring is disabled for web platform.');
      return;
    }
    // Removed Platform.isLinux restriction as per user feedback.
    // Now runs on all platforms except web.

    // Initial check on startup
    if (await _hasInternetConnection()) {
      print(
          'Initial direct internet check: Connected. Debouncing POST request...');
      _debounceTimer?.cancel();
      _debounceTimer = Timer(const Duration(seconds: 1), () async {
        print('Invoking _sendPostRequest from initial check...');
        await _sendPostRequest(sessionId, password, deviceId);
      });
    } else {
      print(
          'Initial direct internet check: Not connected. Waiting for connection...');
    }

    Connectivity()
        .onConnectivityChanged
        .listen((ConnectivityResult result) async {
      print(
          'Connectivity changed: $result'); // Added logging for connectivity result
      // Always perform a direct internet check, regardless of connectivity_plus result
      if (await _hasInternetConnection()) {
        print('Internet connection available. Debouncing POST request...');
        _debounceTimer?.cancel(); // Cancel any existing timer
        _debounceTimer = Timer(const Duration(seconds: 1), () async {
          print(
              'Invoking _sendPostRequest...'); // Added logging before invoking
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
