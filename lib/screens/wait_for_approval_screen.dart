import 'dart:async';

import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../core/auth_service.dart';
import '../core/models.dart';
import '../core/router.dart';
import '../widgets/app_widgets.dart';

class WaitForApprovalScreen extends StatefulWidget {
  final Session session;
  const WaitForApprovalScreen({super.key, required this.session});

  @override
  State<WaitForApprovalScreen> createState() => _WaitForApprovalScreenState();
}

class _WaitForApprovalScreenState extends State<WaitForApprovalScreen> {
  Timer? _timer;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _check());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _check() async {
    if (_checking) return;
    _checking = true;
    try {
      final s = await AuthService.me();
      if (!mounted) return;
      if (s.nextScreen != 'wait_for_approval') {
        _timer?.cancel();
        goToSession(context, s);
      }
    } on ApiException {
      // keep polling; 401 is handled globally
    } finally {
      _checking = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Center(child: BrandLogo()),
          const SizedBox(height: 24),
          const Icon(Icons.check_circle, size: 56, color: Color(0xFF198754)),
          const SizedBox(height: 12),
          const Text(
            'Submitted Successfully!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF198754),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Hello ${widget.session.user.displayName},\nYour form has been submitted and is under review.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: AppColors.muted, height: 1.6),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E1),
              borderRadius: BorderRadius.circular(10),
              border: const Border(left: BorderSide(color: Color(0xFFFF9800), width: 4)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.hourglass_top, size: 18, color: Color(0xFFFF9800)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Once your form is approved, you will be able to access your dashboard.',
                    style: TextStyle(fontSize: 13, color: Color(0xFF424242), height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'This screen refreshes automatically.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: AppColors.muted),
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: () => logoutAndGoToLogin(context),
            icon: const Icon(Icons.logout, size: 16, color: Color(0xFFDC3545)),
            label: const Text(
              'Logout from Account',
              style: TextStyle(color: Color(0xFFDC3545), fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
