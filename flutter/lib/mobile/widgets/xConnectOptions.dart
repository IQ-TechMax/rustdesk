import 'dart:ui';
import 'package:flutter/material.dart';

enum DeviceAction { xBoard, xCast, xCtrl, xCtrlView }

Future<DeviceAction?> showXConnectOptionsDialog(BuildContext context) {
  return showDialog<DeviceAction>(
    context: context,
    // Darken background
    barrierColor: Colors.black.withOpacity(0.6),
    barrierDismissible: true,
    builder: (BuildContext context) {
      // 1. Determine screen metrics
      final double screenWidth = MediaQuery.of(context).size.width;
      final bool isNarrow = screenWidth < 600; // Mobile vs Tablet logic
      final double contentWidth = isNarrow ? 340 : 700;

      return Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.all(20),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: contentWidth),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              // 2. Blur contained inside
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                padding: const EdgeInsets.all(25.0),
                decoration: BoxDecoration(
                  // Dark glass style
                  color: const Color(0xFF1E1E1E).withOpacity(0.85),
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
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header
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
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Responsive Grid/List
                      GridView.count(
                        crossAxisCount:
                            isNarrow ? 1 : 2, // 1 col for phone, 2 for tablet
                        mainAxisSpacing: 15,
                        crossAxisSpacing: 15,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        // Dynamic aspect ratio:
                        // Narrow (List view) needs wide cards (~2.2)
                        // Wide (Grid view) needs squarish cards (~0.85)
                        childAspectRatio: isNarrow ? 2.2 : 0.85,
                        children: [
                          _buildDialogOption(
                            context: context,
                            iconPath: 'assets/xBoard.png',
                            label: 'X Board',
                            description:
                                'Turn screen into a digital whiteboard. Write and draw effortlessly.',
                            onTap: () =>
                                Navigator.of(context).pop(DeviceAction.xBoard),
                            isNarrow: isNarrow,
                          ),
                          _buildDialogOption(
                            context: context,
                            iconPath: 'assets/xCast.png',
                            label: 'X Cast',
                            description:
                                'Cast content from your tablet directly onto Xwall.',
                            onTap: () =>
                                Navigator.of(context).pop(DeviceAction.xCast),
                            isNarrow: isNarrow,
                          ),
                          _buildDialogOption(
                            context: context,
                            iconPath: 'assets/xCtrl.png',
                            label: 'X Ctrl',
                            description:
                                'Take full control with keyboard and mouse.',
                            onTap: () =>
                                Navigator.of(context).pop(DeviceAction.xCtrl),
                            isNarrow: isNarrow,
                          ),
                          _buildDialogOption(
                            context: context,
                            iconPath: 'assets/xCtrlView.png',
                            label: 'X Ctrl (Vue)',
                            description:
                                'Mirror and control Xwall from your tablet.',
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

// Reusable widget that changes layout based on screen width
Widget _buildDialogOption({
  required BuildContext context,
  required String iconPath,
  required String label,
  required String description,
  required VoidCallback onTap,
  required bool isNarrow, // Pass layout state
}) {
  return Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      splashColor: Colors.white.withOpacity(0.1),
      highlightColor: Colors.white.withOpacity(0.05),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        // Switch Layout: Row for Phone, Column for Tablet
        child: isNarrow
            ? _buildMobileLayout(iconPath, label, description)
            : _buildTabletLayout(iconPath, label, description),
      ),
    ),
  );
}

// 1. Mobile Layout (Horizontal Row) - Saves vertical space
Widget _buildMobileLayout(String iconPath, String label, String description) {
  return Row(
    children: [
      Image.asset(iconPath, width: 60, height: 60, fit: BoxFit.contain),
      const SizedBox(width: 15),
      Expanded(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

// 2. Tablet Layout (Vertical Column) - Better for grids
Widget _buildTabletLayout(String iconPath, String label, String description) {
  return Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Expanded(
        flex: 3,
        child: Image.asset(iconPath, fit: BoxFit.contain),
      ),
      const SizedBox(height: 10),
      Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 5),
      Flexible(
        child: Text(
          description,
          textAlign: TextAlign.center,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 12,
          ),
        ),
      ),
    ],
  );
}
