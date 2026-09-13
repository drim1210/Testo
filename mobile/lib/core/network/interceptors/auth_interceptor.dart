import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../api/api_service.dart';

/// Attaches JWT to every request. If no token exists yet,
/// runs anonymous device auth first (skipped for the auth call itself).
class AuthInterceptor extends Interceptor {
  final _storage = const FlutterSecureStorage();
  bool _authenticating = false;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final isAuthCall = options.path.contains('/auth/anonymous');
    var token = await _storage.read(key: AuthService.tokenKey);

    if ((token == null || token.isEmpty) && !isAuthCall && !_authenticating) {
      _authenticating = true;
      try {
        await AuthService().ensureAuthenticated();
      } catch (_) {
        // let the request go unauthenticated; server will return 401
      } finally {
        _authenticating = false;
        token = await _storage.read(key: AuthService.tokenKey);
      }
    }

    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}
