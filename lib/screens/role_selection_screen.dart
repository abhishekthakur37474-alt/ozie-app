import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../core/auth_service.dart';
import '../core/models.dart';
import '../core/router.dart';
import '../widgets/app_widgets.dart';

const List<String> kIndianStates = [
  'Andhra Pradesh', 'Arunachal Pradesh', 'Assam', 'Bihar', 'Chhattisgarh',
  'Goa', 'Gujarat', 'Haryana', 'Himachal Pradesh', 'Jharkhand', 'Karnataka',
  'Kerala', 'Madhya Pradesh', 'Maharashtra', 'Manipur', 'Meghalaya',
  'Mizoram', 'Nagaland', 'Odisha', 'Punjab', 'Rajasthan', 'Sikkim',
  'Tamil Nadu', 'Telangana', 'Tripura', 'Uttar Pradesh', 'Uttarakhand',
  'West Bengal',
  'Andaman and Nicobar Islands', 'Chandigarh',
  'Dadra and Nagar Haveli and Daman and Diu', 'Delhi', 'Jammu and Kashmir',
  'Ladakh', 'Lakshadweep', 'Puducherry',
];

const List<String> kUserTypes = ['Manufacturer', 'Distributor', 'Retailer'];

enum _View { role, code, inquiry, submitted }

class RoleSelectionScreen extends StatefulWidget {
  final Session session;
  const RoleSelectionScreen({super.key, required this.session});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  late _View _view;
  bool _busy = false;

  final _codeKey = GlobalKey<FormState>();
  final _codeCtrl = TextEditingController();

  final _inqKey = GlobalKey<FormState>();
  final _company = TextEditingController();
  final _name = TextEditingController();
  final _contact = TextEditingController();
  final _industry = TextEditingController();
  String? _state;
  String? _type;

  @override
  void initState() {
    super.initState();
    _view = widget.session.inquirySubmitted ? _View.submitted : _View.role;
    _name.text = widget.session.user.name ?? '';
    _contact.text = widget.session.user.mobile ?? '';
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _company.dispose();
    _name.dispose();
    _contact.dispose();
    _industry.dispose();
    super.dispose();
  }

  Future<void> _verifyCode() async {
    if (!_codeKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await AuthService.verifyCode(_codeCtrl.text.trim());
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Code verified'),
          content: const Text(
            'Your introduction code is valid.\n\nThe retailer registration form will be available in the next app update.',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('OK')),
          ],
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      showStatus(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _submitInquiry() async {
    if (!_inqKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await AuthService.submitInquiry(
        companyName: _company.text.trim(),
        name: _name.text.trim(),
        contactNumber: _contact.text.trim(),
        industry: _industry.text.trim(),
        location: _state ?? '',
        userType: _type ?? '',
      );
      if (!mounted) return;
      setState(() => _view = _View.submitted);
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.statusCode == 409) {
        setState(() => _view = _View.submitted);
      } else {
        showStatus(context, e.message, error: true);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _checkStatus() async {
    setState(() => _busy = true);
    try {
      final s = await AuthService.me();
      if (!mounted) return;
      if (s.nextScreen == 'role_selection') {
        showStatus(context, 'Your application is still under review.');
      } else {
        goToSession(context, s);
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      showStatus(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    switch (_view) {
      case _View.role:
        body = _roleView();
        break;
      case _View.code:
        body = _codeView();
        break;
      case _View.inquiry:
        body = _inquiryView();
        break;
      case _View.submitted:
        body = _submittedView();
        break;
    }

    return PopScope(
      canPop: _view == _View.role || _view == _View.submitted,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) setState(() => _view = _View.role);
      },
      child: AuthScaffold(child: body),
    );
  }

  Widget _title(String t) => Text(
        t,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: AppColors.text),
      );

  Widget _logoutLink() => TextButton.icon(
        onPressed: () => logoutAndGoToLogin(context),
        icon: const Icon(Icons.logout, size: 16, color: Color(0xFFDC3545)),
        label: const Text('Logout', style: TextStyle(color: Color(0xFFDC3545), fontSize: 13)),
      );

  Widget _backLink(_View to) => TextButton.icon(
        onPressed: _busy ? null : () => setState(() => _view = to),
        icon: const Icon(Icons.arrow_back, size: 16),
        label: const Text('Back', style: TextStyle(fontSize: 13)),
      );

  Widget _roleView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Center(child: BrandLogo()),
        const SizedBox(height: 20),
        _title('Welcome'),
        const SizedBox(height: 8),
        const Text(
          'Before we proceed, please tell us about your role.\nAre you a retailer?',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: AppColors.muted, height: 1.5),
        ),
        const SizedBox(height: 24),
        GradientButton(
          label: 'Yes, I am a Retailer',
          onPressed: () => setState(() => _view = _View.code),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: () => setState(() => _view = _View.inquiry),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(44),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: const Text('No, I am not'),
        ),
        const SizedBox(height: 8),
        _logoutLink(),
      ],
    );
  }

