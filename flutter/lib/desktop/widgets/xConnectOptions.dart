// /lib/desktop/widgets/xConnectOptions.dart

import 'dart:ui';
import 'package:flutter/material.dart';

enum DeviceAction { xCast, xCtrlView }

Future<DeviceAction?> showDesktopXConnectOptionsDialog(BuildContext context) {
  return showDialog<DeviceAction>(
    context: context,
    // Darken the background (the barrier)
    barrierColor: Colors.black.withOpacity(0.3),
    // Ensure clicking the barrier closes the dialog
    barrierDismissible: true,
    builder: (BuildContext context) {
      // 1. Use MediaQuery instead of LayoutBuilder so the Dialog doesn't expand to full screen
      final double screenWidth = MediaQuery.of(context).size.width;
      final bool isNarrow = screenWidth < 600;
      final double contentWidth = isNarrow ? 340 : 750;

      return Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        // Ensure the dialog never touches the absolute edges
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: contentWidth),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              // 2. Blur effect contained strictly inside the dialog shape
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                padding: const EdgeInsets.all(30.0),
                decoration: BoxDecoration(
                  // 3. Dark semi-transparent background for the glass card
                  color: const Color(0xFF1E1E1E).withOpacity(0.5),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    )
                  ],
                ),
                // Wrap in SingleChildScrollView to handle short screens/landscape
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize:
                        MainAxisSize.min, // Shrink vertically to fit content
                    children: [
                      // Header Row
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back,
                                color: Colors.white),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Modes',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),

                      // Responsive Grid
                      GridView.count(
                        crossAxisCount: isNarrow ? 1 : 2,
                        crossAxisSpacing: 20,
                        mainAxisSpacing: 20,
                        shrinkWrap:
                            true, // Important: let grid take only needed space
                        physics: const NeverScrollableScrollPhysics(),
                        // Dynamic aspect ratio ensures cards look good on both mobile/desktop
                        childAspectRatio: isNarrow ? 1.6 : 1.0,
                        children: [
                          _buildDialogOption(
                            context: context,
                            iconPath:
                                'assets/xCast.png', // Ensure these assets exist
                            label: 'X Cast',
                            description:
                                'Cast content from this PC directly onto xWall.',
                            onTap: () =>
                                Navigator.of(context).pop(DeviceAction.xCast),
                            isNarrow: isNarrow,
                          ),
                          _buildDialogOption(
                            context: context,
                            iconPath:
                                'assets/xCtrlView.png', // Ensure these assets exist
                            label: 'X Ctrl (View)',
                            description:
                                'Mirror and control xWall from this PC.',
                            onTap: () => Navigator.of(context)
                                .pop(DeviceAction.xCtrlView),
                            isNarrow: isNarrow,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

Widget _buildDialogOption({
  required BuildContext context,
  required String iconPath,
  required String label,
  required String description,
  required VoidCallback onTap,
  required bool isNarrow,
}) {
  return Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      // Slight hover effect color
      hoverColor: Colors.white.withOpacity(0.05),
      child: Container(
        padding: const EdgeInsets.all(20.0),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: isNarrow
            // Mobile Layout: Row (Icon Left, Text Right)
            ? Row(
                children: [
                  Image.asset(iconPath,
                      width: 80, height: 80, fit: BoxFit.contain),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          description,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 14,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  )
                ],
              )
            // Desktop Layout: Column (Icon Top, Text Bottom)
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    flex: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Image.asset(iconPath, fit: BoxFit.contain),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(flex: 1),
                ],
              ),
      ),
    ),
  );
}
