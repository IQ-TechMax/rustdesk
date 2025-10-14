import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_hbb/linux_tcp_listener/tcp_listener.dart';

import 'package:bot_toast/bot_toast.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hbb/common/widgets/overlay.dart';
import 'package:flutter_hbb/desktop/pages/desktop_tab_page.dart';
import 'package:flutter_hbb/desktop/pages/install_page.dart';
import 'package:flutter_hbb/desktop/pages/server_page.dart';
import 'package:flutter_hbb/desktop/screen/desktop_file_transfer_screen.dart';
import 'package:flutter_hbb/desktop/screen/desktop_view_camera_screen.dart';
import 'package:flutter_hbb/desktop/screen/desktop_port_forward_screen.dart';
import 'package:flutter_hbb/desktop/screen/desktop_remote_screen.dart';
import 'package:flutter_hbb/desktop/screen/desktop_terminal_screen.dart';
import 'package:flutter_hbb/desktop/widgets/refresh_wrapper.dart';
import 'package:flutter_hbb/models/state_model.dart';
import 'package:flutter_hbb/utils/multi_window_manager.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import 'package:device_info_plus/device_info_plus.dart';

import 'common.dart';
import 'consts.dart';
import 'mobile/pages/home_page.dart';
import 'mobile/pages/server_page.dart';
import 'models/platform_model.dart';
import 'package:flutter_hbb/network_monitor.dart';
import 'package:flutter_hbb/models/server_model.dart';
import 'package:flutter/foundation.dart';

import 'package:flutter_hbb/plugin/handlers.dart'
    if (dart.library.html) 'package:flutter_hbb/web/plugin/handlers.dart';

/// Basic window and launch properties.
int? kWindowId;
WindowType? kWindowType;
late List<String> kBootArgs;

Future<void> main(List<String> args) async {
  earlyAssert();
  WidgetsFlutterBinding.ensureInitialized();

  debugPrint("launch args: $args");
  kBootArgs = List.from(args);

  if (!isDesktop) {
    runMobileApp();
    return;
  }
  // main window
  if (args.isNotEmpty && args.first == 'multi_window') {
    kWindowId = int.parse(args[1]);
    stateGlobal.setWindowId(kWindowId!);
    if (!isMacOS) {
      WindowController.fromWindowId(kWindowId!).showTitleBar(false);
    }
    final argument = args[2].isEmpty
        ? <String, dynamic>{}
        : jsonDecode(args[2]) as Map<String, dynamic>;
    int type = argument['type'] ?? -1;
    // to-do: No need to parse window id ?
    // Because stateGlobal.windowId is a global value.
    argument['windowId'] = kWindowId;
    kWindowType = type.windowType;
    switch (kWindowType) {
      case WindowType.RemoteDesktop:
        desktopType = DesktopType.remote;
        runMultiWindow(
          argument,
          kAppTypeDesktopRemote,
        );
        break;
      case WindowType.FileTransfer:
        desktopType = DesktopType.fileTransfer;
        runMultiWindow(
          argument,
          kAppTypeDesktopFileTransfer,
        );
        break;
      case WindowType.ViewCamera:
        desktopType = DesktopType.viewCamera;
        runMultiWindow(
          argument,
          kAppTypeDesktopViewCamera,
        );
        break;
      case WindowType.PortForward:
        desktopType = DesktopType.portForward;
        runMultiWindow(
          argument,
          kAppTypeDesktopPortForward,
        );
        break;
      case WindowType.Terminal:
        desktopType = DesktopType.terminal;
        runMultiWindow(
          argument,
          kAppTypeDesktopTerminal,
        );
      default:
        break;
    }
  } else if (args.isNotEmpty && args.first == '--cm') {
    debugPrint("--cm started");
    desktopType = DesktopType.cm;
    await windowManager.ensureInitialized();
    runConnectionManagerScreen();
  } else if (args.contains('--install')) {
    runInstallPage();
  } else {
    desktopType = DesktopType.main;
    await windowManager.ensureInitialized();
    windowManager.setPreventClose(true);
    if (isMacOS) {
      disableWindowMovable(kWindowId);
    }
    runMainApp(true);
  }
}