  Widget _codeView() {
    return Form(
      key: _codeKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _title('Introduction Code'),
          const SizedBox(height: 8),
          const Text(
            'Enter the code given by your manufacturer or distributor.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppColors.muted, height: 1.4),
          ),
          const SizedBox(height: 20),
          LabeledField(
            label: 'Introduction Code',
            controller: _codeCtrl,
            hint: 'Enter code',
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _busy ? null : _verifyCode(),
            validator: requiredValidator,
          ),
          const SizedBox(height: 20),
          GradientButton(
            label: 'Verify Code',
            loading: _busy,
            onPressed: _busy ? null : _verifyCode,
          ),
          const SizedBox(height: 8),
          _backLink(_View.role),
        ],
      ),
    );
  }

  Widget _inquiryView() {
    return Form(
      key: _inqKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _title('Join Our Network'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.bg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: const Text(
              'This is a closed user group program. Please share a few details so our experts can reach out to you.',
              style: TextStyle(fontSize: 12, color: AppColors.muted, height: 1.4),
            ),
          ),
          const SizedBox(height: 16),
          LabeledField(
            label: 'Company Name',
            controller: _company,
            textInputAction: TextInputAction.next,
            validator: requiredValidator,
          ),
          const SizedBox(height: 14),
          LabeledField(
            label: 'Your Name',
            controller: _name,
            textInputAction: TextInputAction.next,
            validator: requiredValidator,
          ),
          const SizedBox(height: 14),
          LabeledField(
            label: 'Contact Number',
            controller: _contact,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            validator: requiredValidator,
          ),
          const SizedBox(height: 14),
          LabeledField(
            label: 'Which Industry?',
            controller: _industry,
            hint: 'e.g. FMCG, Electronics, etc.',
            textInputAction: TextInputAction.done,
            validator: requiredValidator,
          ),
          const SizedBox(height: 14),
          LabeledDropdown(
            label: 'State',
            hint: 'Select State...',
            items: kIndianStates,
            onChanged: (v) => _state = v,
            validator: (v) => v == null ? 'Please select a state' : null,
          ),
          const SizedBox(height: 14),
          LabeledDropdown(
            label: 'User Type',
            hint: 'Select Option...',
            items: kUserTypes,
            onChanged: (v) => _type = v,
            validator: (v) => v == null ? 'Please select a user type' : null,
          ),
          const SizedBox(height: 20),
          GradientButton(
            label: 'Submit Details',
            loading: _busy,
            onPressed: _busy ? null : _submitInquiry,
          ),
          const SizedBox(height: 8),
          _backLink(_View.role),
        ],
      ),
    );
  }

  Widget _submittedView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.check_circle, size: 60, color: Color(0xFF198754)),
        const SizedBox(height: 16),
        _title('Application Under Review'),
        const SizedBox(height: 12),
        const Text(
          'You have submitted your details. Our experts are reviewing your application and will reach out to you soon.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: AppColors.muted, height: 1.6),
        ),
        const SizedBox(height: 24),
        GradientButton(
          label: 'Check status',
          loading: _busy,
          onPressed: _busy ? null : _checkStatus,
        ),
        const SizedBox(height: 8),
        _logoutLink(),
      ],
    );
  }
}
