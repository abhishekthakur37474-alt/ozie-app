import 'api_client.dart';
import 'models.dart';

/// ozie-api profile endpoints (v1/profile/*).
class ProfileService {
  ProfileService._();

  static final ApiClient _api = ApiClient.instance;

  static ProfileData _parse(Map<String, dynamic> res) {
    final data = res['data'];
    if (data is Map<String, dynamic>) return ProfileData.fromJson(data);
    throw ApiException('Unexpected server response.');
  }

  static Future<ProfileData> get() async {
    final res = await _api.get('v1/profile/get');
    return _parse(res);
  }

  /// Partial update: only the provided fields are sent.
  /// `name` updates the users row; retailer fields require a retailer profile.
  static Future<ProfileData> update({
    String? name,
    String? shopName,
    String? address,
    String? city,
    String? state,
    String? pincode,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (shopName != null) body['shop_name'] = shopName;
    if (address != null) body['address'] = address;
    if (city != null) body['city'] = city;
    if (state != null) body['state'] = state;
    if (pincode != null) body['pincode'] = pincode;
    if (body.isEmpty) throw ApiException('Nothing to update.');
    final res = await _api.post('v1/profile/update', body: body);
    return _parse(res);
  }
}