Future<void> initEnv(String appType) async {
  // global shared preference
  await platformFFI.init(appType);
  // global FFI, use this **ONLY** for global configuration
  // for convenience, use global FFI on mobile platform
  // focus on multi-ffi on desktop first
  await initGlobalFFI();
  // await Firebase.initializeApp();
  _registerEventHandler();
  // Update the system theme.
  updateSystemWindowTheme();
}

void runMainApp(bool startService) async {
  // register uni links
  await initEnv(kAppTypeMain);
  checkUpdate();
  // trigger connection status updater
  await bind.mainCheckConnectStatus();
  if (startService) {
    gFFI.serverModel.startService();
    bind.pluginSyncUi(syncTo: kAppTypeMain);
    bind.pluginListReload();
  }
  await Future.wait([gFFI.abModel.loadCache(), gFFI.groupModel.loadCache()]);
  gFFI.userModel.refreshCurrentUser();
  _runApp(
    isWeb
        ? '${bind.mainGetAppNameSync()} Web Client V2 (Preview)'
        : bind.mainGetAppNameSync(),
    App(),
    MyTheme.currentThemeMode(),
  );

  // Ensure server ID and password are fetched before starting network monitoring
  await gFFI.serverModel.fetchID();
  await gFFI.serverModel.updatePasswordModel();

  // Call network monitoring after gFFI.serverModel is initialized and values are updated
  final String currentSessionId = gFFI.serverModel.serverId.text;
  final String currentPassword = gFFI.serverModel.serverPasswd.text;
  Future<String> getDeviceId() async {
    final deviceInfo = DeviceInfoPlugin();

    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      return androidInfo.id;
    } else if (Platform.isWindows) {
      final windowsInfo = await deviceInfo.windowsInfo;
      // Remove { and } if present
      return windowsInfo.deviceId.replaceAll(RegExp(r'[{}]'), '');
    } else if (Platform.isLinux) {
      final linuxInfo = await deviceInfo.linuxInfo;
      return linuxInfo.machineId ?? "unknown-linux-id";
    } else {
      return "unknown-device";
    }
  }

  final String deviceId = await getDeviceId();
  debugPrint('Main: Session ID before network monitoring: $currentSessionId');
  debugPrint('Main: Password before network monitoring: $currentPassword');
  print(deviceId);
  NetworkMonitor.startNetworkMonitoring(
      currentSessionId, currentPassword, deviceId);

  // Start UDP discovery
  _startUdpDiscovery(currentSessionId, currentPassword, deviceId);

  bool? alwaysOnTop;
  if (isDesktop) {
    alwaysOnTop =
        bind.mainGetBuildinOption(key: "main-window-always-on-top") == 'Y';
  }

  // Set window option.
  WindowOptions windowOptions = getHiddenTitleBarWindowOptions(
      isMainWindow: true, alwaysOnTop: alwaysOnTop);
  windowManager.waitUntilReadyToShow(windowOptions, () async {
    // Restore the location of the main window before window hide or show.
    await restoreWindowPosition(WindowType.Main);
    // Check the startup argument, if we successfully handle the argument, we keep the main window hidden.
    final handledByUniLinks = await initUniLinks();
    debugPrint("handled by uni links: $handledByUniLinks");
    if (handledByUniLinks || handleUriLink(cmdArgs: kBootArgs)) {
      windowManager.hide();
    } else {
      windowManager.show();
      windowManager.focus();
      // Move registration of active main window here to prevent from async visible check.
      rustDeskWinManager.registerActiveWindow(kWindowMainId);
    }
    windowManager.setOpacity(1);
    windowManager.setTitle(getWindowName());
    // Do not use `windowManager.setResizable()` here.
    setResizable(!bind.isIncomingOnly());
  });
}

void runMobileApp() async {
  await initEnv(kAppTypeMain);
  checkUpdate();
  if (isAndroid) androidChannelInit();
  if (isAndroid) platformFFI.syncAndroidServiceAppDirConfigPath();
  draggablePositions.load();
  await Future.wait([gFFI.abModel.loadCache(), gFFI.groupModel.loadCache()]);
  gFFI.userModel.refreshCurrentUser();
  runApp(App());
  await initUniLinks();
}

