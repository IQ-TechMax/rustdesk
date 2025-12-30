import 'package:flutter/material.dart';
import 'package:flutter_hbb/mobile/pages/server_page.dart';
import 'package:flutter_hbb/mobile/pages/settings_page.dart';
import 'package:flutter_hbb/web/settings_page.dart';
import 'package:get/get.dart';
import '../../common.dart';
import '../../common/widgets/chat_page.dart';
import '../../models/platform_model.dart';
import '../../models/state_model.dart';
import 'connection_page.dart';
import 'package:flutter_hbb/models/device_discovery_model.dart'; // Import the new model
import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/foundation.dart'; // For debugPrint
import 'package:flutter_hbb/utils/xconnect_tcp_manager.dart';
import 'package:flutter_hbb/utils/platform_channel.dart';
import 'package:flutter_hbb/mobile/widgets/xConnectOptions.dart';
import 'package:flutter_hbb/main.dart'; // Ensure globalKey is accessible
import 'package:url_launcher/url_launcher.dart';

Future<String?> getLocalIpFallback() async {
  try {
    for (var interface in await NetworkInterface.list()) {
      for (var addr in interface.addresses) {
        if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
          return addr.address;
        }
      }
    }
  } catch (e) {
    debugPrint('Failed to get local IP: $e');
  }
  return '127.0.0.1';
}

abstract class PageShape extends Widget {
  final String title = "";
  final Widget icon = Icon(null);
  final List<Widget> appBarActions = [];
}

class HomePage extends StatefulWidget {
  static final homeKey = GlobalKey<HomePageState>();

  HomePage() : super(key: homeKey);

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  var _selectedIndex = 0;
  int get selectedIndex => _selectedIndex;
  final List<PageShape> _pages = [];
  int _chatPageTabIndex = -1;
  bool get isChatPageCurrentTab => isAndroid
      ? _selectedIndex == _chatPageTabIndex
      : false; // change this when ios have chat page

  late final DeviceDiscoveryController _deviceDiscoveryController =
      Get.put(DeviceDiscoveryController());

  void refreshPages() {
    setState(() {
      initPages();
    });
  }

  @override
  void initState() {
    super.initState();
    debugPrint('[UI] Splash completed, starting device discovery');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _deviceDiscoveryController.startDiscovery();
    });
    initPages();
  }

  void initPages() {
    _pages.clear();
    if (!bind.isIncomingOnly()) {
      _pages.add(ConnectionPage(
        appBarActions: [],
      ));
    }
    if (isAndroid && !bind.isOutgoingOnly()) {
      _chatPageTabIndex = _pages.length;
      _pages.addAll([ChatPage(type: ChatPageType.mobileMain), ServerPage()]);
    }
    _pages.add(SettingsPage());
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () async {
          if (_selectedIndex != 0) {
            setState(() {
              _selectedIndex = 0;
            });
          } else {
            return true;
          }
          return false;
        },
        child: Scaffold(
            // backgroundColor: MyTheme.grayBg,
            // appBar: AppBar(
            //   centerTitle: true,
            //   title: appTitle(),
            //   // actions: _pages.elementAt(_selectedIndex).appBarActions,
            // ),
            // bottomNavigationBar: BottomNavigationBar(
            //   key: navigationBarKey,
            //   items: _pages
            //       .map((page) =>
            //           BottomNavigationBarItem(icon: page.icon, label: page.title))
            //       .toList(),
            //   currentIndex: _selectedIndex,
            //   type: BottomNavigationBarType.fixed,
            //   selectedItemColor: MyTheme.accent, //
            //   unselectedItemColor: MyTheme.darkGray,
            //   onTap: (index) => setState(() {
            //     // close chat overlay when go chat page
            //     if (_selectedIndex != index) {
            //       _selectedIndex = index;
            //       if (isChatPageCurrentTab) {
            //         gFFI.chatModel.hideChatIconOverlay();
            //         gFFI.chatModel.hideChatWindowOverlay();
            //         gFFI.chatModel.mobileClearClientUnread(
            //             gFFI.chatModel.currentKey.connId);
            //       }
            //     }
            //   }),
            // ),
            body: DeviceSelectionScreen(_deviceDiscoveryController)));
  }

  Widget appTitle() {
    final currentUser = gFFI.chatModel.currentUser;
    final currentKey = gFFI.chatModel.currentKey;
    if (isChatPageCurrentTab &&
        currentUser != null &&
        currentKey.peerId.isNotEmpty) {
      final connected =
          gFFI.serverModel.clients.any((e) => e.id == currentKey.connId);
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Tooltip(
            message: currentKey.isOut
                ? translate('Outgoing connection')
                : translate('Incoming connection'),
            child: Icon(
              currentKey.isOut
                  ? Icons.call_made_rounded
                  : Icons.call_received_rounded,
            ),
          ),
          Expanded(
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "${currentUser.firstName}   ${currentUser.id}",
                  ),
                  if (connected)
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color.fromARGB(255, 133, 246, 199)),
                    ).marginSymmetric(horizontal: 2),
                ],
              ),
            ),
          ),
        ],
      );
    }
    return Text(bind.mainGetAppNameSync());
  }
}

