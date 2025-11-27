import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hbb/main.dart';
import 'package:flutter_hbb/common.dart';

enum SystemWindowTheme { light, dark }

/// The platform channel for RustDesk.
class RdPlatformChannel {
  RdPlatformChannel._();

  static final RdPlatformChannel _windowUtil = RdPlatformChannel._();

  static RdPlatformChannel get instance => _windowUtil;

  final MethodChannel _platformMethodChannel =
      MethodChannel("org.rustdesk.rustdesk/platform");

  /// Change the theme of the system window
  Future<void> changeSystemWindowTheme(SystemWindowTheme theme) {
    assert(isMacOS);
    if (kDebugMode) {
      print(
          "[Window ${kWindowId ?? 'Main'}] change system window theme to ${theme.name}");
    }
    return _platformMethodChannel
        .invokeMethod("setWindowTheme", {"themeName": theme.name});
  }

  /// Terminate .app manually.
  Future<void> terminate() {
    assert(isMacOS);
    return _platformMethodChannel.invokeMethod("terminate");
  }

  Future<String?> getLocalIp() async {
    if (isWindows) {
      return await _platformMethodChannel.invokeMethod("getLocalIp");
    }
    return null;
  }

  Future<int?> getAvailablePort() async {
    if (isWindows) {
      return await _platformMethodChannel.invokeMethod("getAvailablePort");
    }
    return null;
  }
}