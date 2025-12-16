// /lib/desktop/widgets/xConnectOptions.dart

import 'dart:ui';
import 'package:flutter/material.dart';

enum DeviceAction { xCast, xCtrlView } // Simplified for desktop

Future<DeviceAction?> showDesktopXConnectOptionsDialog(BuildContext context) {
  return showDialog<DeviceAction>(
    context: context,
    builder: (BuildContext context) {
      return BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(40.0),
            child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: 30),
                      const Text('Modes',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 30,
                              fontWeight: FontWeight.bold))
                    ]),
                    const SizedBox(height: 40),
                    GridView.count(
                      crossAxisCount: 2,
                      mainAxisSpacing: 20,
                      crossAxisSpacing: 20,
                      shrinkWrap: true,
                      childAspectRatio: 1,
                      physics: const NeverScrollableScrollPhysics(),
                      children: <Widget>[
                        _buildDialogOption(
                          context: context,
                          iconPath: 'assets/xCast.png',
                          label: 'X Cast',
                          description:
                              'Cast content from this PC directly onto xWall.',
                          onTap: () =>
                              Navigator.of(context).pop(DeviceAction.xCast),
                        ),
                        _buildDialogOption(
                          context: context,
                          iconPath: 'assets/xCtrlView.png',
                          label: 'X Ctrl (View)',
                          description: 'Mirror and control xWall from this PC.',
                          onTap: () =>
                              Navigator.of(context).pop(DeviceAction.xCtrlView),
                        ),
                      ],
                    ),
                  ],
                )),
          ),
        ),
      );
    },
  );
}

// Re-using the same helper from mobile is fine
Widget _buildDialogOption({
  required BuildContext context,
  required String iconPath,
  required String label,
  required String description,
  required VoidCallback onTap,
}) {
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset(iconPath, width: 200, height: 200, fit: BoxFit.cover),
            Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(description,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.white.withOpacity(0.7), fontSize: 16)),
          ],
        ),
      ),
    ),
  );
}
