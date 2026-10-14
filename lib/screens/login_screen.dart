import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../core/auth_service.dart';
import '../core/router.dart';
import '../widgets/app_widgets.dart';
import 'forgot_password_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _idCtrl = TextEditingController();
  final _pwCtrl = TextEditingController();

  bool _obscure = true;
  bool _agree = true;
  bool _loading = false;
  bool _googleLoading = false;

  @override
  void dispose() {
    _idCtrl.dispose();
    _pwCtrl.dispose();
    super.dispose();
  }

  bool _tncOk() {
    if (!_agree) {
      showStatus(
        context,
        'Please accept the Terms & Conditions and Privacy Policy.',
        error: true,
      );
      return false;
    }
    return true;
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate() || !_tncOk()) return;
    setState(() => _loading = true);
    try {
      final session = await AuthService.login(
        _idCtrl.text.trim(),
        _pwCtrl.text.trim(),
      );
      if (!mounted) return;
      goToSession(context, session);
    } on ApiException catch (e) {
      if (!mounted) return;
      showStatus(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _google() async {
    if (!_tncOk()) return;
    setState(() => _googleLoading = true);
    try {
      final session = await AuthService.loginWithGoogle();
      if (!mounted) return;
      goToSession(context, session);
    } on ApiException catch (e) {
      if (!mounted) return;
      showStatus(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _googleLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final busy = _loading || _googleLoading;
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
              'Welcome back',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.w500,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 24),
            LabeledField(
              label: 'Email or Mobile Number',
              controller: _idCtrl,
              hint: 'Enter your email or mobile number',
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: requiredValidator,
            ),
            const SizedBox(height: 16),
            LabeledField(
              label: 'Password',
              controller: _pwCtrl,
              hint: 'Enter your password',
              obscure: _obscure,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => busy ? null : _login(),
              validator: requiredValidator,
              suffix: IconButton(
                icon: Icon(
                  _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  size: 18,
                  color: AppColors.blue,
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: busy
                    ? null
                    : () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const ForgotPasswordScreen(),
                          ),
                        ),
                child: const Text('Forgot password?', style: TextStyle(fontSize: 12)),
              ),
            ),
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
              label: 'Sign in',
              loading: _loading,
              onPressed: busy ? null : _login,
            ),
            const SizedBox(height: 20),
            const Row(
              children: [
                Expanded(child: Divider(color: AppColors.border)),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text('OR', style: TextStyle(fontSize: 11, color: AppColors.muted)),
                ),
                Expanded(child: Divider(color: AppColors.border)),
              ],
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: busy ? null : _google,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(44),
                foregroundColor: AppColors.text,
                side: const BorderSide(color: AppColors.border),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: _googleLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.g_mobiledata_rounded, size: 28),
              label: Text(_googleLoading ? 'Processing...' : 'Sign in with Google'),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Don't have an account? ",
                  style: TextStyle(fontSize: 13, color: AppColors.muted),
                ),
                GestureDetector(
                  onTap: busy
                      ? null
                      : () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const RegisterScreen(),
                            ),
                          ),
                  child: const Text(
                    'Sign up',
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