class WebHomePage extends StatelessWidget {
  final connectionPage =
      ConnectionPage(appBarActions: <Widget>[const WebSettingsPage()]);

  @override
  Widget build(BuildContext context) {
    stateGlobal.isInMainPage = true;
    handleUnilink(context);
    return Scaffold(
      // backgroundColor: MyTheme.grayBg,
      appBar: AppBar(
        centerTitle: true,
        title: Text("${bind.mainGetAppNameSync()} (Preview)"),
        actions: connectionPage.appBarActions,
      ),
      body: connectionPage,
    );
  }

  handleUnilink(BuildContext context) {
    if (webInitialLink.isEmpty) {
      return;
    }
    final link = webInitialLink;
    webInitialLink = '';
    final splitter = ["/#/", "/#", "#/", "#"];
    var fakelink = '';
    for (var s in splitter) {
      if (link.contains(s)) {
        var list = link.split(s);
        if (list.length < 2 || list[1].isEmpty) {
          return;
        }
        list.removeAt(0);
        fakelink = "rustdesk://${list.join(s)}";
        break;
      }
    }
    if (fakelink.isEmpty) {
      return;
    }
    final uri = Uri.tryParse(fakelink);
    if (uri == null) {
      return;
    }
    final args = urlLinkToCmdArgs(uri);
    if (args == null || args.isEmpty) {
      return;
    }
    bool isFileTransfer = false;
    bool isViewCamera = false;
    bool isTerminal = false;
    String? id;
    String? password;
    for (int i = 0; i < args.length; i++) {
      switch (args[i]) {
        case '--connect':
        case '--play':
          id = args[i + 1];
          i++;
          break;
        case '--file-transfer':
          isFileTransfer = true;
          id = args[i + 1];
          i++;
          break;
        case '--view-camera':
          isViewCamera = true;
          id = args[i + 1];
          i++;
          break;
        case '--terminal':
          isTerminal = true;
          id = args[i + 1];
          i++;
          break;
        case '--terminal-admin':
          setEnvTerminalAdmin();
          isTerminal = true;
          id = args[i + 1];
          i++;
          break;
        case '--password':
          password = args[i + 1];
          i++;
          break;
        default:
          break;
      }
    }
    if (id != null) {
      connect(context, id,
          isFileTransfer: isFileTransfer,
          isViewCamera: isViewCamera,
          isTerminal: isTerminal,
          password: password);
    }
  }
}

class DeviceSelectionScreen extends StatelessWidget {
  final DeviceDiscoveryController _deviceDiscoveryController;