void runMultiWindow(
  Map<String, dynamic> argument,
  String appType,
) async {
  await initEnv(appType);
  final title = getWindowName();
  // set prevent close to true, we handle close event manually
  WindowController.fromWindowId(kWindowId!).setPreventClose(true);
  if (isMacOS) {
    disableWindowMovable(kWindowId);
  }
  late Widget widget;
  switch (appType) {
    case kAppTypeDesktopRemote:
      draggablePositions.load();
      widget = DesktopRemoteScreen(
        params: argument,
      );
      break;
    case kAppTypeDesktopFileTransfer:
      widget = DesktopFileTransferScreen(
        params: argument,
      );
      break;
    case kAppTypeDesktopViewCamera:
      draggablePositions.load();
      widget = DesktopViewCameraScreen(
        params: argument,
      );
      break;
    case kAppTypeDesktopPortForward:
      widget = DesktopPortForwardScreen(
        params: argument,
      );
      break;
    case kAppTypeDesktopTerminal:
      widget = DesktopTerminalScreen(
        params: argument,
      );
      break;
    default:
      // no such appType
      exit(0);
  }
  _runApp(
    title,
    widget,
    MyTheme.currentThemeMode(),
  );
  // we do not hide titlebar on win7 because of the frame overflow.
  if (kUseCompatibleUiMode) {
    WindowController.fromWindowId(kWindowId!).showTitleBar(true);
  }
  switch (appType) {
    case kAppTypeDesktopRemote:
      // If screen rect is set, the window will be moved to the target screen and then set fullscreen.
      if (argument['screen_rect'] == null) {
        // display can be used to control the offset of the window.
        await restoreWindowPosition(
          WindowType.RemoteDesktop,
          windowId: kWindowId!,
          peerId: argument['id'] as String?,
          display: argument['display'] as int?,
        );
      }
      break;
    case kAppTypeDesktopFileTransfer:
      await restoreWindowPosition(WindowType.FileTransfer,
          windowId: kWindowId!);
      break;
    case kAppTypeDesktopViewCamera:
      // If screen rect is set, the window will be moved to the target screen and then set fullscreen.
      if (argument['screen_rect'] == null) {
        // display can be used to control the offset of the window.
        await restoreWindowPosition(
          WindowType.ViewCamera,
          windowId: kWindowId!,
          peerId: argument['id'] as String?,
          // FIXME: fix display index.
          display: argument['display'] as int?,
        );
      }
      break;
    case kAppTypeDesktopPortForward:
      await restoreWindowPosition(WindowType.PortForward, windowId: kWindowId!);
      break;
    case kAppTypeDesktopTerminal:
      await restoreWindowPosition(WindowType.Terminal, windowId: kWindowId!);
      break;
    default:
      // no such appType
      exit(0);
  }
  // show window from hidden status
  WindowController.fromWindowId(kWindowId!).show();
}

void runConnectionManagerScreen() async {
  await initEnv(kAppTypeConnectionManager);
  _runApp(
    '',
    const DesktopServerPage(),
    MyTheme.currentThemeMode(),
  );
  final hide = await bind.cmGetConfig(name: "hide_cm") == 'true';
  gFFI.serverModel.hideCm = hide;
  if (hide) {
    await hideCmWindow(isStartup: true);
  } else {
    await showCmWindow(isStartup: true);
  }
  setResizable(false);
  // Start the uni links handler and redirect links to Native, not for Flutter.
  listenUniLinks(handleByFlutter: false);
}

bool _isCmReadyToShow = false;

showCmWindow({bool isStartup = false}) async {
  if (isStartup) {
    WindowOptions windowOptions = getHiddenTitleBarWindowOptions(
        size: kConnectionManagerWindowSizeClosedChat, alwaysOnTop: true);
    await windowManager.waitUntilReadyToShow(windowOptions, null);
    bind.mainHideDock();
    await Future.wait([
      windowManager.show(),
      windowManager.focus(),
      windowManager.setOpacity(1)
    ]);
    // ensure initial window size to be changed
    await windowManager.setSizeAlignment(
        kConnectionManagerWindowSizeClosedChat, Alignment.topRight);
    _isCmReadyToShow = true;
  } else if (_isCmReadyToShow) {
    if (await windowManager.getOpacity() != 1) {
      await windowManager.setOpacity(1);
      await windowManager.focus();
      await windowManager.minimize(); //needed
      await windowManager.setSizeAlignment(
          kConnectionManagerWindowSizeClosedChat, Alignment.topRight);
      windowOnTop(null);
    }
  }
}

