import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';

class TcpListener {
  ServerSocket? _serverSocket;
  Function(String)? onMessageReceived;
  final int port;

  TcpListener({required this.port, this.onMessageReceived});

  Future<void> start() async {
    try {
      _serverSocket =
          await ServerSocket.bind(InternetAddress.loopbackIPv4, port);
      debugPrint('TCP Listener started on port $port');
      _serverSocket?.listen(_handleSocket);
    } catch (e) {
      debugPrint('Failed to start TCP Listener on port $port: $e');
    }
  }

  void _handleSocket(Socket clientSocket) {
    debugPrint(
        'Client connected: ${clientSocket.remoteAddress.address}:${clientSocket.remotePort}');
    clientSocket.listen(
      (List<int> data) {
        final message = utf8.decode(data);
        debugPrint('Received from client: $message');
        onMessageReceived?.call(message);
      },
      onDone: () {
        debugPrint(
            'Client disconnected: ${clientSocket.remoteAddress.address}:${clientSocket.remotePort}');
        clientSocket.destroy();
      },
      onError: (e) {
        debugPrint('Error on client socket: $e');
        clientSocket.destroy();
      },
    );
  }

  Future<void> stop() async {
    await _serverSocket?.close();
    _serverSocket = null;
    debugPrint('TCP Listener stopped');
  }
}
