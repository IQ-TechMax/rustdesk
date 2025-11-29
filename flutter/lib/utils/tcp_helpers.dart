import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_hbb/common.dart';
import 'package:flutter_hbb/main.dart'; // Ensure globalKey is accessible

class TcpHelper {
  static const int _timeoutSeconds = 5;

  static Future<Map<String, dynamic>?> sendTcpRequest({
    required String ip,
    required int port, // <--- This was being ignored before
    required Map<String, dynamic> requestPayload,
    String tag = 'TCP',
  }) async {
    Socket? socket;
    try {
      debugPrint('[$tag] Connecting to $ip:$port...');
      
      // FIX: Use the 'port' parameter, do NOT hardcode 64546 here.
      socket = await Socket.connect(ip, port,
          timeout: const Duration(seconds: _timeoutSeconds));
      
      debugPrint('[$tag] Connected.');

      // Send request
      final jsonRequest = jsonEncode(requestPayload);
      socket.write(jsonRequest);
      await socket.flush();

      // Collect response
      final responseBytes = <int>[];
      final completer = Completer<Map<String, dynamic>?>();
      
      socket.listen(
        (data) => responseBytes.addAll(data),
        onDone: () {
          if (responseBytes.isNotEmpty) {
            try {
              final responseStr = utf8.decode(responseBytes);
              debugPrint('[$tag][Windows] Received response: $responseStr');
              final Map<String, dynamic> parsed = jsonDecode(responseStr);
              completer.complete(parsed);

              // --- Auto Connect Logic (Specific to GC_RESPONSE) ---
              if (parsed['action'] == 'GC_RESPONSE') {
                 // Use the IP/Port returned by the device, or fallback to current defaults
                 final String targetIp = parsed['ip'] == '0.0.0.0' ? ip : parsed['ip'];
                 final int targetPort = parsed['port'] ?? 12345;
                 final String password = parsed['password'];
                 
                 debugPrint('[$tag] Auto-connecting to $targetIp:$targetPort');
                 
                 // Run on main thread
                 Future.delayed(Duration.zero, () {
                    gFFI.dialogManager.setPasswordForAutoConnect(password);
                    if (globalKey.currentContext != null) {
                      connect(globalKey.currentContext!, '$targetIp:$targetPort', password: password);
                    }
                 });
              }
              // ----------------------------------------------------

            } catch (e) {
              debugPrint('[$tag] Parse error: $e');
              completer.complete(null);
            }
          } else {
            completer.complete(null);
          }
        },
        onError: (e) => completer.complete(null),
      );

      return await completer.future.timeout(
        const Duration(seconds: _timeoutSeconds + 1),
        onTimeout: () => null,
      );
    } catch (e) {
      debugPrint('[$tag] Connection failed: $e');
      return null;
    } finally {
      socket?.destroy();
    }
  }
}

