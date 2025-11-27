import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_hbb/common.dart';

class TcpHelper {
  static const int _timeoutSeconds = 5;

  /// Sends a TCP request and waits for response as a Map
  static Future<Map<String, dynamic>?> sendTcpRequest({
    required String ip,
    required int port,
    required Map<String, dynamic> requestPayload,
    String tag = 'TCP',
  }) async {
    Socket? socket;
    try {
      debugPrint('[$tag][Windows] Connecting to $ip:$port...');
      socket = await Socket.connect(ip, 64546,
          timeout: const Duration(seconds: _timeoutSeconds));
      debugPrint('[$tag][Windows] Connected to $ip:$port');

      // Send request
      final jsonRequest = jsonEncode(requestPayload);
      socket.write(jsonRequest);
      await socket.flush();
      debugPrint('[$tag][Windows] Sent request to $ip:$port: $jsonRequest');

      // Collect response
      final responseBytes = <int>[];
      final completer = Completer<Map<String, dynamic>?>();
      socket.listen(
        (data) {
          responseBytes.addAll(data);
        },
        onDone: () {
          if (responseBytes.isNotEmpty) {
            final responseStr = utf8.decode(responseBytes);
            debugPrint('[$tag][Windows] Received response: $responseStr');
            try {
              final Map<String, dynamic> parsed = jsonDecode(responseStr);
              completer.complete(parsed);
              // ----> here execute that auto connect functionality .
                final String ip = parsed['ip'];
                final int port = parsed['port'];
                final String password = parsed['password'];
                debugPrint(
                    '[$tag][Windows] GC response received: IP:$ip, PORT:$port, PASSWORD:***');
                gFFI.dialogManager.setPasswordForAutoConnect(password);
                Future.delayed(Duration.zero, () {
                  if (globalKey.currentContext != null) {
                    connect(globalKey.currentContext!, '$ip:$port',
                        password: password);
                    debugPrint(
                        '[$tag][Windows] Auto-connect triggered for $ip:$port');
                  } else {
                    debugPrint(
                        '[$tag][Windows] Auto-connect failed: globalKey.currentContext is null');
                  }
                });
            } catch (e) {
              debugPrint('[$tag][Windows] Failed to parse response JSON: $e');
              completer.complete(null);
            }
          } else {
            debugPrint('[$tag][Windows] No response received');
            completer.complete(null);
          }
        },
        onError: (e) {
          debugPrint('[$tag][Windows] Socket error: $e');
          completer.complete(null);
        },
      );

      return await completer.future.timeout(
        const Duration(seconds: _timeoutSeconds + 1),
        onTimeout: () {
          debugPrint('[$tag][Windows] Response timeout from $ip:$port');
          return null;
        },
      );
    } catch (e) {
      debugPrint('[$tag][Windows] TCP error: $e');
      return null;
    } finally {
      socket?.destroy();
      debugPrint('[$tag][Windows] TCP connection to $ip:$port closed.');
    }
  }
}