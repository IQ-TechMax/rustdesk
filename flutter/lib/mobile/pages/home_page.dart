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
          body: Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/XconnectBackground.png'),
                fit: BoxFit.cover,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const SizedBox(height: 80), // equal space above logo
                Center(
                  child: Image.asset(
                    'assets/xConnect-Logo.png',
                    width: 200, // reduced logo size
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(
                    height: 40), // equal space between logo and blur card
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(
                      left: 25.0,
                      right: 25.0,
                      bottom: 25.0,
                    ), // custom margins
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16.0),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(16.0),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.08),
                            ),
                          ),
                          alignment: Alignment.topLeft,
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Devices',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Container(),
                                ],
                              ),
                              const SizedBox(height: 20),
                              Expanded(
                                child: Obx(() {
                                  if (_deviceDiscoveryController
                                          .isLoading.value &&
                                      _deviceDiscoveryController
                                          .discoveredDevices.isEmpty) {
                                    // This part is fine, it will be centered in the expanded space
                                    return Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          CircularProgressIndicator(
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                    Colors.white),
                                          ),
                                          SizedBox(height: 10),
                                          Text(
                                            "🔍 Finding devices...",
                                            style:
                                                TextStyle(color: Colors.white),
                                          ),
                                        ],
                                      ),
                                    );
                                  } else if (_deviceDiscoveryController
                                      .discoveredDevices.isEmpty) {
                                    // This part is also fine
                                    return const Center(
                                      child: Text(
                                        "No devices available",
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    );
                                  } else {
                                    // This is where the scroll view is needed.
                                    // The SingleChildScrollView now has a constrained height from the Expanded widget
                                    // and can correctly render the Wrap widget with a scrollbar if needed.
                                    return SingleChildScrollView(
                                      child: Wrap(
                                        alignment: WrapAlignment.center,
                                        runAlignment: WrapAlignment.center,
                                        spacing: 20,
                                        runSpacing: 20,
                                        children: _deviceDiscoveryController
                                            .discoveredDevices
                                            .map((device) {
                                          return DeviceCard(
                                            device: device,
                                            logoPath: 'assets/devices-icon.png',
                                          );
                                        }).toList(),
                                      ),
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
        ));
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

class DeviceCard extends StatelessWidget {
  final Device device;
  final String logoPath;

  const DeviceCard({
    super.key,
    required this.device,
    required this.logoPath,
  });

  @override
  Widget build(BuildContext context) {
    const double iconDiameter = 70.0;
    const double cardHeight = 65;
    const double cardWidth = 300.0;
    const double blurBackgroundStartX = iconDiameter / 2;
    const double blurBackgroundPadding = 15.0;

    RxBool isConnecting = RxBool(false);
    RxBool isAlreadyConnected = RxBool(false);

    debugPrint('connected clients ${gFFI.serverModel.clients}');

    return InkWell(
      onTap: () async {
        if (isAlreadyConnected.value) {
          isConnecting.value = false;
          return;
        }
        final selectedAction = await showXConnectOptionsDialog(context);
        if (selectedAction != null) {
          try {
            switch (selectedAction) {
              case DeviceAction.xBoard:
                debugPrint('[ACTION] Executing xBoard logic...');
                await _shareAndroidToLinux(device);
                const String whiteboardAppPackageName = "cn.readpad.whiteboard";
                try {
                  // Use url_launcher to open the app by its package name
                  if (!await launchUrl(
                      Uri.parse('android-app://$whiteboardAppPackageName'))) {
                    // This is a fallback if launchUrl doesn't work as expected on some devices
                    await gFFI.invokeMethod("launch_another_app",
                        {"package_name": whiteboardAppPackageName});
                  }
                  debugPrint(
                      '[UI] Launch intent sent for $whiteboardAppPackageName');
                } catch (e) {
                  debugPrint('[UI] Failed to launch whiteboard app: $e');
                }

                break;
              case DeviceAction.xCast:
                debugPrint('[ACTION] Executing xCast logic...');
                await _shareAndroidToLinux(device);
                break;
              case DeviceAction.xCtrl:
                debugPrint('[ACTION] Executing xCtrl logic...');
                await _shareLinuxToAndroid(device, isBlankScreen: true);
                break;
              case DeviceAction.xCtrlView:
                debugPrint('[ACTION] Executing xCtrlView logic...');
                await _shareLinuxToAndroid(device, isViewOnly: true);
                break;
            }

            isConnecting.value = false;
            isAlreadyConnected.value = true;
          } catch (e) {
            isConnecting.value = false;
            debugPrint(
                '[UI] Error handling connection action for ${device.schoolName}: $e');
          }
        }
      },
      child: Container(
        color: Colors.transparent,
        width: cardWidth,
        height: cardHeight,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.centerLeft,
          children: [
            Positioned(
              left: blurBackgroundStartX,
              right: 0,
              top: 0,
              bottom: 0,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15.0),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              top: (cardHeight - iconDiameter) / 2,
              child: Container(
                width: iconDiameter,
                height: iconDiameter,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6C63FF), Color(0xFF3F37C9)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Container(
                    width: iconDiameter - 10,
                    height: iconDiameter - 10,
                    decoration: const BoxDecoration(
                      color: Color(0xFF3F37C9),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Image.asset(
                        logoPath,
                        width: 50,
                        height: 50,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: iconDiameter + blurBackgroundPadding,
              top: (cardHeight - 45) / 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    device.schoolName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Obx(() {
                    // FIX 2: Simplify status logic
                    bool isBusy = device.tcpStatus.value == 'Busy';
                    return Text(
                      isBusy ? 'Busy' : 'Online',
                      style: TextStyle(
                        color: isBusy ? Colors.yellow : Colors.green,
                        fontSize: 14,
                      ),
                    );
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

  await XConnectTcpManager.to.sendRequest(device.ip, tcPayload);
  debugPrint('[TC] TC info sent to ${device.ip}:${device.port}');
}

Future<void> _shareLinuxToAndroid(Device device,
    {bool isBlankScreen = false, bool isViewOnly = false}) async {
  debugPrint('[UI] GC button clicked for ${device.schoolName}');

  final response = await XConnectTcpManager.to
      .sendRequest(device.ip, {"action": "GC_REQUEST"});

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
