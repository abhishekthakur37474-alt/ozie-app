import 'package:flutter/material.dart';

import '../../core/models.dart';
import '../../core/router.dart';
import '../../widgets/app_widgets.dart';

class SettingsTab extends StatelessWidget {
  final Session session;
  const SettingsTab({super.key, required this.session});

  Future<void> _confirmLogout(BuildContext context) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Do you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
    if (yes == true && context.mounted) {
      await logoutAndGoToLogin(context);
    }
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

  @override
  Widget build(BuildContext context) {
    final user = session.user;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
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
              _row('Name', user.displayName),
              _row('Email', user.email ?? '-'),
              _row('Mobile', user.mobile ?? '-'),
              _row('Role', user.roleLabel),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: ListTile(
            leading: const Icon(Icons.logout, color: Color(0xFFDC3545)),
            title: const Text(
              'Logout',
              style: TextStyle(color: Color(0xFFDC3545), fontWeight: FontWeight.w500),
            ),
            onTap: () => _confirmLogout(context),
          ),
        ),
      ],
    );
  }
}