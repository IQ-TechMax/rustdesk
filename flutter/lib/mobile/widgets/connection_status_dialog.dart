import 'dart:ui';
import 'package:flutter/material.dart';

enum ConnectionStatus { connecting, connected, failed }

class ConnectionStatusDialog extends StatelessWidget {
  final ConnectionStatus status;
  final VoidCallback onCancel; // For "Connecting" state
  final VoidCallback onDisconnect; // For "Connected" state

  const ConnectionStatusDialog({
    super.key,
    required this.status,
    required this.onCancel,
    required this.onDisconnect,
  });

  @override
  Widget build(BuildContext context) {
    String title;
    String message;
    Widget actionButton;

    switch (status) {
      case ConnectionStatus.connecting:
        title = 'Connecting...';
        message = 'Establishing connection with the device. Please wait.';
        actionButton = OutlinedButton(
          onPressed: onCancel,
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: const BorderSide(color: Colors.white54),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('Cancel'),
        );
        break;
      case ConnectionStatus.connected:
        title = 'Connected';
        message = 'You are now connected to the device.';
        actionButton = ElevatedButton(
          onPressed: onDisconnect,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.redAccent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('Disconnect'),
        );
        break;
      case ConnectionStatus.failed:
        title = 'Connection Failed';
        message = 'Could not connect to the device. Please try again.';
        actionButton = ElevatedButton(
          onPressed: () => Navigator.of(context).pop(), // Just close on failure
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('OK'),
        );
        break;
    }

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: AlertDialog(
        backgroundColor: Colors.grey.shade900.withOpacity(0.8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
          side: BorderSide(color: Colors.white.withOpacity(0.2)),
        ),
        title: Center(
          child: Text(
            title,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (status == ConnectionStatus.connecting)
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              )
            else if (status == ConnectionStatus.connected)
              const Icon(Icons.check_circle, color: Colors.green, size: 48)
            else
              const Icon(Icons.error, color: Colors.red, size: 48),
            const SizedBox(height: 20),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
        actions: <Widget>[
          Center(child: actionButton),
        ],
      ),
    );
  }
}
