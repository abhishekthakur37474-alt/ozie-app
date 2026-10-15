import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../core/models.dart';
import '../core/profile_service.dart';
import '../core/router.dart';
import '../widgets/app_widgets.dart';
import 'change_password_screen.dart';

/// My Account: shows GET v1/profile/get and edits via v1/profile/update.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  ProfileData? _profile;
  String? _error;
  bool _loading = true;
  bool _editing = false;
  bool _saving = false;

  final _nameCtrl = TextEditingController();
  final _shopCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();
  final _pincodeCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _shopCtrl.dispose();
    _addressCtrl.dispose();
    _cityCtrl.dispose();
    _stateCtrl.dispose();
    _pincodeCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final p = await ProfileService.get();
      if (!mounted) return;
      setState(() {
        _profile = p;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  void _startEdit() {
    final p = _profile;
    if (p == null) return;
    _nameCtrl.text = p.name ?? '';
    _shopCtrl.text = p.retailer?.shopName ?? '';
    _addressCtrl.text = p.retailer?.address ?? '';
    _cityCtrl.text = p.retailer?.city ?? '';
    _stateCtrl.text = p.retailer?.state ?? '';
    _pincodeCtrl.text = p.retailer?.pincode ?? '';
    setState(() => _editing = true);
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.length < 2) {
      showStatus(context, 'Please enter your full name (2-100 characters).', error: true);
      return;
    }
    final hasRetailer = _profile?.retailer != null;
    final pincode = _pincodeCtrl.text.trim();
    if (hasRetailer && pincode.isNotEmpty && !RegExp(r'^[0-9]{6}$').hasMatch(pincode)) {
      showStatus(context, 'Pincode must be 6 digits.', error: true);
      return;
    }

    setState(() => _saving = true);
    try {
      final p = await ProfileService.update(
        name: name,
        shopName: hasRetailer ? _shopCtrl.text.trim() : null,
        address: hasRetailer ? _addressCtrl.text.trim() : null,
        city: hasRetailer ? _cityCtrl.text.trim() : null,
        state: hasRetailer ? _stateCtrl.text.trim() : null,
        pincode: hasRetailer ? pincode : null,
      );
      if (!mounted) return;
      setState(() {
        _profile = p;
        _editing = false;
      });
      showStatus(context, 'Profile updated successfully.');
    } on ApiException catch (e) {
      if (!mounted) return;
      showStatus(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _roleLabel(String? t) {
    if (t == null || t.isEmpty) return 'No role yet';
    return t
        .split('_')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  String _money(double v) => '₹${v.toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Account'),
        backgroundColor: AppColors.bg,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        actions: [
          if (_profile != null && !_editing)
            IconButton(
              tooltip: 'Edit',
              icon: const Icon(Icons.edit_outlined),
              onPressed: _startEdit,
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.dangerText)),
              const SizedBox(height: 16),
              FilledButton(onPressed: _load, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }
    final p = _profile!;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _header(p),
        const SizedBox(height: 20),
        if (_editing) ...[
          _editForm(p),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _saving ? null : () => setState(() => _editing = false),
                  style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(44)),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GradientButton(
                  label: 'Save',
                  loading: _saving,
                  onPressed: _saving ? null : _save,
                ),
              ),
            ],
          ),
        ] else ...[
          _card('Account', [
            _row('Name', p.name ?? '-'),
            _row('Email', p.email ?? '-'),
            _row('Mobile', p.mobile ?? '-'),
            _row('Role', _roleLabel(p.userType)),
            if (p.memberSince != null) _row('Member since', p.memberSince!),
          ]),
          if (p.retailer != null) ...[
            const SizedBox(height: 16),
            _card('Shop', [
              _row('Shop name', p.retailer!.shopName ?? '-'),
              _row('Retailer code', p.retailer!.retailerCode ?? '-'),
              _row('Address', p.retailer!.address ?? '-'),
              _row('City', p.retailer!.city ?? '-'),
              _row('State', p.retailer!.state ?? '-'),
              _row('Pincode', p.retailer!.pincode ?? '-'),
              _row('GST', p.retailer!.gst ?? '-'),
              _row('PAN', p.retailer!.pan ?? '-'),
              _row('Status', p.retailer!.status ?? '-'),
            ]),
            const SizedBox(height: 16),
            _card('Credit', [
              _row('Credit limit', _money(p.retailer!.creditLimit)),
              _row('Current balance', _money(p.retailer!.currentBalance)),
              _row('Available credit', _money(p.retailer!.availableCredit)),
              _row('Credit days', '${p.retailer!.creditDays}'),
            ]),
          ],
          if (p.license != null) ...[
            const SizedBox(height: 16),
            _card('License', [
              _row('Holder name', p.license!.holderName ?? '-'),
              _row('Holder contact', p.license!.holderContact ?? '-'),
              _row('Holder address', p.license!.holderAddress ?? '-'),
              _row('Operator name', p.license!.operatorName ?? '-'),
              _row('Operator contact', p.license!.operatorContact ?? '-'),
            ]),
          ],
        ],
        const SizedBox(height: 20),
        Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.lock_outline_rounded, color: AppColors.blue),
                title: const Text('Change Password'),
                trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const ChangePasswordScreen()),
                ),
              ),
              const Divider(height: 1, indent: 56, color: AppColors.border),
              ListTile(
                leading: const Icon(Icons.logout, color: Color(0xFFDC3545)),
                title: const Text('Logout', style: TextStyle(color: Color(0xFFDC3545))),
                onTap: () => logoutAndGoToLogin(context),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _header(ProfileData p) {
    return Column(
      children: [
        const SizedBox(height: 8),
        CircleAvatar(
          radius: 44,
          backgroundColor: const Color(0xFFDCE9FA),
          child: Text(
            _initials(p.displayName),
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w600, color: AppColors.blue),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          p.displayName,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.text),
        ),
        const SizedBox(height: 4),
        Text(_roleLabel(p.userType), style: const TextStyle(fontSize: 13, color: AppColors.muted)),
        if (p.isVerified == true) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.successBg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Verified',
              style: TextStyle(fontSize: 11, color: AppColors.successText, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ],
    );
  }

  Widget _editForm(ProfileData p) {
    final hasRetailer = p.retailer != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LabeledField(
          label: 'Full Name',
          controller: _nameCtrl,
          hint: 'Enter your full name',
          textInputAction: TextInputAction.next,
        ),
        if (hasRetailer) ...[
          const SizedBox(height: 14),
          LabeledField(
            label: 'Shop Name',
            controller: _shopCtrl,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 14),
          LabeledField(
            label: 'Address',
            controller: _addressCtrl,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 14),
          LabeledField(
            label: 'City',
            controller: _cityCtrl,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 14),
          LabeledField(
            label: 'State',
            controller: _stateCtrl,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 14),
          LabeledField(
            label: 'Pincode',
            controller: _pincodeCtrl,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
          ),
        ] else ...[
          const SizedBox(height: 8),
          const Text(
            'Shop and address details are created after your onboarding is approved.',
            style: TextStyle(fontSize: 12, color: AppColors.muted),
          ),
        ],
      ],
    );
  }

  Widget _card(String title, List<Widget> rows) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.text),
          ),
          const SizedBox(height: 8),
          ...rows,
        ],
      ),
    );
  }

  Widget _row(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 110,
              child: Text(k, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
            ),
            Expanded(
              child: Text(v, style: const TextStyle(fontSize: 14, color: AppColors.text)),
            ),
          ],
        ),
      );
}
