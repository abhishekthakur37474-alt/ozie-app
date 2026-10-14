import 'package:flutter/material.dart';

import '../core/models.dart';
import '../widgets/app_widgets.dart';
import 'notifications_screen.dart';
import 'tabs/catalog_tab.dart';
import 'tabs/home_tab.dart';
import 'tabs/orders_tab.dart';
import 'tabs/settings_tab.dart';

/// App shell after login: top bar (logo + notifications) and bottom menu.
class MainShell extends StatefulWidget {
  final Session session;
  const MainShell({super.key, required this.session});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  static const List<String> _titles = ['Home', 'Catalog', 'View Orders', 'Settings'];

  /// Home shows logo + app name. Other tabs show the tab name.
  Widget _buildTitle() {
    if (_index == 0) {
      return const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppLogoImage(size: 32, radius: 8),
          SizedBox(width: 10),
          Text(
            'Ozie',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.text,
            ),
          ),
        ],
      );
    }
    return Text(
      _titles[_index],
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.text,
      ),
    );
  }

  void _openNotifications() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const NotificationsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      HomeTab(session: widget.session),
      const CatalogTab(),
      const OrdersTab(),
      SettingsTab(session: widget.session),
    ];

    return PopScope(
      canPop: _index == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) setState(() => _index = 0);
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.card,
          surfaceTintColor: Colors.transparent,
          scrolledUnderElevation: 0,
          elevation: 0,
          titleSpacing: 16,
          title: _buildTitle(),
          actions: [
            IconButton(
              tooltip: 'Notifications',
              icon: const Icon(
                Icons.notifications_none_rounded,
                color: AppColors.text,
              ),
              onPressed: _openNotifications,
            ),
            const SizedBox(width: 4),
          ],
          bottom: const PreferredSize(
            preferredSize: Size.fromHeight(1),
            child: Divider(height: 1, color: AppColors.border),
          ),
        ),
        body: IndexedStack(index: _index, children: pages),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          backgroundColor: AppColors.card,
          surfaceTintColor: Colors.transparent,
          indicatorColor: const Color(0xFFDCE9FA),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded, color: AppColors.blue),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.grid_view_outlined),
              selectedIcon: Icon(Icons.grid_view_rounded, color: AppColors.blue),
              label: 'Catalog',
            ),
            NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              selectedIcon: Icon(Icons.receipt_long, color: AppColors.blue),
              label: 'View Orders',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings, color: AppColors.blue),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
} 