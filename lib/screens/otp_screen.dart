import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/api_client.dart';
import '../core/auth_service.dart';
import '../core/router.dart';
import '../widgets/app_widgets.dart';

class OtpScreen extends StatefulWidget {
  final String email;
  final String method; // 'email' | 'mobile'
  final String mobile; // 10 digits, used only for masked display
  final int resendAfter;
  const OtpScreen({
    super.key,
    required this.email,
    this.method = 'email',
    this.mobile = '',
    this.resendAfter = 60,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _otpCtrl = TextEditingController();
  Timer? _timer;
  int _cooldown = 0;
  bool _busy = false;
  bool _resending = false;

  @override
  void initState() {
    super.initState();
    _cooldown = widget.resendAfter;
    _runTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpCtrl.dispose();
    super.dispose();
  }

  void _runTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_cooldown <= 1) {
        t.cancel();
        setState(() => _cooldown = 0);
      } else {
        setState(() => _cooldown--);
      }
    });
  }

  void _startCooldown(int secs) {
    setState(() => _cooldown = secs);
    _runTimer();
  }

  String get _masked {
    if (widget.method == 'mobile') {
      final d = widget.mobile.replaceAll(RegExp(r'\D'), '');
      return d.length >= 2 ? '+91 ******${d.substring(d.length - 2)}' : '+91 ********';
    }
    final parts = widget.email.split('@');
    final name = parts.first;
    final domain = parts.length > 1 ? parts[1] : '';
    if (name.length <= 2) return '$name@$domain';
    return '${name[0]}${'*' * (name.length - 2)}${name[name.length - 1]}@$domain';
  }

  Future<void> _verify() async {
    if (_busy) return;
    final otp = _otpCtrl.text.trim();
    if (otp.length != 6) {
      showStatus(context, 'Please enter the 6-digit code.', error: true);
      return;
    }
    setState(() => _busy = true);
    try {
      final session = await AuthService.verifyOtp(widget.email, otp);
      if (!mounted) return;
      goToSession(context, session);
    } on ApiException catch (e) {
      if (!mounted) return;
      showStatus(context, e.message, error: true);
      if (e.statusCode == 422) _otpCtrl.clear();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resend() async {
    if (_cooldown > 0 || _resending || _busy) return;
    setState(() => _resending = true);
    try {
      final msg = await AuthService.resendOtp(widget.email);
      if (!mounted) return;
      _otpCtrl.clear();
      showStatus(context, msg);
      _startCooldown(widget.resendAfter);
    } on ApiException catch (e) {
      if (!mounted) return;
      showStatus(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  String get _timerLabel {
    final m = (_cooldown ~/ 60).toString().padLeft(2, '0');
    final s = (_cooldown % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Center(child: BrandLogo()),
          const SizedBox(height: 20),
          const Text(
            'Verify OTP',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.method == 'mobile'
                ? "We've sent a 6-digit code to your WhatsApp\n$_masked"
                : "We've sent a 6-digit code to\n$_masked",
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: AppColors.muted, height: 1.5),
          ),
          const SizedBox(height: 22),
          TextField(
            controller: _otpCtrl,
            autofocus: true,
            enabled: !_busy,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            maxLength: 6,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w600,
              letterSpacing: 12,
              color: AppColors.text,
            ),
            decoration: inputDecoration(hint: '------').copyWith(counterText: ''),
            onChanged: (v) {
              if (v.length == 6) _verify();
            },
          ),
          const SizedBox(height: 20),
          GradientButton(
            label: 'Verify OTP',
            loading: _busy,
            onPressed: _busy ? null : _verify,
          ),
          const SizedBox(height: 16),
          Center(
            child: _cooldown > 0
                ? Text(
                    "Didn't receive the code? Resend in $_timerLabel",
                    style: const TextStyle(fontSize: 12, color: AppColors.muted),
                  )
                : TextButton(
                    onPressed: _resending ? null : _resend,
                    child: Text(_resending ? 'Sending...' : 'Resend OTP'),
                  ),
          ),
          TextButton(
            onPressed: _busy ? null : () => Navigator.of(context).pop(),
            child: const Text('Change email', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
