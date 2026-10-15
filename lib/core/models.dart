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

double _toDouble(dynamic v) => (v as num?)?.toDouble() ?? 0;
int _toInt(dynamic v) => (v as num?)?.toInt() ?? 0;
String? _toStr(dynamic v) => v?.toString();

List<T> _toList<T>(dynamic v, T Function(Map<String, dynamic>) build) {
  if (v is! List) return const [];
  return v
      .whereType<Map>()
      .map((e) => build(e.cast<String, dynamic>()))
      .toList();
}

Map<String, dynamic> _asMap(dynamic v) =>
    v is Map ? v.cast<String, dynamic>() : const <String, dynamic>{};

/// Response of GET v1/dashboard/retailer.
class RetailerDashboard {
  final DashboardGreeting greeting;
  final DashboardCredit credit;
  final DashboardToday today;
  final DashboardCounts counts;
  final double pendingPaymentsTotal;
  final DashboardBankCard bankCard;
  final List<DashboardBanner> banners;
  final List<DashboardScheme> paperSchemes;
  final List<DashboardScheme> standardSchemes;
  final List<DashboardScheme> marquee;
  final List<DashboardOrder> latestOrders;
  final List<DashboardPendingPayment> pendingPayments;
  final List<DashboardQuickAction> quickActions;

  const RetailerDashboard({
    required this.greeting,
    required this.credit,
    required this.today,
    required this.counts,
    required this.pendingPaymentsTotal,
    required this.bankCard,
    required this.banners,
    required this.paperSchemes,
    required this.standardSchemes,
    required this.marquee,
    required this.latestOrders,
    required this.pendingPayments,
    required this.quickActions,
  });

  factory RetailerDashboard.fromJson(Map<String, dynamic> j) => RetailerDashboard(
        greeting: DashboardGreeting.fromJson(_asMap(j['greeting'])),
        credit: DashboardCredit.fromJson(_asMap(j['credit'])),
        today: DashboardToday.fromJson(_asMap(j['today'])),
        counts: DashboardCounts.fromJson(_asMap(j['counts'])),
        pendingPaymentsTotal: _toDouble(j['pending_payments_total']),
        bankCard: DashboardBankCard.fromJson(_asMap(j['bank_card'])),
        banners: _toList(j['banners'], DashboardBanner.fromJson),
        paperSchemes: _toList(j['paper_schemes'], DashboardScheme.fromJson),
        standardSchemes: _toList(j['standard_schemes'], DashboardScheme.fromJson),
        marquee: _toList(j['marquee'], DashboardScheme.fromJson),
        latestOrders: _toList(j['latest_orders'], DashboardOrder.fromJson),
        pendingPayments:
            _toList(j['pending_payments'], DashboardPendingPayment.fromJson),
        quickActions: _toList(j['quick_actions'], DashboardQuickAction.fromJson),
      );

  /// All active schemes with the paper ones first (same order as the ticker).
  List<DashboardScheme> get allSchemes => marquee;
}

class DashboardGreeting {
  final String name;
  final String firstName;
  final String? retailerCode;
  final String category;
  final String? date;

  const DashboardGreeting({
    required this.name,
    required this.firstName,
    this.retailerCode,
    this.category = 'D',
    this.date,
  });

  factory DashboardGreeting.fromJson(Map<String, dynamic> j) {
    final name = _toStr(j['name']) ?? 'Retailer';
    return DashboardGreeting(
      name: name,
      firstName: _toStr(j['first_name']) ?? name.split(' ').first,
      retailerCode: _toStr(j['retailer_code']),
      category: _toStr(j['category']) ?? 'D',
      date: _toStr(j['date']),
    );
  }
}

class DashboardCredit {
  final double limit;
  final double currentBalance;
  final double availableCredit;
  final int creditDays;

  const DashboardCredit({
    this.limit = 0,
    this.currentBalance = 0,
    this.availableCredit = 0,
    this.creditDays = 0,
  });

  factory DashboardCredit.fromJson(Map<String, dynamic> j) => DashboardCredit(
        limit: _toDouble(j['limit']),
        currentBalance: _toDouble(j['current_balance']),
        availableCredit: _toDouble(j['available_credit']),
        creditDays: _toInt(j['credit_days']),
      );

  double get usedRatio =>
      limit <= 0 ? 0 : (currentBalance / limit).clamp(0.0, 1.0).toDouble();
}

class DashboardToday {
  final int ordersCount;
  final double salesValue;
  final double paidValue;

  const DashboardToday({
    this.ordersCount = 0,
    this.salesValue = 0,
    this.paidValue = 0,
  });

  factory DashboardToday.fromJson(Map<String, dynamic> j) => DashboardToday(
        ordersCount: _toInt(j['orders_count']),
        salesValue: _toDouble(j['sales_value']),
        paidValue: _toDouble(j['paid_value']),
      );
}

class DashboardCounts {
  final int pendingOrders;
  final int dispatched;
  final int pendingPayments;

  const DashboardCounts({
    this.pendingOrders = 0,
    this.dispatched = 0,
    this.pendingPayments = 0,
  });

  factory DashboardCounts.fromJson(Map<String, dynamic> j) => DashboardCounts(
        pendingOrders: _toInt(j['pending_orders']),
        dispatched: _toInt(j['dispatched']),
        pendingPayments: _toInt(j['pending_payments']),
      );
}

class DashboardBankCard {
  final String status;
  final String message;
  final String? action;

  const DashboardBankCard({
    this.status = 'Inactive',
    this.message = '',
    this.action,
  });

