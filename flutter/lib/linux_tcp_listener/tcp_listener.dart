import 'dart:io';
import 'dart:convert';
import 'dart:developer'; // For logging
import 'package:flutter_hbb/common.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_hbb/main.dart';

const int kGcResponsePort = 64546; // Port for GC response

class TcpListener {
  ServerSocket? _serverSocket;
  final int port;

  TcpListener({required this.port});

  Future<void> start() async {
    try {
      _serverSocket = await ServerSocket.bind(InternetAddress.anyIPv4, port);
      _log('TCP Listener started on port $port');
      _serverSocket?.listen(_handleSocket);
    } catch (e) {
      _log('❌Failed to start TCP Listener: $e');
    }
  }

  void _handleSocket(Socket clientSocket) {
    _log(
        'Client connected: ${clientSocket.remoteAddress.address}:${clientSocket.remotePort}');

    clientSocket.listen(
      (data) async {
        final message = utf8.decode(data);
        _log('Received from client: $message');
        await _parseMessage(clientSocket, message);
      },
      onDone: () {
        _log(
            'Client disconnected: ${clientSocket.remoteAddress.address}:${clientSocket.remotePort}');
        clientSocket.destroy();
      },
      onError: (e) {
        _log('❌Socket error: $e');
        clientSocket.destroy();
      },
    );
  }

  Future<void> _parseMessage(Socket client, String message) async {
    try {
      final Map<String, dynamic> jsonMsg = jsonDecode(message);

      if (jsonMsg.containsKey('action')) {
        final String action = jsonMsg['action'];

        // Handle TC: just log
        if (action == 'TC') {
          _log('[TC] Received TC request from ${client.remoteAddress.address}');
          final ip = jsonMsg['ip'];
          final port = jsonMsg['port'];
          final password = jsonMsg['password'];
          _log('[TC] IP: $ip, PORT: $port, PASSWORD: $password');

          // Programmatically initiate connection
          if (ip != null && port != null && password != null) {
            // Ensure Flutter is ready to handle UI updates
            Future.delayed(Duration.zero, () {
              connect(
                globalKey.currentContext!,
                '$ip:$port',
                password: password,
                isAutoConnect: true,
              );
            });
          }
        }

        // Handle GC: respond with IP, port, password
        else if (action == 'GC_REQUEST') {
          _log('[GC] Received GC request from ${client.remoteAddress.address}');

          // Get local IP
          String localIp = '';
          try {
            for (var interface in await NetworkInterface.list()) {
              for (var addr in interface.addresses) {
                if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
                  localIp = addr.address;
                  break;
                }
              }
              if (localIp.isNotEmpty) break;
            }
          } catch (e) {
            _log('❌Failed to get local IP: $e');
          }

          final String password = 'linux_placeholder_password';

          final Map<String, dynamic> gcResponse = {
            'action': 'GC_RESPONSE',
            'ip': localIp,
            'port': kGcResponsePort,
            'password': password,
          };

          try {
            client.write(jsonEncode(gcResponse));
            _log('[GC] Sent GC response: $gcResponse');
          } catch (e) {
            _log('❌Failed to send GC response: $e');
          }
        }

        // Unknown action
        else {
          _log('❌Unknown action received: $action');
        }
      } else {
        _log('❌Invalid request received: $message');
      }
    } catch (e) {
      _log('❌Malformed JSON received: $message — $e');
    }
  }

  Future<void> stop() async {
    await _serverSocket?.close();
    _serverSocket = null;
    _log('TCP Listener stopped');
  }

  void _log(String message) {
    log('[TCP Listener] $message');
  }
}
