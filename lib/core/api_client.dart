import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'config.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final Map<String, dynamic>? errors;

  ApiException(this.message, {this.statusCode, this.errors});

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  static const String _tokenKey = 'ozie_token';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  String? _token;

  /// Called when a logged-in request gets 401 (token expired/revoked).
  void Function()? onUnauthorized;

  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.baseUrl,
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 30),
      contentType: Headers.jsonContentType,
      headers: {
        'Accept': 'application/json',
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        'X-Requested-With': 'XMLHttpRequest',
      },
    ),
  );

  bool get hasToken => _token != null && _token!.isNotEmpty;

  Future<void> loadToken() async {
    _token = await _storage.read(key: _tokenKey);
  }

  Future<void> saveToken(String token) async {
    _token = token;
    await _storage.write(key: _tokenKey, value: token);
  }

  Future<void> clearToken() async {
    _token = null;
    await _storage.delete(key: _tokenKey);
  }

  Future<Map<String, dynamic>> get(String path) => _send('GET', path);

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
    bool auth = true,
  }) =>
      _send('POST', path, body: body, auth: auth);

  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    Map<String, dynamic>? body,
    bool auth = true,
  }) async {
    try {
      final res = await _dio.request<dynamic>(
        path,
        data: method == 'POST' ? (body ?? <String, dynamic>{}) : null,
        options: Options(
          method: method,
          headers: (auth && hasToken) ? {'Authorization': 'Bearer $_token'} : null,
        ),
      );
      final data = res.data;
      if (data is Map<String, dynamic>) return data;
      throw ApiException('Unexpected server response.');
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      final data = e.response?.data;

      if (code == 401 && auth && hasToken) {
        await clearToken();
        onUnauthorized?.call();
      }

      if (data is Map && data['message'] is String) {
        final errs = data['errors'];
        throw ApiException(
          data['message'] as String,
          statusCode: code,
          errors: errs is Map<String, dynamic> ? errs : null,
        );
      }

      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        throw ApiException('Network error. Check your internet connection.');
      }

      throw ApiException(
        'Server error${code != null ? ' ($code)' : ''}. Please try again.',
        statusCode: code,
      );
    }
  }
}
