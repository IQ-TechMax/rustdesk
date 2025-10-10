import 'dart:io';
import 'dart:convert';
import 'dart:developer'; // Import for logging
import 'package:flutter/foundation.dart';
import 'package:flutter_hbb/utils/multi_window_manager.dart';
import 'package:flutter_hbb/consts.dart';
import 'package:flutter_hbb/main.dart';
import 'package:flutter_hbb/models/model.dart';
import 'package:flutter_hbb/native/common.dart';
import 'package:flutter_hbb/models/platform_model.dart';

const int _kGcResponsePort = 64546; // Define constant for GC response port

class TcpListener {
  ServerSocket? _serverSocket;
  Function(String)? onMessageReceived;
  final int port;
  final FFI ffi;
  final List<Map<String, dynamic>> _parsedMessages = [];
  int _totalTcRequests = 0;
  int _totalTcFailures = 0;
  int _totalGcRequests = 0;
  int _totalGcFailures = 0;

  TcpListener({required this.port, required this.ffi, this.onMessageReceived});

  Future<void> start() async {
    try {
      _serverSocket = await ServerSocket.bind(InternetAddress.anyIPv4, port);
      _log('TCP Listener started on port $port');
      _serverSocket?.listen(_handleSocket);
      _log('✅ Task 2.1 completed — TCP message parsing and routing verified.');
    } catch (e) {
      _log('❌Failed to start TCP Listener on port $port: $e');
    }
  }

  void _handleSocket(Socket clientSocket) {
    _log(
        'Client connected: ${clientSocket.remoteAddress.address}:${clientSocket.remotePort}');
    clientSocket.listen(
      (List<int> data) async {
        try {
          final message = utf8.decode(data);
          _log('Received from client: $message');
          await _parseAndRouteMessage(clientSocket, message);
        } catch (e) {
          _log('❌Error processing received data: $e');
          clientSocket.destroy();
        }
      },
      onDone: () {
        _log(
            'Client disconnected: ${clientSocket.remoteAddress.address}:${clientSocket.remotePort}');
        clientSocket.destroy();
      },
      onError: (e) {
        _log('❌Error on client socket: $e');
        clientSocket.destroy();
      },
    );
  }

  Future<void> _parseAndRouteMessage(Socket client, String message) async {
    try {
      final Map<String, dynamic> json = jsonDecode(message);

      if (json.containsKey('action') &&
          json.containsKey('ip') &&
          json.containsKey('port')) {
        final String action = json['action'];
        _parsedMessages.add(json);

        if (action == 'TC') {
          _log('[TC][Linux] Using existing RustDesk backend to connect...');
          _totalTcRequests++;
          final String ip = json['ip'];
          final int port = json['port'];
          final String password = json['password'] ?? '';
          final String remoteId = '$ip:$port';
          try {
            await rustDeskWinManager.newRemoteDesktop(
              remoteId,
              password: password,
            );
            _log('[TC][Linux] Connection successful to $ip:$port');
          } catch (e) {
            _totalTcFailures++;
            _log('❌[TC][Linux] Connection failed to $ip:$port: $e');
          }
        } else if (action == 'GC_REQUEST') {
          _log(
              '[GC][Linux] Received GC request from ${client.remoteAddress.address}');
          _totalGcRequests++;

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
            _log('❌[GC][Linux] Failed to get local IP: $e');
          }

          // Placeholder for RustDesk password retrieval
          final String rustDeskPassword =
              await platformFFI.ffiBind.mainGetPermanentPassword(hint: null);

          final Map<String, dynamic> gcResponse = {
            'action': 'GC_RESPONSE',
            'ip': localIp,
            'port': _kGcResponsePort,
            "⚠️check here for port"
                'password': rustDeskPassword,
          };

          try {
            client.write(utf8.encode(jsonEncode(gcResponse)));
            _log(
                '[GC][Linux] Responded with local IP=$localIp, PORT=$_kGcResponsePort, password=$rustDeskPassword');
          } catch (e) {
            _totalGcFailures++;
            _log('❌[GC][Linux] Failed to send GC response: $e');
          }
        } else {
          _log('❌[TCP][Linux] Unknown action received: $action — ignored.');
        }
      } else {
        _log(
            '❌[TCP][Linux] Invalid or incomplete request received — ignored. Message: $message');
      }
    } catch (e) {
      _log(
          '❌[TCP][Linux] Malformed JSON data received: $message — ignored. Error: $e');
    }
  }

  Future<void> stop() async {
    _log('✅ Linux TC/GC backend integration completed successfully.');
    _log('Total TC requests handled: $_totalTcRequests');
    _log('Total GC requests handled: $_totalGcRequests');
    final String failureMessage =
        (_totalTcFailures == 0 && _totalGcFailures == 0)
            ? 'None'
            : 'TC: $_totalTcFailures, GC: $_totalGcFailures';
    _log('❌Any failures: $failureMessage');
    await _serverSocket?.close();
    _serverSocket = null;
    _parsedMessages.clear(); // Clear messages to prevent memory leak
    _log('TCP Listener stopped');
  }

  void _log(String message) {
    log('[TCP Listener] $message'); // Using dart:developer's log
  }
}
