import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';

class XConnectTcpManager extends GetxController {
  static XConnectTcpManager get to => Get.find();

  ServerSocket? _serverSocket;
  final int _port = 64546;

  final Rx<Map<String, dynamic>> _messageBus = Rx<Map<String, dynamic>>({});
  Stream<Map<String, dynamic>> get messageStream => _messageBus.stream;

  final Uuid _uuid = Uuid();

  @override
  void onInit() {
    super.onInit();
    _startServer();
  }

  Future<void> _startServer() async {
    if (_serverSocket != null) return;
    try {
      _serverSocket =
          await ServerSocket.bind(InternetAddress.anyIPv4, _port, shared: true);
      debugPrint('[XConnectTcpManager] ✅ Server listening on port $_port');

      _serverSocket!.listen((Socket client) {
        debugPrint(
            '[XConnectTcpManager] -> Receiving self originated request from client: ${client.remoteAddress.address}');
        client.listen(
          (data) {
            try {
              final responseStr = utf8.decode(data);
              final Map<String, dynamic> json = jsonDecode(responseStr);
              // Main server only handles broadcast-like messages
              if (json['transaction_id'] == null) {
                json['remoteIp'] = client.remoteAddress.address;
                _messageBus.value = json;
              }

              debugPrint(
                  '[XConnectTcpManager] -> Received message details : $json');
            } catch (e) {
              debugPrint('[XConnectTcpManager] ‼️ Error parsing data: $e');
            }
          },
          onDone: () {
            debugPrint(
                '[XConnectTcpManager] -> Successfully Received message from client');
            client.destroy();
          },
          onError: (error) {
            debugPrint('[XConnectTcpManager] ‼️ Socket error: $error');
            client.destroy();
          },
        );
      });
    } catch (e) {
      debugPrint(
          '[XConnectTcpManager] ‼️ FATAL: Could not bind server to port $_port: $e');
    }
  }

  /// Sends a request and waits for a response on the SAME socket connection.
  Future<Map<String, dynamic>?> sendRequest(
      String ip, Map<String, dynamic> payload) async {
    final transactionId = _uuid.v4();
    payload['transaction_id'] = transactionId;

    Socket? socket;
    try {
      final completer = Completer<Map<String, dynamic>?>();

      socket =
          await Socket.connect(ip, _port, timeout: const Duration(seconds: 3));
      debugPrint(
          '[XConnectTcpManager] -> Connected to $ip:$_port for TX_ID $transactionId');

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

  @override
  void onClose() {
    _serverSocket?.close();
    super.onClose();
  }
}
