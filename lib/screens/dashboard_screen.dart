import 'package:flutter/material.dart';

import '../core/models.dart';
import '../core/router.dart';
import '../widgets/app_widgets.dart';

/// Placeholder. Role-wise dashboards (retailer, distributor, ...) come next.
class DashboardScreen extends StatelessWidget {
  final Session session;
  const DashboardScreen({super.key, required this.session});

  Future<void> _confirmLogout(BuildContext context) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Do you want to logout?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Logout')),
        ],
      ),
    );
    if (yes == true && context.mounted) {
      await logoutAndGoToLogin(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = session.user;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ozie'),
        backgroundColor: AppColors.card,
        actions: [
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout),
            onPressed: () => _confirmLogout(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: const LinearGradient(
                colors: [AppColors.green, AppColors.blue],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello, ${user.displayName}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    user.roleLabel,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _row('User ID', '${user.id}'),
                _row('Email', user.email ?? '-'),
                _row('Mobile', user.mobile ?? '-'),
                _row('Role', user.roleLabel),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Dashboard for your role will be added in the next update.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppColors.muted),
          ),
        ],
      ),
    );
  }

  Widget _row(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 80,
              child: Text(k, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
            ),
            Expanded(
              child: Text(v, style: const TextStyle(fontSize: 14, color: AppColors.text)),
            ),
          ],
        ),
      );
}