  const DeviceSelectionScreen(this._deviceDiscoveryController, {Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 1. Determine Layout Metrics
        final double screenWidth = constraints.maxWidth;
        final double screenHeight = constraints.maxHeight;

        // Breakpoints
        final bool isTablet = screenWidth >= 850;
        final bool isLandscapePhone = !isTablet && (screenWidth > screenHeight);

        debugPrint(
            '[UI] Screen Size: ${screenWidth}x$screenHeight | isTablet: $isTablet | isLandscapePhone: $isLandscapePhone');

        // Dynamic Values
        final double logoSize =
            isLandscapePhone ? 120.0 : (isTablet ? 220.0 : 180.0);
        final double sidePadding = isTablet ? 40.0 : 16.0;
        final double verticalGap =
            isLandscapePhone ? 10.0 : (isTablet ? 80.0 : 50.0);

        // Grid Configuration
        final double cardHeight = 80.0;
        final double gridMaxCrossAxisExtent = isTablet ? 450.0 : 500.0;

        return Scaffold(
          resizeToAvoidBottomInset: false,
          body: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/XconnectBackground.png'),
                fit: BoxFit.cover,
              ),
            ),
            child: SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  SizedBox(height: verticalGap),

                  // Responsive Logo
                  Flexible(
                    flex: 0,
                    child: Image.asset(
                      'assets/xConnect-Logo.png',
                      width: logoSize,
                      fit: BoxFit.contain,
                    ),
                  ),

                  SizedBox(height: isLandscapePhone ? 15 : 40),

                  // Glass Panel
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(sidePadding, 0, sidePadding,
                          isLandscapePhone ? 10 : 30),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20.0),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E1E1E).withOpacity(0.75),
                              borderRadius: BorderRadius.circular(20.0),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.1),
                                width: 1,
                              ),
                            ),
                            padding: EdgeInsets.all(isTablet ? 32.0 : 16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Header
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Devices',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: isTablet ? 24 : 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    // Optional: Add a refresh icon here if needed
                                    IconButton(
                                      onPressed: () {
                                        _deviceDiscoveryController
                                            .refreshDiscovery();
                                      },
                                      icon: const Icon(Icons.refresh,
                                          color: Colors.white),
                                      tooltip: 'Refresh',
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 15),

                                // Device List
                                Expanded(
                                  child: Obx(() {
                                    if (_deviceDiscoveryController
                                            .isLoading.value &&
                                        _deviceDiscoveryController
                                            .discoveredDevices.isEmpty) {
                                      return const Center(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            CircularProgressIndicator(
                                                color: Colors.white),
                                            SizedBox(height: 10),
                                            Text("🔍 Finding devices...",
                                                style: TextStyle(
                                                    color: Colors.white)),
                                          ],
                                        ),
                                      );
                                    } else if (_deviceDiscoveryController
                                        .discoveredDevices.isEmpty) {
                                      return const Center(
                                        child: Text(
                                          "No devices available",
                                          style:
                                              TextStyle(color: Colors.white70),
                                        ),
                                      );
                                    } else {
                                      // Responsive Grid View
                                      return GridView.builder(
                                        padding:
                                            const EdgeInsets.only(bottom: 20),
                                        gridDelegate:
                                            SliverGridDelegateWithMaxCrossAxisExtent(
                                          maxCrossAxisExtent:
                                              gridMaxCrossAxisExtent,
                                          mainAxisExtent: cardHeight,
                                          crossAxisSpacing: 20,
                                          mainAxisSpacing: 20,
                                        ),
                                        itemCount: _deviceDiscoveryController
                                            .discoveredDevices.length,
                                        itemBuilder: (context, index) {
                                          final device =
                                              _deviceDiscoveryController
                                                  .discoveredDevices[index];
                                          return DeviceCard(
                                            device: device,
                                            logoPath: 'assets/devices-icon.png',
                                            // Pass dimensions down to card for calculation
                                            totalHeight: cardHeight,
                                            isTablet: isTablet,
                                          );
                                        },
                                      );
                                    }
                                  }),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class DeviceCard extends StatefulWidget {
  final Device device;
  final String logoPath;
  final double totalHeight;
  final bool isTablet;

  const DeviceCard({
    super.key,
    required this.device,
    required this.logoPath,
    required this.totalHeight,
    required this.isTablet,
  });

  @override
  State<DeviceCard> createState() => _DeviceCardState();
}

class _DeviceCardState extends State<DeviceCard> {
  final RxBool isConnecting = false.obs;
  final RxBool isDisconnecting = false.obs;

  @override
  Widget build(BuildContext context) {
    // 2. Adaptive Icon Size
    // Tablet: 80px icon | Mobile: 60px icon
    final double iconDiameter = 80.0;

    return InkWell(
      onTap: () async {
        if (widget.device.isConnected.value == true) {
          try {
            if (isDisconnecting.value) {
              return; // Prevent multiple taps while disconnecting
            }
            isDisconnecting.value = true;
            if (widget.device.connectionType.value == ConnectionType.incoming) {
              await sendTCPRequest(
                  widget.device.ip, {"action": "CLOSE_CONNECTION"});
            }
          } catch (e) {
            debugPrint('[UI] Disconnection error: $e');
          }
        } else {
          if (isConnecting.value) {
            return; // Prevent multiple taps while connecting
          }

          final selectedAction = await showXConnectOptionsDialog(context);

          if (selectedAction != null) {
            isConnecting.value = true;
            try {
              switch (selectedAction) {
                case DeviceAction.xBoard:
                  await _shareAndroidToLinux(widget.device);
                  const String whiteboardAppPackageName =
                      "cn.readpad.whiteboard";
                  try {
                    if (!await launchUrl(
                        Uri.parse('android-app://$whiteboardAppPackageName'))) {
                      await gFFI.invokeMethod("launch_another_app",
                          {"package_name": whiteboardAppPackageName});
                    }
                  } catch (e) {
                    debugPrint('[UI] Failed to launch app: $e');
                  }
                  break;
                case DeviceAction.xCast:
                  await _shareAndroidToLinux(widget.device);
                  break;
                case DeviceAction.xCtrl:
                  await _shareLinuxToAndroid(widget.device,
                      isBlankScreen: true);
                  break;
                case DeviceAction.xCtrlView:
                  await _shareLinuxToAndroid(widget.device, isViewOnly: true);
                  break;
              }
              if (mounted) setState(() {});
            } catch (e) {
              debugPrint('[UI] Error: $e');
            }
          }
        }
      },
      child: SizedBox(
        height: widget.totalHeight,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.centerLeft,
          children: [
            // 1. Blur Background Card
            Positioned(
              left: iconDiameter / 2,
              right: 0,
              // Centered vertically with margin
              top: 8,
              bottom: 8,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15.0),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(15.0),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                  ),
                ),
              ),
            ),

