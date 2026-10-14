import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../core/auth_service.dart';
import '../widgets/app_widgets.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _idCtrl = TextEditingController();
  bool _loading = false;
  String? _sentMessage;

  @override
  void dispose() {
    _idCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final msg = await AuthService.forgotPassword(_idCtrl.text.trim());
      if (!mounted) return;
      setState(() => _sentMessage = msg);
    } on ApiException catch (e) {
      if (!mounted) return;
      showStatus(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      child: _sentMessage != null ? _sentView() : _formView(),
    );
  }

  Widget _sentView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.mark_email_read_outlined, size: 56, color: AppColors.green),
        const SizedBox(height: 16),
        const Text(
          'Check your inbox',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.text),
        ),
        const SizedBox(height: 12),
        Text(
          _sentMessage!,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14, color: AppColors.muted, height: 1.5),
        ),
        const SizedBox(height: 8),
        const Text(
          'Open the link, set a new password, then log in here.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: AppColors.muted),
        ),
        const SizedBox(height: 24),
        GradientButton(
          label: 'Back to login',
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  Widget _formView() {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Center(child: BrandLogo()),
          const SizedBox(height: 20),
          const Text(
            'Forgot password?',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500, color: AppColors.text),
          ),
          const SizedBox(height: 8),
          const Text(
            'Enter your email or mobile number. We will send you a secure reset link.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppColors.muted, height: 1.4),
          ),
          const SizedBox(height: 24),
          LabeledField(
            label: 'Email or Mobile Number',
            controller: _idCtrl,
            hint: 'Enter your email or mobile number',
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _loading ? null : _submit(),
            validator: requiredValidator,
          ),
          const SizedBox(height: 20),
          GradientButton(
            label: 'Send reset link',
            loading: _loading,
            onPressed: _loading ? null : _submit,
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Back to login'),
          ),
        ],
      ),
    );
  }
}