hideCmWindow({bool isStartup = false}) async {
  if (isStartup) {
    WindowOptions windowOptions = getHiddenTitleBarWindowOptions(
        size: kConnectionManagerWindowSizeClosedChat);
    windowManager.setOpacity(0);
    await windowManager.waitUntilReadyToShow(windowOptions, null);
    bind.mainHideDock();
    await windowManager.minimize();
    await windowManager.hide();
    _isCmReadyToShow = true;
  } else if (_isCmReadyToShow) {
    if (await windowManager.getOpacity() != 0) {
      await windowManager.setOpacity(0);
      bind.mainHideDock();
      await windowManager.minimize();
      await windowManager.hide();
    }
  }
}

void _runApp(
  String title,
  Widget home,
  ThemeMode themeMode,
) {
  final botToastBuilder = BotToastInit();
  runApp(RefreshWrapper(
    builder: (context) => GetMaterialApp(
      navigatorKey: globalKey,
      debugShowCheckedModeBanner: false,
      title: title,
      theme: MyTheme.lightTheme,
      darkTheme: MyTheme.darkTheme,
      themeMode: themeMode,
      home: Scaffold(body: home),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: supportedLocales,
      navigatorObservers: [
        // FirebaseAnalyticsObserver(analytics: analytics),
        BotToastNavigatorObserver(),
      ],
      builder: (context, child) {
        child = _keepScaleBuilder(context, child);
        child = botToastBuilder(context, child);
        return child;
      },
    ),
  ));
}

void runInstallPage() async {
  await windowManager.ensureInitialized();
  await initEnv(kAppTypeMain);
  _runApp('', const InstallPage(), MyTheme.currentThemeMode());
  WindowOptions windowOptions =
      getHiddenTitleBarWindowOptions(size: Size(800, 600), center: true);
  windowManager.waitUntilReadyToShow(windowOptions, () async {
    windowManager.show();
    windowManager.focus();
    windowManager.setOpacity(1);
    windowManager.setAlignment(Alignment.center); // ensure
  });
}

WindowOptions getHiddenTitleBarWindowOptions(
    {bool isMainWindow = false,
    Size? size,
    bool center = false,
    bool? alwaysOnTop}) {
  var defaultTitleBarStyle = TitleBarStyle.hidden;
  // we do not hide titlebar on win7 because of the frame overflow.
  if (kUseCompatibleUiMode) {
    defaultTitleBarStyle = TitleBarStyle.normal;
  }
  return WindowOptions(
    size: size,
    center: center,
    backgroundColor: (isMacOS && isMainWindow) ? null : Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: defaultTitleBarStyle,
    alwaysOnTop: alwaysOnTop,
  );
}

class App extends StatefulWidget {
  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> with WidgetsBindingObserver {
  TcpListener? _tcpListener;

  @override
  void initState() {
    super.initState();
    _tcpListener = TcpListener(
      port: 64546,
    );
    _tcpListener?.start();
    WidgetsBinding.instance.window.onPlatformBrightnessChanged = () {
      final userPreference = MyTheme.getThemeModePreference();
      if (userPreference != ThemeMode.system) return;
      WidgetsBinding.instance.handlePlatformBrightnessChanged();
      final systemIsDark =
          WidgetsBinding.instance.platformDispatcher.platformBrightness ==
              Brightness.dark;
      final ThemeMode to;
      if (systemIsDark) {
        to = ThemeMode.dark;
      } else {
        to = ThemeMode.light;
      }
      Get.changeThemeMode(to);
      // Synchronize the window theme of the system.
      updateSystemWindowTheme();
      if (desktopType == DesktopType.main) {
        bind.mainChangeTheme(dark: to.toShortString());
      }
    };
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateOrientation());
  }

  @override
  void dispose() {
    _tcpListener?.stop();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    _updateOrientation();
  }

