class AppUser {
  final int id;
  final String? name;
  final String? email;
  final String? mobile;
  final String? userType;

  const AppUser({
    required this.id,
    this.name,
    this.email,
    this.mobile,
    this.userType,
  });

  factory AppUser.fromJson(Map<String, dynamic> j) => AppUser(
        id: (j['id'] as num).toInt(),
        name: j['name']?.toString(),
        email: j['email']?.toString(),
        mobile: j['mobile']?.toString(),
        userType: j['user_type']?.toString(),
      );

  String get displayName =>
      (name != null && name!.trim().isNotEmpty) ? name!.trim() : (email ?? 'User');

  String get roleLabel {
    final t = userType;
    if (t == null || t.isEmpty) return 'No role yet';
    return t
        .split('_')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }
}

/// next_screen: dashboard | wait_for_approval | role_selection
class Session {
  final AppUser user;
  final String nextScreen;
  final bool inquirySubmitted;
  final int retailerFormFilled;

  const Session({
    required this.user,
    required this.nextScreen,
    required this.inquirySubmitted,
    required this.retailerFormFilled,
  });

  factory Session.fromData(Map<String, dynamic> d) => Session(
        user: AppUser.fromJson(d['user'] as Map<String, dynamic>),
        nextScreen: (d['next_screen'] as String?) ?? 'dashboard',
        inquirySubmitted: d['inquiry_submitted'] == true,
        retailerFormFilled: (d['retailer_form_filled'] as num?)?.toInt() ?? 0,
      );
}

/// Retailer block from GET/POST v1/profile.
class RetailerProfile {
  final String? name;
  final String? shopName;
  final String? address;
  final String? city;
  final String? state;
  final String? pincode;
  final String? gpsCoordinates;
  final String? gst;
  final String? pan;
  final String? retailerCode;
  final String? category;
  final String? status;
  final double creditLimit;
  final double currentBalance;
  final double availableCredit;
  final int creditDays;
  final String? photoUrl;

  const RetailerProfile({
    this.name,
    this.shopName,
    this.address,
    this.city,
    this.state,
    this.pincode,
    this.gpsCoordinates,
    this.gst,
    this.pan,
    this.retailerCode,
    this.category,
    this.status,
    this.creditLimit = 0,
    this.currentBalance = 0,
    this.availableCredit = 0,
    this.creditDays = 0,
    this.photoUrl,
  });

  factory RetailerProfile.fromJson(Map<String, dynamic> j) => RetailerProfile(
        name: j['name']?.toString(),
        shopName: j['shop_name']?.toString(),
        address: j['address']?.toString(),
        city: j['city']?.toString(),
        state: j['state']?.toString(),
        pincode: j['pincode']?.toString(),
        gpsCoordinates: j['gps_coordinates']?.toString(),
        gst: j['gst']?.toString(),
        pan: j['pan']?.toString(),
        retailerCode: j['retailer_code']?.toString(),
        category: j['category']?.toString(),
        status: j['status']?.toString(),
        creditLimit: (j['credit_limit'] as num?)?.toDouble() ?? 0,
        currentBalance: (j['current_balance'] as num?)?.toDouble() ?? 0,
        availableCredit: (j['available_credit'] as num?)?.toDouble() ?? 0,
        creditDays: (j['credit_days'] as num?)?.toInt() ?? 0,
        photoUrl: j['photo_url']?.toString(),
      );
}

/// License block from GET/POST v1/profile.
class LicenseProfile {
  final String? licenseCopyUrl;
  final String? holderName;
  final String? holderContact;
  final String? holderAddress;
  final String? operatorName;
  final String? operatorContact;
  final String? operatorAddress;

  const LicenseProfile({
    this.licenseCopyUrl,
    this.holderName,
    this.holderContact,
    this.holderAddress,
    this.operatorName,
    this.operatorContact,
    this.operatorAddress,
  });

  factory LicenseProfile.fromJson(Map<String, dynamic> j) => LicenseProfile(
        licenseCopyUrl: j['license_copy_url']?.toString(),
        holderName: j['holder_name']?.toString(),
        holderContact: j['holder_contact']?.toString(),
        holderAddress: j['holder_address']?.toString(),
        operatorName: j['operator_name']?.toString(),
        operatorContact: j['operator_contact']?.toString(),
        operatorAddress: j['operator_address']?.toString(),
      );
}

/// Response of GET v1/profile/get and POST v1/profile/update.
class ProfileData {
  final int id;
  final String? name;
  final String? email;
  final String? mobile;
  final String? userType;
  final bool? isVerified;
  final String? memberSince;
  final String? photoUrl;
  final RetailerProfile? retailer;
  final LicenseProfile? license;

  const ProfileData({
    required this.id,
    this.name,
    this.email,
    this.mobile,
    this.userType,
    this.isVerified,
    this.memberSince,
    this.photoUrl,
    this.retailer,
    this.license,
  });

  factory ProfileData.fromJson(Map<String, dynamic> d) {
    final p = d['profile'] is Map<String, dynamic>
        ? d['profile'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final r = d['retailer'];
    final l = d['license'];
    return ProfileData(
      id: (p['id'] as num?)?.toInt() ?? 0,
      name: p['name']?.toString(),
      email: p['email']?.toString(),
      mobile: p['mobile']?.toString(),
      userType: p['user_type']?.toString(),
      isVerified: p['is_verified'] as bool?,
      memberSince: p['member_since']?.toString(),
      photoUrl: p['photo_url']?.toString(),
      retailer: r is Map<String, dynamic> ? RetailerProfile.fromJson(r) : null,
      license: l is Map<String, dynamic> ? LicenseProfile.fromJson(l) : null,
    );
  }

  AppUser toUser() => AppUser(
        id: id,
        name: name,
        email: email,
        mobile: mobile,
        userType: userType,
      );

  String get displayName =>
      (name != null && name!.trim().isNotEmpty) ? name!.trim() : (email ?? 'User');
}

/// Response of POST v1/onboarding/check-duplicate.
class DuplicateResult {
  final bool? contactAvailable;
  final bool? licenseAvailable;

  const DuplicateResult({this.contactAvailable, this.licenseAvailable});

  factory DuplicateResult.fromJson(Map<String, dynamic> j) => DuplicateResult(
        contactAvailable: j['contact_available'] as bool?,
        licenseAvailable: j['license_available'] as bool?,
      );
}
