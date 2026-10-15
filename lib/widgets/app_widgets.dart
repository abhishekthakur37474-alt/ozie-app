import 'package:flutter/material.dart';

class AppColors {
  static const Color green = Color(0xFF1CB87A);
  static const Color blue = Color(0xFF1A6FD4);
  static const Color bg = Color(0xFFF4F6FA);
  static const Color card = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE2E6EF);
  static const Color inputBg = Color(0xFFFAFBFD);
  static const Color text = Color(0xFF1E2A3B);
  static const Color muted = Color(0xFF6B7280);
  static const Color successBg = Color(0xFFD6F5EA);
  static const Color successText = Color(0xFF0A7A50);
  static const Color dangerBg = Color(0xFFFECDD3);
  static const Color dangerText = Color(0xFF9F1239);
}

class AppAssets {
  static const String logo = 'assets/images/logos/icon-512.png';
}

/// App logo from assets. Falls back to the gradient icon if the asset is missing.
class AppLogoImage extends StatelessWidget {
  final double size;
  final double radius;
  const AppLogoImage({super.key, required this.size, this.radius = 12});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Image.asset(
        AppAssets.logo,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.green, AppColors.blue],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Icon(Icons.storefront_rounded, color: Colors.white, size: size * 0.5),
        ),
      ),
    );
  }
}

ThemeData buildTheme() {
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.blue,
      primary: AppColors.blue,
    ),
    scaffoldBackgroundColor: AppColors.bg,
  );
}

String? requiredValidator(String? v) =>
    (v == null || v.trim().isEmpty) ? 'This field is required' : null;

const List<String> _kMonths = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// Formats a number as Indian rupees, e.g. 1234567.5 -> "₹12,34,567.50".
String formatInr(dynamic value, {bool decimals = true}) {
  final v = (value is num) ? value.toDouble() : double.tryParse('$value') ?? 0;
  final neg = v < 0;
  final fixed = v.abs().toStringAsFixed(decimals ? 2 : 0);
  final parts = fixed.split('.');
  final intPart = parts[0];
  final buf = StringBuffer();
  if (intPart.length <= 3) {
    buf.write(intPart);
  } else {
    final last3 = intPart.substring(intPart.length - 3);
    var rest = intPart.substring(0, intPart.length - 3);
    final chunks = <String>[];
    while (rest.length > 2) {
      chunks.insert(0, rest.substring(rest.length - 2));
      rest = rest.substring(0, rest.length - 2);
    }
    if (rest.isNotEmpty) chunks.insert(0, rest);
    buf.write(chunks.join(','));
    buf.write(',');
    buf.write(last3);
  }
  final out = parts.length > 1 ? '${buf.toString()}.${parts[1]}' : buf.toString();
  return '${neg ? '-' : ''}₹$out';
}

/// "2026-10-15 10:15:00" or "2026-10-15" -> "15 Oct 2026". Falls back to input.
String formatDate(String? raw) {
  final s = (raw ?? '').trim();
  if (s.isEmpty) return '-';
  final datePart = s.split(' ').first;
  final d = DateTime.tryParse(datePart);
  if (d == null) return datePart;
  return '${d.day} ${_kMonths[d.month - 1]} ${d.year}';
}

void showStatus(BuildContext context, String message, {bool error = false}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: error ? AppColors.dangerBg : AppColors.successBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      content: Text(
        message,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: error ? AppColors.dangerText : AppColors.successText,
          fontWeight: FontWeight.w500,
          fontSize: 13,
        ),
      ),
    ),
  );
}

InputDecoration inputDecoration({String? hint, Widget? suffix}) {
  OutlineInputBorder border(Color c, double w) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: c, width: w),
      );
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(fontSize: 13, color: AppColors.muted),
    filled: true,
    fillColor: AppColors.inputBg,
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    suffixIcon: suffix,
    border: border(AppColors.border, 1),
    enabledBorder: border(AppColors.border, 1),
    focusedBorder: border(AppColors.blue, 2),
  );
}

class AuthScaffold extends StatelessWidget {
  final Widget child;
  const AuthScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const AppLogoImage(size: 72, radius: 18),
        const SizedBox(height: 8),
        const Text(
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
}

class GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  const GradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null && !loading;
    return Opacity(
      opacity: disabled ? 0.5 : 1,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: loading ? null : onPressed,
          child: Ink(
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              gradient: const LinearGradient(
                colors: [AppColors.green, AppColors.blue],
              ),
            ),
            child: Center(
              child: loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class LabeledField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? hint;
  final bool obscure;
  final TextInputType? keyboardType;
  final Widget? suffix;
  final String? Function(String?)? validator;
  final TextInputAction? textInputAction;
  final void Function(String)? onSubmitted;
  final FocusNode? focusNode;
  final void Function(String)? onChanged;

  const LabeledField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.obscure = false,
    this.keyboardType,
    this.suffix,
    this.validator,
    this.textInputAction,
    this.onSubmitted,
    this.focusNode,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.text)),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          obscureText: obscure,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          onFieldSubmitted: onSubmitted,
          onChanged: onChanged,
          validator: validator,
          style: const TextStyle(fontSize: 14, color: AppColors.text),
          decoration: inputDecoration(hint: hint, suffix: suffix),
        ),
      ],
    );
  }
}

class LabeledDropdown extends StatelessWidget {
  final String label;
  final String hint;
  final List<String> items;
  final String? value;
  final void Function(String?) onChanged;
  final String? Function(String?)? validator;

  const LabeledDropdown({
    super.key,
    required this.label,
    required this.hint,
    required this.items,
    this.value,
    required this.onChanged,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.text)),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          initialValue: value,
          isExpanded: true,
          hint: Text(hint, style: const TextStyle(fontSize: 13, color: AppColors.muted)),
          items: items
              .map((s) => DropdownMenuItem<String>(
                    value: s,
                    child: Text(s, style: const TextStyle(fontSize: 14)),
                  ))
              .toList(),
          onChanged: onChanged,
          validator: validator,
          decoration: inputDecoration(),
        ),
      ],
    );
  }
}