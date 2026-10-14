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
