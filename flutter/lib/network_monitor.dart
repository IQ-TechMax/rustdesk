import 'dart:async'; // Import for Timer
import 'dart:convert';
import 'dart:io'; // Import for InternetAddress.lookup
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_hbb/models/platform_model.dart';

class NetworkMonitor {
  static const String _apiUrl =
      'https://web.xwall.io/public/api/updateRemoteDetails';
  static Timer? _debounceTimer; // Debounce timer for network changes

  static Future<void> _sendPostRequest(
    String sessionId, String password, String deviceId) async {
  
    final Map<String, String> requestBody = {
      'serialnumber': deviceId,
      'sessionid': sessionId,
      'password': password,
      'status': 'online'
    };
  
    print('Sending POST request to: $_apiUrl');
    print('  Serial: $deviceId');
    print('  Session ID: $sessionId');
    // print('  Password: $password'); // Don't log passwords!
  
    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded'
        },
        // FIX: Pass the Map directly. Do NOT use jsonEncode.
        // The http package will automatically convert this to x-www-form-urlencoded
        body: requestBody, 
      );
  
      if (response.statusCode == 200) {
        // Parse the JSON response from the server
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        
        print('✅ POST Request Successful');
        print('  Message: ${responseData['message']}');
        print('  Device Name Recieved: ${responseData['deviceName']}');

        if (responseData != null && responseData['deviceName'] != null && responseData['deviceName'] != '') {
          await bind.setXConnectDeviceName(value: responseData['deviceName']);
        }
      } else {
        print('❌ POST Request Failed with status: ${response.statusCode}');
        print('  Response: ${response.body}');
      }
    } catch (e, stacktrace) {
      print('❌ Error sending POST request: $e');
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
