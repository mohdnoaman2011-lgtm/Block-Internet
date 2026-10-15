import 'package:flutter/material.dart';
import 'package:block_internet/models/app_item.dart';
import 'package:block_internet/screens/apps_page.dart';
import 'package:block_internet/screens/schedule_page.dart';
import 'package:block_internet/screens/settings_page.dart';
import 'package:block_internet/services/block_service.dart';
import 'package:block_internet/theme.dart';

class HomeShell extends StatefulWidget {
  HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int tab = 0;
  bool masterOn = true;
  final apps = <AppItem>[
    AppItem('Browser Lite', [Color(0xFF7E7FB8), Color(0xFF7FB0BD)]),
    AppItem('Tunnel VPN', [Color(0xFF7A6A9A), Color(0xFFA98BB8)]),
    AppItem('Secure Link', [Color(0xFF2F3D5E), Color(0xFF2F3D5E)]),
    AppItem('PDF Reader', [Color(0xFFA55A52), Color(0xFFA55A52)], blocked: true),
    AppItem('Muslim Pattern', [Color(0xFF8E6F99), Color(0xFFC98FA3)], blocked: true),
    AppItem('Anime Rift Game', [Color(0xFF2B2B2E), Color(0xFF2B2B2E)]),
    AppItem('Watch Anime', [Color(0xFF1A1A1A), Color(0xFF1A1A1A)], blocked: true),
    AppItem('Remote Desk', [Color(0xFFC26B60), Color(0xFFC26B60)], blocked: true),
    AppItem('Phone Settings', [Color(0xFF3A4547), Color(0xFF3A4547)], system: true),
  ];

  void refresh() => setState(() {});

  @override
  void initState() {
    super.initState();
    themeNotifier.addListener(refresh);
  }

  @override
  void dispose() {
    themeNotifier.removeListener(refresh);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      AppsPage(
        title: 'Block Internet Access',
        apps: apps,
        onlyBlocked: false,
        masterOn: masterOn,
        onMaster: (v) {
          masterOn = v;
          BlockService.setMaster(v);
          refresh();
        },
        onChanged: refresh,
      ),
      AppsPage(
        title: 'Blocked Apps',
        apps: apps,
        onlyBlocked: true,
        masterOn: masterOn,
        onMaster: (v) {
          masterOn = v;
          BlockService.setMaster(v);
          refresh();
        },
        onChanged: refresh,
      ),
      SchedulePage(),
      SettingsPage(),
    ];

    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0.9, -1.1),
                  radius: 1.0,
                  colors: [AppColors.accent.withAlpha(36), Colors.transparent],
                ),
              ),
            ),
          ),
          IndexedStack(index: tab, children: pages),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          margin: EdgeInsets.fromLTRB(14, 0, 14, 12),
          decoration: BoxDecoration(
            color: AppColors.navBg,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: AppColors.navBorder),
          ),
          clipBehavior: Clip.antiAlias,
          child: NavigationBar(
            height: 70,
            backgroundColor: Colors.transparent,
            indicatorColor: Color(0xFF2F4A47),
            selectedIndex: tab,
            onDestinationSelected: (i) => setState(() => tab = i),
            destinations: [
              NavigationDestination(icon: Icon(Icons.list_rounded), label: 'Apps'),
              NavigationDestination(icon: Icon(Icons.block), label: 'Blocked'),
              NavigationDestination(icon: Icon(Icons.timer_outlined), label: 'Schedule'),
              NavigationDestination(icon: Icon(Icons.settings_outlined), label: 'Settings'),
            ],
          ),
        ),
      ),
    );
  }
}
