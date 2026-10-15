import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../widgets/app_widgets.dart';

/// Placeholder. Notification list comes when the API is ready.
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: AppColors.card,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          tooltip: 'Back',
          icon: const HugeIcon(
            icon: HugeIcons.strokeRoundedChevronLeft,
            color: AppColors.text,
            strokeWidth: 1.5,
          ),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.notifications_none_rounded, size: 56, color: AppColors.muted),
              SizedBox(height: 12),
              Text(
                'No notifications yet',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.text,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}