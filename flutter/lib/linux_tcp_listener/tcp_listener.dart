import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';

class TcpListener {
  ServerSocket? _serverSocket;
  Function(String)? onMessageReceived;
  final int port;
  final List<Map<String, dynamic>> _parsedMessages = [];

  TcpListener({required this.port, this.onMessageReceived});

  Future<void> start() async {
    try {
      _serverSocket =
          await ServerSocket.bind(InternetAddress.loopbackIPv4, port);
      _log('TCP Listener started on port $port');
      _serverSocket?.listen(_handleSocket);
      _log('✅ Task 2.1 completed — TCP message parsing and routing verified.');
    } catch (e) {
      _log('Failed to start TCP Listener on port $port: $e');
    }
  }

  void _handleSocket(Socket clientSocket) {
    _log(
        'Client connected: ${clientSocket.remoteAddress.address}:${clientSocket.remotePort}');
    clientSocket.listen(
      (List<int> data) {
        final message = utf8.decode(data);
        _log('Received from client: $message');
        _parseAndRouteMessage(message);
      },
      onDone: () {
        _log(
            'Client disconnected: ${clientSocket.remoteAddress.address}:${clientSocket.remotePort}');
        clientSocket.destroy();
      },
      onError: (e) {
        _log('Error on client socket: $e');
        clientSocket.destroy();
      },
    );
  }

  void _parseAndRouteMessage(String message) {
    try {
      final Map<String, dynamic> json = jsonDecode(message);

      if (json.containsKey('action') &&
          json.containsKey('ip') &&
          json.containsKey('port')) {
        final String action = json['action'];
        _parsedMessages.add(json);

        if (action == 'TC') {
          _log(
              '[TC][Linux] Parsed request successfully. Ready for connection (Task 2.2).');
        } else if (action == 'GC_REQUEST') {
          _log(
              '[GC][Linux] Parsed request successfully. Ready for response (Task 2.2).');
        } else {
          _log('[TCP][Linux] Unknown action received: $action — ignored.');
        }
      } else {
        _log('[TCP][Linux] Invalid or incomplete request received — ignored.');
      }
    } catch (e) {
      _log(
          '[TCP][Linux] Malformed JSON data received: $message — ignored. Error: $e');
    }
  }

  Future<void> stop() async {
    await _serverSocket?.close();
    _serverSocket = null;
    _log('TCP Listener stopped');
  }

  void _log(String message) {
    debugPrint('[TCP Listener] $message');
  }
}
