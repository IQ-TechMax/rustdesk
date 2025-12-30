import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

final int SHARED_PORT = 64546;

/// Sends a request and waits for a response on the SAME socket connection.
Future<Map<String, dynamic>?> sendTCPRequest(
    String ip, Map<String, dynamic> payload) async {
  final transactionId = Uuid().v4();
  payload['transaction_id'] = transactionId;

  Socket? socket;
  try {
    final completer = Completer<Map<String, dynamic>?>();

    socket = await Socket.connect(ip, SHARED_PORT,
        timeout: const Duration(seconds: 3));
    debugPrint(
        '[XConnectTcpManager] -> Connected to $ip:$SHARED_PORT for TX_ID $transactionId');

    // **THE FIX**: Listen for the response on this specific socket
    socket.listen(
      (data) {
        try {
          final responseStr = utf8.decode(data);
          final Map<String, dynamic> json = jsonDecode(responseStr);
          if (json['transaction_id'] == transactionId) {
            if (!completer.isCompleted) {
              debugPrint(
                  '[XConnectTcpManager] -> Response for TX_ID $transactionId received: $json');
              completer.complete(json);
            }
          }
        } catch (e) {
          if (!completer.isCompleted) {
            debugPrint(
                '[XConnectTcpManager] ‼️ Parse error for TX_ID $transactionId: $e');
            completer.complete(null);
          }
        }
      },
      onDone: () {
        if (!completer.isCompleted) {
          debugPrint(
              '[XConnectTcpManager] -> Socket closed by peer before response for TX_ID $transactionId');
          completer.complete(null);
        }
      },
      onError: (error) {
        if (!completer.isCompleted) {
          debugPrint(
              '[XConnectTcpManager] ‼️ Socket error for TX_ID $transactionId: $error');
          completer.complete(null);
        }
      },
      cancelOnError: true,
    );

    // Now, send the request
    socket.write(jsonEncode(payload));
    await socket.flush();
    debugPrint(
        '[XConnectTcpManager] -> Sent request with TX_ID $transactionId to $ip');

    // Wait for the completer, which is fulfilled by the socket's listener.
    return await completer.future.timeout(const Duration(seconds: 5),
        onTimeout: () {
      debugPrint(
          '[XConnectTcpManager] ‼️ Request timed out for TX_ID $transactionId');
      return null;
    });
  } catch (e) {
    debugPrint(
        '[XConnectTcpManager] ‼️ Error in sendRequest for TX_ID $transactionId: $e');
    return null;
  } finally {
    // Cleanly close the socket after the conversation is over.
    socket?.destroy();
  }
}
