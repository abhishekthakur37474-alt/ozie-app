import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import '../core/api_client.dart';
import '../core/constants.dart';
import '../core/models.dart';
import '../core/onboarding_service.dart';
import '../widgets/app_widgets.dart';

/// Retailer self-onboarding form (v1/onboarding/submit).
///
/// Photo upload (license_photo / shop_photos) is optional on the server and is
/// intentionally not part of this step.
class RetailerFormScreen extends StatefulWidget {
  final Session session;
  const RetailerFormScreen({super.key, required this.session});

  @override
  State<RetailerFormScreen> createState() => _RetailerFormScreenState();
}

class _RetailerFormScreenState extends State<RetailerFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _licenseName = TextEditingController();
  final _licenseNo = TextEditingController();
  final _shopName = TextEditingController();
  final _contact = TextEditingController();
  final _altContact = TextEditingController();
  final _email = TextEditingController();
  final _opName = TextEditingController();
  final _opNumber = TextEditingController();
  final _areaTerritory = TextEditingController();

  final _building = TextEditingController();
  final _street = TextEditingController();
  final _landmark = TextEditingController();
  final _locality = TextEditingController();
  final _city = TextEditingController();
  final _pincode = TextEditingController();
  final _country = TextEditingController(text: 'India');

  final _purchaseCases = TextEditingController();
  final _offtake = TextEditingController();

  final _contactFocus = FocusNode();
  final _licenseFocus = FocusNode();

  final List<String> _brands = [];
  final List<String> _categories = [];
  final List<String> _expectations = [];

  String _outlet = kOutletTypes.first;
  String? _state;
  bool _confirmLocation = false;

  String _brandAvailability = 'No';
  String _outOfStock = 'Medium';

  final Map<String, String> _scores = {
    'stock_holding_capacity': '3',
    'purchasing_capacity': '3',
    'payment_behavior': '3',
    'our_brand_visibility': '3',
    'support_towards_brand': '3',
  };

  static const Map<String, String> _scoreLabels = {
    'stock_holding_capacity': 'Stock Holding Capacity',
    'purchasing_capacity': 'Purchasing Capacity',
    'payment_behavior': 'Payment Behavior',
    'our_brand_visibility': 'Our Brand Visibility',
    'support_towards_brand': 'Support Towards Brand',
  };

  bool? _contactAvailable;
  bool? _licenseAvailable;
  bool _checkingContact = false;
  bool _checkingLicense = false;
  bool _fetchingLocation = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _contact.text = widget.session.user.mobile ?? '';
    _email.text = widget.session.user.email ?? '';
    _contactFocus.addListener(() {
      if (!_contactFocus.hasFocus) _checkContact();
    });
    _licenseFocus.addListener(() {
      if (!_licenseFocus.hasFocus) _checkLicense();
    });
  }

  @override
  void dispose() {
    _licenseName.dispose();
    _licenseNo.dispose();
    _shopName.dispose();
    _contact.dispose();
    _altContact.dispose();
    _email.dispose();
    _opName.dispose();
    _opNumber.dispose();
    _areaTerritory.dispose();
    _building.dispose();
    _street.dispose();
    _landmark.dispose();
    _locality.dispose();
    _city.dispose();
    _pincode.dispose();
    _country.dispose();
    _purchaseCases.dispose();
    _offtake.dispose();
    _contactFocus.dispose();
    _licenseFocus.dispose();
    super.dispose();
  }

  String _digits(String v) => v.replaceAll(RegExp(r'\D'), '');

  Future<void> _checkContact() async {
    final d = _digits(_contact.text);
    if (d.length != 10) {
      if (mounted) setState(() => _contactAvailable = null);
      return;
    }
    setState(() => _checkingContact = true);
    try {
      final r = await OnboardingService.checkDuplicate(contactNumber: d);
      if (!mounted) return;
      setState(() => _contactAvailable = r.contactAvailable);
    } on ApiException {
      // ignore; server validates again on submit
    } finally {
      if (mounted) setState(() => _checkingContact = false);
    }
  }

  Future<void> _checkLicense() async {
    final v = _licenseNo.text.trim();
    if (v.isEmpty) {
      if (mounted) setState(() => _licenseAvailable = null);
      return;
    }
    setState(() => _checkingLicense = true);
    try {
      final r = await OnboardingService.checkDuplicate(licenseNumber: v);
      if (!mounted) return;
      setState(() => _licenseAvailable = r.licenseAvailable);
    } on ApiException {
      // ignore; server validates again on submit
    } finally {
      if (mounted) setState(() => _checkingLicense = false);
    }
  }

  Future<void> _addToList(List<String> list, String title) async {
    final value = await showDialog<String>(
      context: context,
      builder: (_) => _AddValueDialog(title: title),
    );
    final v = value?.trim() ?? '';
    if (v.isNotEmpty && mounted) setState(() => list.add(v));
  }

  String? _clean(String? v) {
    final t = v?.trim() ?? '';
    return t.isEmpty ? null : t;
  }

  void _fill(TextEditingController c, String? v) {
    final t = _clean(v);
    if (t != null) c.text = t;
  }

  String? _matchState(String? area) {
    final a = _clean(area);
    if (a == null) return null;
    final lower = a.toLowerCase();
    for (final s in kIndianStates) {
      if (s.toLowerCase() == lower) return s;
    }
    const aliases = {
      'orissa': 'Odisha',
      'uttaranchal': 'Uttarakhand',
      'pondicherry': 'Puducherry',
      'jammu & kashmir': 'Jammu and Kashmir',
      'nct of delhi': 'Delhi',
      'new delhi': 'Delhi',
      'tamilnadu': 'Tamil Nadu',
      'telengana': 'Telangana',
    };
    final alias = aliases[lower];
    if (alias != null) return alias;
    for (final s in kIndianStates) {
      if (lower.contains(s.toLowerCase())) return s;
    }
    return null;
  }

  void _applyPlacemark(Placemark p) {
    _fill(_building, _clean(p.subThoroughfare) ?? p.name);
    _fill(_street, _clean(p.thoroughfare) ?? p.street);
    _fill(_locality, _clean(p.subLocality) ?? p.locality);
    _fill(_city, _clean(p.locality) ?? p.subAdministrativeArea);
    _fill(_pincode, p.postalCode);
    _fill(_country, _clean(p.country) ?? 'India');
    final matched = _matchState(p.administrativeArea);
    if (matched != null) _state = matched;
  }

  Future<void> _fetchLocation() async {
    if (_fetchingLocation) return;
    setState(() => _fetchingLocation = true);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        if (mounted) {
          showStatus(context, 'Location services are off. Please enable GPS.', error: true);
        }
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) {
          showStatus(context, 'Location permission denied. Allow it to auto-fill.', error: true);
        }
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      final placemarks = await Geocoding().placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (!mounted) return;
      if (placemarks.isEmpty) {
        showStatus(context, 'Could not resolve your address. Please enter it manually.', error: true);
        return;
      }
      setState(() => _applyPlacemark(placemarks.first));
      showStatus(context, 'Location fetched. Please verify the address.');
    } catch (_) {
      if (mounted) {
        showStatus(context, 'Could not fetch location. Please try again.', error: true);
      }
    } finally {
      if (mounted) setState(() => _fetchingLocation = false);
    }
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    if (_brands.isEmpty) {
      showStatus(context, 'Add at least one most selling brand.', error: true);
      return;
    }
    if (!_confirmLocation) {
      showStatus(context, 'Please confirm that you have verified the location.', error: true);
      return;
    }
    if (_contactAvailable == false) {
      showStatus(context, 'This Contact Number is already registered.', error: true);
      return;
    }
    if (_licenseAvailable == false) {
      showStatus(context, 'This License Number is already registered.', error: true);
      return;
    }

    final form = <String, dynamic>{
      'license_retailer_name': _licenseName.text.trim(),
      'license_number': _licenseNo.text.trim(),
      'shop_name': _shopName.text.trim(),
      'contact_number': _digits(_contact.text),
      'alternate_contact_number': _digits(_altContact.text),
      'email': _email.text.trim(),
      'shop_operator_name': _opName.text.trim(),
      'shop_operator_number': _digits(_opNumber.text),
      'outlet_type': _outlet,
      'area_territory': _areaTerritory.text.trim(),
      'building_number': _building.text.trim(),
      'street_name': _street.text.trim(),
      'landmark': _landmark.text.trim(),
      'area_locality': _locality.text.trim(),
      'city': _city.text.trim(),
      'state': _state ?? '',
      'pincode': _pincode.text.trim(),
      'country': _country.text.trim().isEmpty ? 'India' : _country.text.trim(),
      'confirm_location_chk': true,
      'most_selling_brands': _brands,
      'category_preference': _categories,
      'our_brand_availability': _brandAvailability,
      'avg_monthly_purchase_cases': int.tryParse(_purchaseCases.text.trim()) ?? 0,
      'avg_monthly_offtake': int.tryParse(_offtake.text.trim()) ?? 0,
      'out_of_stock_frequency': _outOfStock,
      'retailer_expectations': _expectations,
      'stock_holding_capacity': int.tryParse(_scores['stock_holding_capacity']!) ?? 0,
      'purchasing_capacity': int.tryParse(_scores['purchasing_capacity']!) ?? 0,
      'payment_behavior': int.tryParse(_scores['payment_behavior']!) ?? 0,
      'our_brand_visibility': int.tryParse(_scores['our_brand_visibility']!) ?? 0,
      'support_towards_brand': int.tryParse(_scores['support_towards_brand']!) ?? 0,
    };

    setState(() => _submitting = true);
    try {
      final session = await OnboardingService.submitRetailerForm(form);
      if (!mounted) return;
      showStatus(context, 'Retailer form submitted successfully!');
      Navigator.of(context).pop<Session>(session);
    } on ApiException catch (e) {
      if (!mounted) return;
      showStatus(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String? _req10(String? v) {
    if (v == null || v.trim().isEmpty) return 'This field is required';
    return _digits(v).length == 10 ? null : 'Must be exactly 10 digits';
  }

  String? _opt10(String? v) {
    final d = _digits(v ?? '');
    if (d.isEmpty) return null;
    return d.length == 10 ? null : 'Must be exactly 10 digits';
  }

  String? _emailValidator(String? v) {
    final t = (v ?? '').trim();
    if (t.isEmpty) return null;
    final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(t);
    return ok ? null : 'Enter a valid email address';
  }

  String? _pinValidator(String? v) {
    final d = (v ?? '').trim();
    if (d.isEmpty) return 'This field is required';
    return RegExp(r'^[0-9]{6}$').hasMatch(d) ? null : 'Pincode must be 6 digits';
  }

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 12),
        child: Text(
          text,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.text),
        ),
      );

  Widget _availability(bool? ok, bool checking, {String available = 'Available'}) {
    if (checking) {
      return const Padding(
        padding: EdgeInsets.only(top: 4),
        child: Text('Checking availability...', style: TextStyle(fontSize: 11, color: AppColors.muted)),
      );
    }
    if (ok == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        ok ? available : 'Already registered',
        style: TextStyle(fontSize: 11, color: ok ? AppColors.successText : AppColors.dangerText),
      ),
    );
  }

  Widget _listField(String label, List<String> values, String dialogTitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.text)),
        const SizedBox(height: 6),
        if (values.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final v in values)
                Chip(
                  label: Text(v, style: const TextStyle(fontSize: 12)),
                  backgroundColor: AppColors.inputBg,
                  side: const BorderSide(color: AppColors.border),
                  deleteIcon: const Icon(Icons.close, size: 16),
                  onDeleted: () => setState(() => values.remove(v)),
                ),
            ],
          ),
        if (values.isNotEmpty) const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            onPressed: _submitting ? null : () => _addToList(values, dialogTitle),
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Add', style: TextStyle(fontSize: 13)),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 36),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Retailer Registration'),
        backgroundColor: AppColors.bg,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            _sectionTitle('License & Shop'),
            LabeledField(
              label: 'License Retailer Name *',
              controller: _licenseName,
              hint: 'Name on the license',
              textInputAction: TextInputAction.next,
              validator: requiredValidator,
            ),
            const SizedBox(height: 14),
            LabeledField(
              label: 'License Number *',
              controller: _licenseNo,
              hint: 'Enter license number',
              focusNode: _licenseFocus,
              textInputAction: TextInputAction.next,
              validator: requiredValidator,
            ),
            _availability(_licenseAvailable, _checkingLicense),
            const SizedBox(height: 14),
            LabeledField(
              label: 'Shop Name *',
              controller: _shopName,
              hint: 'Enter shop name',
              textInputAction: TextInputAction.next,
              validator: requiredValidator,
            ),
            const SizedBox(height: 14),
            LabeledField(
              label: 'Contact Number *',
              controller: _contact,
              hint: '10 digit mobile number',
              keyboardType: TextInputType.phone,
              focusNode: _contactFocus,
              textInputAction: TextInputAction.next,
              validator: _req10,
            ),
            _availability(_contactAvailable, _checkingContact),
            const SizedBox(height: 14),
            LabeledField(
              label: 'Alternate Contact Number',
              controller: _altContact,
              hint: '10 digit mobile number',
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              validator: _opt10,
            ),
            const SizedBox(height: 14),
            LabeledField(
              label: 'Email',
              controller: _email,
              hint: 'Enter email address',
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: _emailValidator,
            ),
            const SizedBox(height: 14),
            LabeledField(
              label: 'Shop Operator Name',
              controller: _opName,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 14),
            LabeledField(
              label: 'Shop Operator Contact Number',
              controller: _opNumber,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              validator: _opt10,
            ),
            const SizedBox(height: 14),
            LabeledDropdown(
              label: 'Outlet Type',
              hint: 'Select outlet type',
              items: kOutletTypes,
              value: _outlet,
              onChanged: (v) => setState(() => _outlet = v ?? kOutletTypes.first),
            ),
            const SizedBox(height: 14),
            LabeledField(
              label: 'Area / Territory',
              controller: _areaTerritory,
              textInputAction: TextInputAction.next,
            ),

            _sectionTitle('Shop Location'),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: (_submitting || _fetchingLocation) ? null : _fetchLocation,
                icon: _fetchingLocation
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.my_location, size: 18),
                label: Text(
                  _fetchingLocation ? 'Fetching location...' : 'Fetch Current Location',
                  style: const TextStyle(fontSize: 13),
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 40),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  foregroundColor: AppColors.blue,
                  side: const BorderSide(color: AppColors.blue),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
            const SizedBox(height: 14),
            LabeledField(
              label: 'Shop / Building Number *',
              controller: _building,
              textInputAction: TextInputAction.next,
              validator: requiredValidator,
            ),
            const SizedBox(height: 14),
            LabeledField(
              label: 'Street / Road Name *',
              controller: _street,
              textInputAction: TextInputAction.next,
              validator: requiredValidator,
            ),
            const SizedBox(height: 14),
            LabeledField(
              label: 'Landmark',
              controller: _landmark,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 14),
            LabeledField(
              label: 'Area / Locality *',
              controller: _locality,
              textInputAction: TextInputAction.next,
              validator: requiredValidator,
            ),
            const SizedBox(height: 14),
            LabeledField(
              label: 'City *',
              controller: _city,
              textInputAction: TextInputAction.next,
              validator: requiredValidator,
            ),
            const SizedBox(height: 14),
            LabeledDropdown(
              label: 'State *',
              hint: 'Select State...',
              items: kIndianStates,
              value: _state,
              onChanged: (v) => setState(() => _state = v),
              validator: (v) => v == null ? 'Please select a state' : null,
            ),
            const SizedBox(height: 14),
            LabeledField(
              label: 'Pincode *',
              controller: _pincode,
              hint: '6 digit pincode',
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              validator: _pinValidator,
            ),
            const SizedBox(height: 14),
            LabeledField(
              label: 'Country',
              controller: _country,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 14),
            CheckboxListTile(
              value: _confirmLocation,
              onChanged: (v) => setState(() => _confirmLocation = v ?? false),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: const Text(
                'I confirm that the shop location details above are verified.',
                style: TextStyle(fontSize: 13, color: AppColors.text),
              ),
            ),

            _sectionTitle('Business Details'),
            _listField('Most Selling Brands *', _brands, 'Add brand'),
            const SizedBox(height: 14),
            _listField('Category Preference', _categories, 'Add category'),
            const SizedBox(height: 14),
            LabeledField(
              label: 'Average Monthly Purchase (cases)',
              controller: _purchaseCases,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 14),
            LabeledDropdown(
              label: 'Our Brand Availability',
              hint: 'Select',
              items: kYesNo,
              value: _brandAvailability,
              onChanged: (v) => setState(() => _brandAvailability = v ?? 'No'),
            ),
            const SizedBox(height: 14),
            LabeledField(
              label: 'Average Monthly Offtake',
              controller: _offtake,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 14),
            LabeledDropdown(
              label: 'Out of Stock Frequency',
              hint: 'Select',
              items: kOutOfStockOptions,
              value: _outOfStock,
              onChanged: (v) => setState(() => _outOfStock = v ?? 'Medium'),
            ),
            const SizedBox(height: 14),
            _listField('Retailer Expectations', _expectations, 'Add expectation'),

            _sectionTitle('Score Card (1-5)'),
            for (final entry in _scoreLabels.entries) ...[
              LabeledDropdown(
                label: entry.value,
                hint: 'Select score',
                items: kScoreOptions,
                value: _scores[entry.key],
                onChanged: (v) => setState(() => _scores[entry.key] = v ?? '3'),
              ),
              const SizedBox(height: 14),
            ],

            const SizedBox(height: 8),
            GradientButton(
              label: 'Submit Registration',
              loading: _submitting,
              onPressed: _submitting ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}

/// Single-value input dialog. Owns its [TextEditingController] so it is
/// disposed together with the dialog route (prevents the "controller used
/// after being disposed" crash when the dialog closes via submit).
class _AddValueDialog extends StatefulWidget {
  final String title;
  const _AddValueDialog({required this.title});

  @override
  State<_AddValueDialog> createState() => _AddValueDialogState();
}

class _AddValueDialogState extends State<_AddValueDialog> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _submit() => Navigator.of(context).pop(_ctrl.text);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _ctrl,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        textInputAction: TextInputAction.done,
        decoration: const InputDecoration(hintText: 'Type a value'),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        TextButton(onPressed: _submit, child: const Text('Add')),
      ],
    );
  }
}
