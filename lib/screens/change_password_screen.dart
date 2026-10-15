import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../core/auth_service.dart';
import '../widgets/app_widgets.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _loading = false;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  String? _newValidator(String? v) {
    final t = (v ?? '').trim();
    if (t.isEmpty) return 'This field is required';
    if (t.length < 6) return 'Password must be at least 6 characters';
    if (t.length > 64) return 'Password must be at most 64 characters';
    return null;
  }

  String? _confirmValidator(String? v) {
    if ((v ?? '').trim().isEmpty) return 'This field is required';
    if (v!.trim() != _newCtrl.text.trim()) return 'Passwords do not match';
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_currentCtrl.text.trim() == _newCtrl.text.trim()) {
      showStatus(context, 'New password must be different from the current password.', error: true);
      return;
    }
    setState(() => _loading = true);
    try {
      await AuthService.changePassword(
        currentPassword: _currentCtrl.text.trim(),
        newPassword: _newCtrl.text.trim(),
      );
      if (!mounted) return;
      showStatus(context, 'Password updated successfully.');
      Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      showStatus(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _eye(bool obscure, VoidCallback onTap) => IconButton(
        icon: Icon(
          obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
          size: 18,
          color: AppColors.blue,
        ),
        onPressed: onTap,
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Change Password'),
        backgroundColor: AppColors.bg,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Enter your current password and choose a new one. If you signed up with Google and have no password, leave the current password blank.',
                    style: TextStyle(fontSize: 12, color: AppColors.muted, height: 1.5),
                  ),
                  const SizedBox(height: 20),
                  LabeledField(
                    label: 'Current Password',
                    controller: _currentCtrl,
                    hint: 'Enter current password',
                    obscure: _obscureCurrent,
                    textInputAction: TextInputAction.next,
                    suffix: _eye(_obscureCurrent, () => setState(() => _obscureCurrent = !_obscureCurrent)),
                  ),
                  const SizedBox(height: 14),
                  LabeledField(
                    label: 'New Password',
                    controller: _newCtrl,
                    hint: 'Minimum 6 characters',
                    obscure: _obscureNew,
                    textInputAction: TextInputAction.next,
                    validator: _newValidator,
                    suffix: _eye(_obscureNew, () => setState(() => _obscureNew = !_obscureNew)),
                  ),
                  const SizedBox(height: 14),
                  LabeledField(
                    label: 'Confirm New Password',
                    controller: _confirmCtrl,
                    hint: 'Re-enter new password',
                    obscure: _obscureConfirm,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _loading ? null : _submit(),
                    validator: _confirmValidator,
                    suffix: _eye(_obscureConfirm, () => setState(() => _obscureConfirm = !_obscureConfirm)),
                  ),
                  const SizedBox(height: 24),
                  GradientButton(
                    label: 'Update password',
                    loading: _loading,
                    onPressed: _loading ? null : _submit,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
