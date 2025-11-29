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
import 'package:flutter_hbb/utils/tcp_helpers.dart';
import 'package:flutter_hbb/utils/platform_channel.dart';

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
      
  late final DeviceDiscoveryController _deviceDiscoveryController = Get.put(DeviceDiscoveryController());

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
                    image: AssetImage('assets/XconnectBackground.jpg'),
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
                          left: 45.0,
                          right: 45.0,
                          bottom: 55.0,
                        ), // custom margins
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16.0),
                          child: BackdropFilter(
                            filter:
                                ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
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
                                  Obx(() {
                                    if (_deviceDiscoveryController
                                            .isLoading.value &&
                                        _deviceDiscoveryController
                                            .discoveredDevices.isEmpty) {
                                      debugPrint(
                                          "[UI] Device discovery is loading");
                                      return Center(
                                        child: Column(
                                          children: [
                                            CircularProgressIndicator(
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                      Colors.white),
                                            ),
                                            SizedBox(height: 10),
                                            Text(
                                              "🔍 Finding devices...",
                                              style: TextStyle(
                                                  color: Colors.white),
                                            ),
                                          ],
                                        ),
                                      );
                                    } else if (_deviceDiscoveryController
                                        .discoveredDevices.isEmpty) {
                                      debugPrint(
                                          "[UI] Discovery complete, No devices found");
                                      return Center(
                                        child: Text(
                                          "No devices available",
                                          style: TextStyle(color: Colors.white),
                                        ),
                                      );
                                    } else {
                                      debugPrint(
                                          "[UI] Discovery complete, ${_deviceDiscoveryController.discoveredDevices.length} devices found");
                                      return Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _deviceDiscoveryController
                                                .statusText.value,
                                            style:
                                                TextStyle(color: Colors.white),
                                          ),
                                          const SizedBox(height: 10),
                                          Center(
                                            child: Wrap(
                                              alignment: WrapAlignment.center,
                                              runAlignment:
                                                  WrapAlignment.center,
                                              spacing: 20,
                                              runSpacing: 20,
                                              children:
                                                  _deviceDiscoveryController
                                                      .discoveredDevices
                                                      .map((device) {
                                                final String schoolName = "Device ID : ${device.schoolName}";
                                                const statusColor =
                                                    Colors.green;
                                                debugPrint(
                                                    "UI: Rendering device: $schoolName, online: true");
                                                return DeviceCard(
                                                  device: device,
                                                  logoPath:
                                                      'assets/devices-icon.png',
                                                );
                                              }).toList(),
                                            ),
                                          ),
                                        ],
                                      );
                                    }
                                  }),
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
    const double iconDiameter = 70.0; // Diameter of the icon circle
    const double cardHeight = 65; // Slightly taller than icon for padding
    const double cardWidth = 300.0; // Overall width of the component

    // Horizontal offset for the blur background relative to the icon's center
    // If blur starts from icon's center, its left will be iconDiameter / 2
    const double blurBackgroundStartX = iconDiameter / 2;
    const double blurBackgroundPadding =
        15.0; // Internal padding for text within the blur

    return Container(
      // Optional: A container for the entire card if it has a consistent dark background,
      // otherwise, this can be transparent. Based on the image, the dark background is global.
      color:
          Colors.transparent, // Assuming the dark blue is the screen background
      width: cardWidth,
      height: cardHeight,
      child: Stack(
        clipBehavior: Clip.none, // Allow children to paint outside its bounds
        alignment: Alignment.centerLeft,
        children: [
          // 1. The Blurred Background for Text
          Positioned(
            left: blurBackgroundStartX, // Start from the center of the icon
            right: 0, // Extends to the right edge of the card
            top: 0,
            bottom: 0,
            child: ClipRRect(
              borderRadius:
                  BorderRadius.circular(15.0), // Rounded corners for the blur
              child: BackdropFilter(
                filter:
                    ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0), // Apply blur
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(
                        0.1), // Semi-transparent overlay for frosted effect
                    // No need for a borderRadius here if ClipRRect handles it
                  ),
                ),
              ),
            ),
          ),

          // 2. Icon (positioned absolutely to overlap the blur)
          Positioned(
            left: 0, // Starts at the very left of the Stack
            top: (cardHeight - iconDiameter) / 2, // Vertically center the icon
            child: Container(
              width: iconDiameter,
              height: iconDiameter,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF6C63FF), // Lighter purple
                    Color(0xFF3F37C9), // Darker purple
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [],
              ),
              child: Center(
                child: Container(
                  width: iconDiameter -
                      10, // Slightly smaller to show the gradient border
                  height: iconDiameter - 10,
                  decoration: const BoxDecoration(
                    color: Color(
                        0xFF3F37C9), // Darker inner color for the icon background
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

          // 3. Text Content (positioned over the blur, aligned with icon's start)
          Positioned(
            left: iconDiameter +
                blurBackgroundPadding, // Icon diameter + padding to start text
            top: (cardHeight - 45) /
                2, // Adjust to vertically center the text block, assuming approx height 45
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min, // Take minimum space needed
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
                  Color statusColor;
                  String statusText = device.tcpStatus.value;
                  switch (device.tcpStatus.value) {
                    case 'Connecting...':
                      statusColor = Colors.orange;
                      break;
                    case 'Cannot connect':
                      statusColor = Colors.red;
                      break;
                    case 'Ready':
                    case 'Connected':
                    case 'Sending info...':
                    case 'Info sent':
                      statusColor = Colors.green;
                      statusText = 'Online';
                      break;
                    default:
                      statusColor = Colors.grey;
                  }
                  return Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        statusText,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(
                          width: 10), // Spacing between status and buttons
                      TextButton(
                        onPressed: () => _handleGcButtonClick(device),
                        style: TextButton.styleFrom(
                          padding:
                              EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          side: BorderSide(color: Colors.white70, width: 1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: Text(
                          'GC',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 5), // Spacing between buttons
                      TextButton(
                        onPressed: () => _handleTcButtonClick(device),
                        style: TextButton.styleFrom(
                          padding:
                              EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          side: BorderSide(color: Colors.white70, width: 1),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(20), // Pill shape
                          ),
                        ),
                        child: Text(
                          'TC',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _handleTcButtonClick(Device device) async {
  debugPrint('[UI] TC button clicked for ${device.schoolName}');
  device.tcpStatus.value = 'Sending info...';

  final localIp = await getLocalIpFallback();
  final availablePort = 12345;
  final rustDeskPassword = gFFI.serverModel.serverPasswd.text;

  if (localIp == null) {
    debugPrint('[TC][Windows] Failed to get local IP.');
    device.tcpStatus.value = 'Failed';
    return;
  }

  final tcPayload = {
    "action": "TC",
    "ip": localIp,
    "port": availablePort,
    "password": rustDeskPassword,
  };

  debugPrint(
      '[TC][Windows] Sending TC info to ${device.ip}:${device.port}: $tcPayload');

  await TcpHelper.sendTcpRequest(
    ip: device.ip,
    port: 64546, // Send to Linux SHARED_PORT (it listens for commands here)
    requestPayload: tcPayload,
    tag: 'TC',
  );

  device.tcpStatus.value = 'Info sent';
  debugPrint('[TC][Windows] TC info sent to ${device.ip}:${device.port}');
}

Future<void> _handleGcButtonClick(Device device) async {
  debugPrint('[UI] GC button clicked for ${device.schoolName}');
  device.tcpStatus.value = 'Requesting...';

  final response = await TcpHelper.sendTcpRequest(
    ip: device.ip,
    port: 64546, // Send to Linux SHARED_PORT
    requestPayload: {"action": "GC_REQUEST"},
    tag: 'GC',
  );

  if (response != null && response['ack'] == 'GC_ACK') {
    debugPrint('[GC][Windows] ✅ Received GC_ACK from ${device.ip}');
    debugPrint('[GC][Windows] Linux device info: '
        'IP=${response['ip']}, PORT=${response['port']}, PASSWORD=${response['password']}');
    device.tcpStatus.value = 'GC Info Received';
  } else {
    debugPrint('[GC][Windows] ❌ No valid GC_ACK or no response');
    device.tcpStatus.value = 'GC Failed';
  }
}