            // 2. Floating Icon
            // Mathematically centered vertically
            Positioned(
              left: 0,
              top: 0,
              child: Container(
                width: iconDiameter,
                height: iconDiameter,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFF6C63FF), Color(0xFF3F37C9)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black38,
                        blurRadius: 8,
                        offset: Offset(0, 4))
                  ],
                ),
                padding: const EdgeInsets.all(2),
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFF3F37C9),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Image.asset(
                      widget.logoPath,
                      width: iconDiameter * 0.55,
                      height: iconDiameter * 0.55,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),

            // 3. Text Content
            Positioned(
              left: iconDiameter + 15,
              right: 15,
              top: 0,
              bottom: 0,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.device.schoolName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      // Larger font for Tablet
                      fontSize: widget.isTablet ? 18 : 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Obx(() {
                    if (widget.device.isConnected.value == true) {
                      if (isConnecting.value) {
                        isConnecting.value = false;
                      }
                      return Text("Disconnect",
                          style: TextStyle(
                              color: Colors.redAccent,
                              fontSize: 13,
                              fontWeight: FontWeight.bold));
                    } else {
                      if (isDisconnecting.value) {
                        isDisconnecting.value = false;
                      }

                      if (isConnecting.value) {
                        return const Text("Connecting...",
                            style:
                                TextStyle(color: Colors.yellow, fontSize: 13));
                      }

                      return Text(
                        'Online',
                        style: TextStyle(
                          color: Colors.greenAccent,
                          fontSize: 13,
                        ),
                      );
                    }
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _shareAndroidToLinux(Device device) async {
  debugPrint('[UI] TC button clicked for ${device.schoolName}');

  if (!gFFI.serverModel.inputOk) {
    debugPrint(
        '[TC] Remote input service is not active. Requesting permission...');
    gFFI.serverModel.toggleInput();
    // uncomment below when input permission is not mandatory
    // isCanceled.value = true;
    // return;
  }

  final localIp = await getLocalIpFallback();
  final availablePort = 12345;
  final rustDeskPassword = gFFI.serverModel.serverPasswd.text;

  if (localIp == null) {
    debugPrint('[TC] Failed to get local IP.');
    return;
  }

  final tcPayload = {
    "action": "TC",
    "ip": localIp,
    "port": availablePort,
    "password": rustDeskPassword,
  };

  debugPrint('[TC] Sending TC info to ${device.ip}:${device.port}: $tcPayload');

  await sendTCPRequest(device.ip, tcPayload);
  debugPrint('[TC] TC info sent to ${device.ip}:${device.port}');
}

Future<void> _shareLinuxToAndroid(Device device,
    {bool isBlankScreen = false, bool isViewOnly = false}) async {
  debugPrint('[UI] GC button clicked for ${device.schoolName}');

  final response = await sendTCPRequest(device.ip, {"action": "GC_REQUEST"});

  debugPrint('[GC] ✅ Received GC_ACK - $response');

  if (response != null && response['action'] == 'GC_RESPONSE') {
    debugPrint('[GC] ✅ Received GC_ACK from ${device.ip}');
    debugPrint('[GC] Linux device info: '
        'IP=${response['ip']}, PORT=${response['port']}, PASSWORD=${response['password']}');
    final String targetIp = response['ip'];
    final int targetPort = response['port'] ?? 12345;
    final String password = response['password'];

    debugPrint('[GC] Auto-connecting to $targetIp:$targetPort');

    gFFI.dialogManager.setPasswordForAutoConnect(password);
    if (globalKey.currentContext != null) {
      await connect(globalKey.currentContext!, '$targetIp:$targetPort',
          password: password,
          isViewOnly: isViewOnly,
          isBlankScreen: isBlankScreen);
    }
  } else {
    debugPrint('[GC] ❌ No valid GC_ACK or no response');
    throw Exception('No valid GC_ACK or no response');
  }
}