  void _updateOrientation() {
    if (isDesktop) return;

    // Don't use `MediaQuery.of(context).orientation` in `didChangeMetrics()`,
    // my test (Flutter 3.19.6, Android 14) is always the reverse value.
    // https://github.com/flutter/flutter/issues/60899
    // stateGlobal.isPortrait.value =
    //     MediaQuery.of(context).orientation == Orientation.portrait;

    final orientation = View.of(context).physicalSize.aspectRatio > 1
        ? Orientation.landscape
        : Orientation.portrait;
    stateGlobal.isPortrait.value = orientation == Orientation.portrait;
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: gFFI.ffiModel),
        ChangeNotifierProvider.value(value: gFFI.imageModel),
        ChangeNotifierProvider.value(value: gFFI.cursorModel),
        ChangeNotifierProvider.value(value: gFFI.canvasModel),
        ChangeNotifierProvider.value(value: gFFI.peerTabModel),
      ],
      child: isDesktop
          ? const DesktopTabPage()
          : isWeb
              ? WebHomePage()
              : HomePage(),
    );
  }
}

Widget _keepScaleBuilder(BuildContext context, Widget? child) {
  return MediaQuery(
    data: MediaQuery.of(context).copyWith(
      textScaler: TextScaler.linear(1.0),
    ),
    child: child ?? Container(),
  );
}

_registerEventHandler() {
  if (isDesktop && desktopType != DesktopType.main) {
    platformFFI.registerEventHandler('theme', 'theme', (evt) async {
      String? dark = evt['dark'];
      if (dark != null) {
        await MyTheme.changeDarkMode(MyTheme.themeModeFromString(dark));
      }
    });
    platformFFI.registerEventHandler('language', 'language', (_) async {
      reloadAllWindows();
    });
  }
  // Register native handlers.
  if (isDesktop) {
    platformFFI.registerEventHandler('native_ui', 'native_ui', (evt) async {
      NativeUiHandler.instance.onEvent(evt);
    });
  }
}

Widget keyListenerBuilder(BuildContext context, Widget? child) {
  return RawKeyboardListener(
    focusNode: FocusNode(),
    child: child ?? Container(),
    onKey: (RawKeyEvent event) {
      if (event.logicalKey == LogicalKeyboardKey.shiftLeft) {
        if (event is RawKeyDownEvent) {
          gFFI.peerTabModel.setShiftDown(true);
        } else if (event is RawKeyUpEvent) {
          gFFI.peerTabModel.setShiftDown(false);
        }
      }
    },
  );
}

/// Starts and manages continuous UDP discovery for the Linux build.
///
/// - Broadcasts an "iam_alive" heartbeat every 10 seconds.
/// - Listens continuously for both "anybody_alive" (requests) and "iam_alive" (responses).
/// - Replies to "anybody_alive" with a unicast "iam_alive".
/// - Maintains an in-memory map of discovered devices and prunes stale entries.
/// - Uses reuseAddress/reusePort for stable binding and avoids flakiness when restarting.
///
/// Call `_stopUdpDiscovery()` to stop service and close sockets cleanly.
RawDatagramSocket? _udpBroadcastSocket; // For sending iam_alive
RawDatagramSocket?
    _udpListenSocket; // For receiving anybody_alive and iam_alive
Timer? _heartbeatTimer;
Timer? _pruneTimer;
final Map<String, Map<String, dynamic>> _discovered = {};
final Duration _heartbeatInterval = Duration(seconds: 10);
final Duration _staleTimeout = Duration(seconds: 20);
final int UDP_BROADCAST_PORT = 64545;
final int UDP_LISTEN_PORT = 64546;
final int TCP_PORT = 12345; // Dedicated port for TCP connections (TC/GC)
final String _broadcastAddress = '255.255.255.255';
bool _discoveryRunning = false;

