import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../core/auth_service.dart';
import '../widgets/app_widgets.dart';
import 'otp_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  final _pwCtrl = TextEditingController();
  final _cpwCtrl = TextEditingController();

  bool _obscure = true;
  bool _obscure2 = true;
  bool _agree = true;
  bool _loading = false;
  String _method = 'email'; // 'email' | 'mobile' (WhatsApp)

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _mobileCtrl.dispose();
    _pwCtrl.dispose();
    _cpwCtrl.dispose();
    super.dispose();
  }

  String? _nameValidator(String? v) {
    if (v == null || v.trim().length < 2) return 'Please enter your full name';
    return null;
  }

  String? _emailValidator(String? v) {
    final t = (v ?? '').trim();
    if (t.isEmpty) return 'This field is required';
    final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(t);
    return ok ? null : 'Enter a valid email address';
  }

  String? _mobileValidator(String? v) {
    final d = (v ?? '').replaceAll(RegExp(r'\D'), '');
    if (d.isEmpty) return 'This field is required';
    return d.length == 10 ? null : 'Enter a 10 digit mobile number';
  }

  String? _pwValidator(String? v) {
    final t = (v ?? '').trim();
    if (t.isEmpty) return 'This field is required';
    if (t.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  String? _cpwValidator(String? v) {
    if ((v ?? '').trim().isEmpty) return 'This field is required';
    if (v!.trim() != _pwCtrl.text.trim()) return 'Passwords do not match';
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agree) {
      showStatus(
        context,
        'Please accept the Terms & Conditions and Privacy Policy.',
        error: true,
      );
      return;
    }

    final email = _emailCtrl.text.trim().toLowerCase();
    final mobile = _mobileCtrl.text.replaceAll(RegExp(r'\D'), '');
    setState(() => _loading = true);
    try {
      final msg = await AuthService.register(
        name: _nameCtrl.text.trim(),
        email: email,
        mobile: mobile,
        password: _pwCtrl.text.trim(),
        verifyMethod: _method,
      );
      if (!mounted) return;
      showStatus(context, msg);
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => OtpScreen(email: email, method: _method, mobile: mobile),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      showStatus(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _methodTile(String value, IconData icon, String label) {
    final selected = _method == value;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: _loading ? null : () => setState(() => _method = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? AppColors.successBg : AppColors.inputBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? AppColors.green : AppColors.border,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: selected ? AppColors.successText : AppColors.muted,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: selected ? AppColors.successText : AppColors.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
    return AuthScaffold(
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Center(child: BrandLogo()),
            const SizedBox(height: 20),
            const Text(
              'Create your account',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w500,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _method == 'mobile'
                  ? 'We will send a 6-digit code to your WhatsApp number.'
                  : 'We will send a 6-digit code to your email.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppColors.muted),
            ),
            const SizedBox(height: 22),
            LabeledField(
              label: 'Full Name',
              controller: _nameCtrl,
              hint: 'Enter your full name',
              keyboardType: TextInputType.name,
              textInputAction: TextInputAction.next,
              validator: _nameValidator,
            ),
            const SizedBox(height: 14),
            LabeledField(
              label: 'Email',
              controller: _emailCtrl,
              hint: 'Enter your email',
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: _emailValidator,
            ),
            const SizedBox(height: 14),
            LabeledField(
              label: 'Mobile Number',
              controller: _mobileCtrl,
              hint: '10 digit mobile number',
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              validator: _mobileValidator,
            ),
            const SizedBox(height: 14),
            LabeledField(
              label: 'Password',
              controller: _pwCtrl,
              hint: 'Minimum 6 characters',
              obscure: _obscure,
              textInputAction: TextInputAction.next,
              validator: _pwValidator,
              suffix: _eye(_obscure, () => setState(() => _obscure = !_obscure)),
            ),
            const SizedBox(height: 14),
            LabeledField(
              label: 'Confirm Password',
              controller: _cpwCtrl,
              hint: 'Re-enter your password',
              obscure: _obscure2,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _loading ? null : _submit(),
              validator: _cpwValidator,
              suffix: _eye(_obscure2, () => setState(() => _obscure2 = !_obscure2)),
            ),
            const SizedBox(height: 16),
            const Text(
              'Verify my account using',
              style: TextStyle(fontSize: 12, color: AppColors.text),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                _methodTile('email', Icons.email_outlined, 'Email'),
                const SizedBox(width: 10),
                _methodTile('mobile', Icons.chat_outlined, 'WhatsApp'),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.bg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 28,
                    height: 28,
                    child: Checkbox(
                      value: _agree,
                      onChanged: (v) => setState(() => _agree = v ?? false),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: Text(
                        'I have read and agree to the Ozie Terms & Conditions and Privacy Policy.',
                        style: TextStyle(fontSize: 11, color: AppColors.muted, height: 1.4),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            GradientButton(
              label: 'Send OTP',
              loading: _loading,
              onPressed: _loading ? null : _submit,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Already have an account? ',
                  style: TextStyle(fontSize: 13, color: AppColors.muted),
                ),
                GestureDetector(
                  onTap: _loading ? null : () => Navigator.of(context).pop(),
                  child: const Text(
                    'Sign in',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.blue,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
