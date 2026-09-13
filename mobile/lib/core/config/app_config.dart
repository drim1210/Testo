import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AppConfig {
  static const String _defaultUrl = 'http://192.168.101.10:8000';
  static String _baseUrl = const String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: _defaultUrl,
  );

  static const _storageKey = 'custom_api_base_url';
  static const _storage = FlutterSecureStorage();

  static void Function(String url)? onBaseUrlChanged;

  static String get apiBaseUrl => _baseUrl;
  static String get apiV1 => '$_baseUrl/api/v1';
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(minutes: 5);
  static const Duration pollInterval = Duration(seconds: 3);

  /// Load any custom server URL saved by user in a previous session
  static Future<void> loadSavedUrl() async {
    try {
      final saved = await _storage.read(key: _storageKey);
      if (saved != null && saved.trim().isNotEmpty) {
        await setBaseUrl(saved.trim(), persist: false);
      }
    } catch (_) {}
  }

  /// Update the active base URL dynamically
  static Future<void> setBaseUrl(String url, {bool persist = true}) async {
    var cleaned = url.trim();
    if (!cleaned.startsWith('http://') && !cleaned.startsWith('https://')) {
      cleaned = 'http://$cleaned';
    }
    if (cleaned.endsWith('/')) {
      cleaned = cleaned.substring(0, cleaned.length - 1);
    }
    _baseUrl = cleaned;
    onBaseUrlChanged?.call(apiV1);
    if (persist) {
      await _storage.write(key: _storageKey, value: cleaned);
    }
  }
}