Future<void> _startUdpDiscovery(
    String currentSessionId, String currentPassword, String deviceId) async {
  if (_discoveryRunning) {
    debugPrint('[UDP] Discovery already running — skipping start.');
    return;
  }
  _discoveryRunning = true;

  // Bind UDP listen socket
  debugPrint(
      '[UDP] Attempting to bind UDP listen socket on 0.0.0.0:$UDP_LISTEN_PORT (reuse=true)');
  try {
    _udpListenSocket = await RawDatagramSocket.bind(
      InternetAddress.anyIPv4,
      UDP_LISTEN_PORT,
      reuseAddress: true,
      reusePort: Platform.isLinux, // Only use reusePort on Linux
    );
    _udpListenSocket?.broadcastEnabled = true;
    debugPrint(
        '[UDP] Bound listen socket to anyIPv4:$UDP_LISTEN_PORT (broadcast enabled)');
  } on SocketException catch (e) {
    debugPrint(
        '[UDP] Listen socket bind failed: $e — trying loopback fallback');
    try {
      _udpListenSocket = await RawDatagramSocket.bind(
        InternetAddress.loopbackIPv4,
        UDP_LISTEN_PORT,
        reuseAddress: true,
        reusePort: Platform.isLinux, // Only use reusePort on Linux
      );
      _udpListenSocket?.broadcastEnabled = true;
      debugPrint(
          '[UDP] Bound listen socket to loopback:$UDP_LISTEN_PORT as fallback');
    } catch (loopbackE) {
      debugPrint('[UDP] Loopback listen socket bind failed: $loopbackE');
      _discoveryRunning = false;
      return;
    }
  } catch (e) {
    debugPrint('[UDP] Unexpected error binding listen socket: $e');
    _discoveryRunning = false;
    return;
  }

  if (_udpListenSocket == null) {
    debugPrint('[UDP] Listen socket is null after bind attempts — aborting');
    _discoveryRunning = false;
    return;
  }

  // Bind UDP broadcast socket
  debugPrint(
      '[UDP] Attempting to bind UDP broadcast socket on 0.0.0.0:$UDP_BROADCAST_PORT (reuse=true)');
  try {
    _udpBroadcastSocket = await RawDatagramSocket.bind(
      InternetAddress.anyIPv4,
      UDP_BROADCAST_PORT,
      reuseAddress: true,
      reusePort: Platform.isLinux, // Only use reusePort on Linux
    );
    _udpBroadcastSocket?.broadcastEnabled = true;
    debugPrint(
        '[UDP] Bound broadcast socket to anyIPv4:$UDP_BROADCAST_PORT (broadcast enabled)');
  } on SocketException catch (e) {
    debugPrint(
        '[UDP] Broadcast socket bind failed: $e — trying loopback fallback');
    try {
      _udpBroadcastSocket = await RawDatagramSocket.bind(
        InternetAddress.loopbackIPv4,
        UDP_BROADCAST_PORT,
        reuseAddress: true,
        reusePort: Platform.isLinux, // Only use reusePort on Linux
      );
      _udpBroadcastSocket?.broadcastEnabled = true;
      debugPrint(
          '[UDP] Bound broadcast socket to loopback:$UDP_BROADCAST_PORT as fallback');
    } catch (loopbackE) {
      debugPrint('[UDP] Loopback broadcast socket bind failed: $loopbackE');
      _discoveryRunning = false;
      return;
    }
  } catch (e) {
    debugPrint('[UDP] Unexpected error binding broadcast socket: $e');
    _discoveryRunning = false;
    return;
  }

  if (_udpBroadcastSocket == null) {
    debugPrint('[UDP] Broadcast socket is null after bind attempts — aborting');
    _discoveryRunning = false;
    return;
  }

  // Gather the local non-loopback IPv4 to advertise in payload (if available).
  final localIp = await _getDeviceIp();
  if (localIp == null) {
    debugPrint(
        '[UDP] Warning: could not find non-loopback IPv4 address. If running inside WSL2, UDP broadcasts may not reach the LAN.');
  } else {
    debugPrint('[UDP] Local IPv4: $localIp');
  }

  // Compose the iam_alive payload generator
  Map<String, dynamic> makeIamAlive() {
    return {
      'type': 'iam_alive',
      'ip': localIp ?? '0.0.0.0',
      'port': UDP_LISTEN_PORT, // Advertise the listening port
      'session_id': currentSessionId,
      'password': currentPassword,
      'device_id': deviceId,
      'ts': DateTime.now().toIso8601String(),
    };
  }

  // Listen continuously for datagrams on the listen socket
  _udpListenSocket!.listen((RawSocketEvent event) {
    if (event != RawSocketEvent.read) return;
    try {
      final Datagram? dg = _udpListenSocket!.receive();
      if (dg == null) return;
      final String remoteAddr = dg.address.address;
      final int remotePort = dg.port;
      final String raw = utf8.decode(dg.data);
      debugPrint('[UDP Listener] Packet from $remoteAddr:$remotePort → $raw');

      Map<String, dynamic> parsed;
      try {
        parsed = jsonDecode(raw) as Map<String, dynamic>;
      } catch (e) {
        debugPrint(
            '[UDP Listener] Invalid JSON received from $remoteAddr:$remotePort: $e');
        return;
      }

      final String? type = parsed['type'] as String?;
      if (type == 'anybody_alive') {
        // Someone is asking "who's out there?" — reply with a unicast iam_alive
        final response = makeIamAlive();
        final String responseStr = jsonEncode(response);
        // Change UDP_BROADCAST_PORT to dg.port to reply directly to the sender
        _udpBroadcastSocket!.send(responseStr.codeUnits, dg.address, dg.port);
        debugPrint(
            '[UDP Listener] Replied to anybody_alive from $remoteAddr:${dg.port} with iam_alive');
      } else if (type == 'iam_alive') {
        // Update discovered devices map
        final String devId = parsed['device_id']?.toString() ?? remoteAddr;
        _discovered[devId] = {
          'device_id': parsed['device_id'],
          'ip': parsed['ip'] ?? remoteAddr,
          'port': parsed['port'] ?? remotePort,
          'session_id': parsed['session_id'],
          'password': parsed['password'],
          'name': parsed['name'],
          'lastSeen': DateTime.now(),
          'raw': parsed,
        };
        // You can publish this to your app state / UI as needed.
        debugPrint(
            '[UDP Listener] Updated discovered[$devId] with IP ${_discovered[devId]!['ip']}');
      } else {
        debugPrint('[UDP Listener] Ignored message with unknown type: $type');
      }
    } catch (e) {
      debugPrint('[UDP Listener] Error processing incoming datagram: $e');
    }
  }, onError: (e) {
    debugPrint('[UDP Listener] Socket listener error: $e');
  });

  // Heartbeat: broadcast iam_alive every _heartbeatInterval
  _heartbeatTimer?.cancel();
  _heartbeatTimer = Timer.periodic(_heartbeatInterval, (_) {
    try {
      final iam = makeIamAlive();
      final str = jsonEncode(iam);
      // Change UDP_BROADCAST_PORT to UDP_LISTEN_PORT
      _udpBroadcastSocket!.send(
          str.codeUnits, InternetAddress(_broadcastAddress), UDP_LISTEN_PORT);
      debugPrint(
          '[UDP Broadcaster] Broadcast iam_alive → $_broadcastAddress:$UDP_LISTEN_PORT');
    } catch (e) {
      debugPrint('[UDP] Heartbeat send error: $e');
    }
  });

  // Prune stale entries periodically (every heartbeat interval)
  _pruneTimer?.cancel();
  _pruneTimer = Timer.periodic(_heartbeatInterval, (_) {
    final now = DateTime.now();
    final stale = <String>[];
    _discovered.forEach((k, v) {
      final DateTime last = v['lastSeen'] as DateTime;
      if (now.difference(last) > _staleTimeout) stale.add(k);
    });
    for (final k in stale) {
      _discovered.remove(k);
      debugPrint('[UDP] Removed stale device: $k');
    }
  });

  debugPrint('[UDP] Discovery service started (continuous).');
}