  factory DashboardBankCard.fromJson(Map<String, dynamic> j) => DashboardBankCard(
        status: _toStr(j['status']) ?? 'Inactive',
        message: _toStr(j['message']) ?? '',
        action: _toStr(j['action']),
      );

  bool get isActive => status.toLowerCase() == 'active';
  bool get isPending => status.toLowerCase() == 'pending';
}

class DashboardBanner {
  final String id;
  final String type;
  final String? mediaUrl;
  final String? streamUrl;
  final String? title;

  const DashboardBanner({
    required this.id,
    this.type = 'image',
    this.mediaUrl,
    this.streamUrl,
    this.title,
  });

  factory DashboardBanner.fromJson(Map<String, dynamic> j) => DashboardBanner(
        id: _toStr(j['id']) ?? '',
        type: _toStr(j['type']) ?? 'image',
        mediaUrl: _toStr(j['media_url']),
        streamUrl: _toStr(j['stream_url']),
        title: _toStr(j['title']),
      );

  bool get isVideo => type.toLowerCase() == 'video';
}

class DashboardScheme {
  final int id;
  final String originType;
  final String? title;
  final String? schemeType;
  final int? productId;
  final String productName;
  final int minQuantity;
  final double minAmount;
  final String? minText;
  final String? giftName;
  final double? giftValue;
  final String? giftImageUrl;
  final String? startDate;
  final String? endDate;
  final int? stockAvailable;
  final bool isAvailable;

  const DashboardScheme({
    required this.id,
    this.originType = 'Standard Scheme',
    this.title,
    this.schemeType,
    this.productId,
    this.productName = 'All Products',
    this.minQuantity = 0,
    this.minAmount = 0,
    this.minText,
    this.giftName,
    this.giftValue,
    this.giftImageUrl,
    this.startDate,
    this.endDate,
    this.stockAvailable,
    this.isAvailable = true,
  });

  factory DashboardScheme.fromJson(Map<String, dynamic> j) => DashboardScheme(
        id: _toInt(j['id']),
        originType: _toStr(j['origin_type']) ?? 'Standard Scheme',
        title: _toStr(j['title']),
        schemeType: _toStr(j['scheme_type']),
        productId: (j['product_id'] as num?)?.toInt(),
        productName: _toStr(j['product_name']) ?? 'All Products',
        minQuantity: _toInt(j['min_quantity']),
        minAmount: _toDouble(j['min_amount']),
        minText: _toStr(j['min_text']),
        giftName: _toStr(j['gift_name']),
        giftValue: (j['gift_value'] as num?)?.toDouble(),
        giftImageUrl: _toStr(j['gift_image_url']),
        startDate: _toStr(j['start_date']),
        endDate: _toStr(j['end_date']),
        stockAvailable: (j['stock_available'] as num?)?.toInt(),
        isAvailable: j['is_available'] != false,
      );

  bool get isPaper => originType.toLowerCase() == 'paper scheme';
}

class DashboardOrder {
  final int orderId;
  final String? invoiceNumber;
  final String displayNumber;
  final String customer;
  final double total;
  final String? paymentStatus;
  final bool isPaid;
  final String? createdAt;

  const DashboardOrder({
    required this.orderId,
    this.invoiceNumber,
    this.displayNumber = '',
    this.customer = 'Customer',
    this.total = 0,
    this.paymentStatus,
    this.isPaid = false,
    this.createdAt,
  });

  factory DashboardOrder.fromJson(Map<String, dynamic> j) => DashboardOrder(
        orderId: _toInt(j['order_id']),
        invoiceNumber: _toStr(j['invoice_number']),
        displayNumber: _toStr(j['display_number']) ?? '',
        customer: _toStr(j['customer']) ?? 'Customer',
        total: _toDouble(j['total']),
        paymentStatus: _toStr(j['payment_status']),
        isPaid: j['is_paid'] == true,
        createdAt: _toStr(j['created_at']),
      );
}

class DashboardPendingPayment {
  final int orderId;
  final String? invoiceNumber;
  final double total;
  final double? paidAmount;
  final double? dueAmount;
  final String? dueDate;
  final String? paymentStatus;
  final bool isOverdue;
  final String badge;

  const DashboardPendingPayment({
    required this.orderId,
    this.invoiceNumber,
    this.total = 0,
    this.paidAmount,
    this.dueAmount,
    this.dueDate,
    this.paymentStatus,
    this.isOverdue = false,
    this.badge = 'Pending',
  });

  factory DashboardPendingPayment.fromJson(Map<String, dynamic> j) =>
      DashboardPendingPayment(
        orderId: _toInt(j['order_id']),
        invoiceNumber: _toStr(j['invoice_number']),
        total: _toDouble(j['total']),
        paidAmount: (j['paid_amount'] as num?)?.toDouble(),
        dueAmount: (j['due_amount'] as num?)?.toDouble(),
        dueDate: _toStr(j['due_date']),
        paymentStatus: _toStr(j['payment_status']),
        isOverdue: j['is_overdue'] == true,
        badge: _toStr(j['badge']) ?? 'Pending',
      );
}

class DashboardQuickAction {
  final String key;
  final String label;
  final String? web;

  const DashboardQuickAction({
    required this.key,
    required this.label,
    this.web,
  });

  factory DashboardQuickAction.fromJson(Map<String, dynamic> j) =>
      DashboardQuickAction(
        key: _toStr(j['key']) ?? '',
        label: _toStr(j['label']) ?? '',
        web: _toStr(j['web']),
      );
}
