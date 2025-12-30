// tcp_listener.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:developer';

import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_hbb/consts.dart';
import 'package:flutter_hbb/main.dart'; // keep if connect() and globalKey are used
import 'package:flutter_hbb/common.dart';
import 'package:flutter_hbb/models/state_model.dart';
import 'package:flutter_hbb/utils/multi_window_manager.dart';


const int _tcpBindRetryCount = 3;
const Duration _tcpBindRetryDelay = Duration(seconds: 1);

class TcpListener {
  ServerSocket? _serverSocket;
  final int port;
  bool _running = false;

  TcpListener({required this.port});

  Future<void> start() async {
    if (_running) {
      _log('TCP Listener already running; skipping start');
      return;
    }
    _running = true;

    int attempt = 0;
    while (attempt < _tcpBindRetryCount) {
      attempt++;
      try {
        // 'shared: true' allows multiple processes/isolates to bind in some platforms.
        _serverSocket = await ServerSocket.bind(InternetAddress.anyIPv4, port,
            shared: true);
        _log('TCP Listener started on port $port (attempt $attempt)');
        _serverSocket?.listen(_handleSocket, onError: (e) {
          _log('ServerSocket listen error: $e');
        });
        return;
      } catch (e) {
        _log(
            '❌Failed to bind TCP Listener on port $port (attempt $attempt): $e');
        if (attempt < _tcpBindRetryCount) {
          await Future.delayed(_tcpBindRetryDelay);
        } else {
          _log('❌Exceeded retry attempts to bind TCP listener on port $port.');
          _running = false;
          return;
        }
      }
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
        try {
          clientSocket.destroy();
        } catch (e) {
          _log('Error destroying client socket: $e');
        }
      },
      onError: (e) {
        _log('❌Socket error: $e');
        try {
          clientSocket.destroy();
        } catch (_) {}
      },
      cancelOnError: true,
    );
  }

  Future<void> _parseMessage(Socket client, String message) async {
    try {
      final Map<String, dynamic> jsonMsg = jsonDecode(message);

      if (!jsonMsg.containsKey('action')) {
        _log('❌Invalid request received (no action): $message');
        return;
      }

      final String action = jsonMsg['action'];

      // TC: incoming instruction to "take control" — we should initiate connect()
      if (action == 'TC') {
        _log('[TC] Received TC request from ${client.remoteAddress.address}');
        final ip = jsonMsg['ip']?.toString();
        final port = jsonMsg['port'];
        final password = jsonMsg['password']?.toString();
        _log('[TC] IP: $ip, PORT: $port');

        if (ip != null && port != null && password != null) {
            try {
              await connect(globalKey.currentContext!, '$ip:$port',
                  password: password);
              
              await DesktopMultiWindow.invokeMethod(WindowType.RemoteDesktop.index, kWindowEventSetFullscreen, 'true');
              
              _log('[TC] Auto connect triggered to $ip:$port');
            } catch (e) {
              _log('[TC] Auto connect error: $e');
            }
        } else {
          _log('[TC] Missing fields in TC message.');
        }
      }

      // GC_REQUEST: reply with IP/port/password and an ack that Windows expects.
      else if (action == 'GC_REQUEST') {
        _log('[GC] Received GC_REQUEST from ${client.remoteAddress.address}');

        // Determine local IP (non-loopback) safely
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

        final String password = gFFI.serverModel.serverPasswd.text;
        final Map<String, dynamic> gcResponse = {
          'ack': 'GC_ACK', // NOTE: Windows checks for this field
          'action': 'GC_RESPONSE',
          'ip': localIp.isNotEmpty ? localIp : '0.0.0.0',
          'port':
              XCONNECT_PORT,
          'password': password,
          'transaction_id': jsonMsg['transaction_id']
        };

        try {
          final String out = jsonEncode(gcResponse);
          client.write(out);
          await client.flush();
          _log('[GC] Sent GC response: $gcResponse');
        } catch (e) {
          _log('❌Failed to send GC response: $e');
        }
      }

      else if ( action == 'CLOSE_CONNECTION') {
        try {
          DesktopMultiWindow.invokeMethod(WindowType.RemoteDesktop.index, kWindowEventRemoveRemoteByPeerId, '${client.remoteAddress.address}:$XCONNECT_PORT');
        } catch (e) {
          _log('❌Failed to close outgoing connection window: $e');
        }
      }

      // Unknown action
      else {
        _log('❌Unknown action received: $action');
      }
    } catch (e) {
      _log('❌Malformed JSON received or parse error: $message — $e');
    }
  }

  Future<void> stop() async {
    if (!_running) return;
    try {
      await _serverSocket?.close();
      _serverSocket = null;
      _running = false;
      _log('TCP Listener stopped');
    } catch (e) {
      _log('Error stopping TCP listener: $e');
    }
  }

  void _log(String message) {
    log('[TCP Listener] $message');
    if (kDebugMode) debugPrint('[TCP Listener] $message');
  }
}