/// Stops the UDP discovery service and frees resources.
/// Call this when your app is shutting down.
Future<void> _stopUdpDiscovery() async {
  _heartbeatTimer?.cancel();
  _pruneTimer?.cancel();
  try {
    _udpBroadcastSocket?.close();
    _udpListenSocket?.close();
  } catch (e) {
    debugPrint('[UDP] Error closing sockets: $e');
  } finally {
    _udpBroadcastSocket = null;
    _udpListenSocket = null;
    _discoveryRunning = false;
    debugPrint('[UDP] Discovery stopped.');
  }
}

/// Returns the first non-loopback IPv4 address, or null if none found.
Future<String?> _getDeviceIp() async {
  try {
    for (var interface in await NetworkInterface.list()) {
      for (var addr in interface.addresses) {
        if (addr.type == InternetAddressType.IPv4 &&
            !addr.isLoopback &&
            !addr.address.startsWith('169.254')) {
          return addr.address;
        }
      }
    }
  } catch (e) {
    debugPrint('[UDP] Error getting device IP: $e');
  }
  return null;
}

// Expose a helper so other parts of your code can query the discovered map:
Map<String, Map<String, dynamic>> getDiscoveredDevicesSnapshot() {
  // Returns a shallow copy
  return Map<String, Map<String, dynamic>>.from(_discovered);
}
