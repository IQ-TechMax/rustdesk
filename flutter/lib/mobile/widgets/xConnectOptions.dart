// You can place this function within your home_page.dart file or a new utility file.

import 'dart:ui';
import 'package:flutter/material.dart';

// An enum to represent the selected action
enum DeviceAction { xBoard, xCast, xCtrl, xCtrlView }

Future<DeviceAction?> showXConnectOptionsDialog(BuildContext context) {
  return showDialog<DeviceAction>(
    context: context,
    barrierColor: Colors.black.withOpacity(0.5), // Darken the background a bit
    builder: (BuildContext context) {
      // Using a BackdropFilter for the blur effect
      return BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Dialog(
          backgroundColor: Colors.transparent, // Transparent to see the blur
          elevation: 0,
          insetPadding:
              const EdgeInsets.all(20), // Add padding around the dialog
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                  20)), // Add rounded corners to the dialog itself
          child: ConstrainedBox(
            constraints: const BoxConstraints(
                maxWidth: 800), // Max width for larger screens
            child: Padding(
              // Added this Padding widget
              padding: const EdgeInsets.all(
                  20.0), // This will space out the content from the corners
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const Text(
                        'Modes',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Using LayoutBuilder to create a responsive grid
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth > 500;
                      return GridView.count(
                        crossAxisCount: isWide
                            ? 4
                            : 2, // 4 items in a row on wide screens, 2 on narrow
                        mainAxisSpacing: 20,
                        crossAxisSpacing: 20,
                        shrinkWrap: true,
                        childAspectRatio:
                            0.8, // Adjust aspect ratio to provide more height
                        physics: const NeverScrollableScrollPhysics(),
                        children: <Widget>[
                          _buildDialogOption(
                            context: context,
                            iconPath: 'assets/xBoard.png',
                            label: 'X Board',
                            description:
                                'Turn screen into a digital whiteboard. Write, draw, and explain effortlessly for interactive lessons, brainstorming sessions, or presentations.',
                            onTap: () =>
                                Navigator.of(context).pop(DeviceAction.xBoard),
                          ),
                          _buildDialogOption(
                            context: context,
                            iconPath: 'assets/xCast.png',
                            label: 'X Cast',
                            description:
                                'Cast content from your tablet directly onto xWell. Access lessons, materials, and media for an engaging big-well experience.',
                            onTap: () =>
                                Navigator.of(context).pop(DeviceAction.xCast),
                          ),
                          _buildDialogOption(
                            context: context,
                            iconPath: 'assets/xCtrl.png',
                            label: 'X Ctrl',
                            description:
                                'Take full control with keyboard and mouse. Navigate, manage, and interact with content smoothly on xWell.',
                            onTap: () =>
                                Navigator.of(context).pop(DeviceAction.xCtrl),
                          ),
                          _buildDialogOption(
                            context: context,
                            iconPath: 'assets/xCtrlView.png',
                            label: 'X Ctrl (vue)',
                            description:
                                'Mirror and control xWell from your tablet.',
                            onTap: () => Navigator.of(context)
                                .pop(DeviceAction.xCtrlView),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

// A helper widget to create each image option to avoid code repetition.
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
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: SingleChildScrollView(
        // Added this widget to prevent overflow
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset(iconPath,
                width: 80,
                height: 80,
                fit: BoxFit.cover), // Use a real icon here
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              textAlign: TextAlign.center,
              style:
                  TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 8),
            ),
          ],
        ),
      ),
    ),
  );
}
