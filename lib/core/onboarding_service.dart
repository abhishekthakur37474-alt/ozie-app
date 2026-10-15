import 'api_client.dart';
import 'models.dart';

/// ozie-api onboarding endpoints (v1/onboarding/*).
class OnboardingService {
  OnboardingService._();

  static final ApiClient _api = ApiClient.instance;

  static Map<String, dynamic> _dataOf(Map<String, dynamic> res) {
    final data = res['data'];
    if (data is Map<String, dynamic>) return data;
    throw ApiException('Unexpected server response.');
  }

  /// Verifies the introduction code given by a manufacturer/distributor.
  /// On success the retailer form can be opened.
  static Future<void> verifyCode(String code) async {
    await _api.post('v1/onboarding/verify-code', body: {'code': code});
  }

  /// "No, I'm not a retailer" inquiry.
  static Future<void> submitInquiry({
    required String companyName,
    required String name,
    required String contactNumber,
    required String industry,
    required String location,
    required String userType,
  }) async {
    await _api.post('v1/onboarding/inquiry', body: {
      'company_name': companyName,
      'name': name,
      'contact_number': contactNumber,
      'industry': industry,
      'location': location,
      'user_type': userType,
    });
  }

  /// Live duplicate check while filling the retailer form.
  static Future<DuplicateResult> checkDuplicate({
    String? contactNumber,
    String? licenseNumber,
  }) async {
    final body = <String, dynamic>{};
    if (contactNumber != null && contactNumber.isNotEmpty) {
      body['contact_number'] = contactNumber;
    }
    if (licenseNumber != null && licenseNumber.isNotEmpty) {
      body['license_number'] = licenseNumber;
    }
    final res = await _api.post('v1/onboarding/check-duplicate', body: body);
    return DuplicateResult.fromJson(_dataOf(res));
  }

  /// Submits the full retailer registration form. Returns the new session state
  /// (next_screen becomes `wait_for_approval`).
  static Future<Session> submitRetailerForm(Map<String, dynamic> form) async {
    final res = await _api.post('v1/onboarding/submit', body: form);
    return Session.fromData(_dataOf(res));
  }
}
