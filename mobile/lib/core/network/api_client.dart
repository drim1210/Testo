import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/app_config.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/error_interceptor.dart';

class ApiClient {
  static ApiClient? _instance;
  late final Dio _dio;

  ApiClient._() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConfig.apiV1,
      connectTimeout: AppConfig.connectTimeout,
      receiveTimeout: AppConfig.receiveTimeout,
      headers: {'Content-Type': 'application/json'},
    ));
    AppConfig.onBaseUrlChanged = (newUrl) {
      _dio.options.baseUrl = newUrl;
    };
    _dio.interceptors.addAll([
      AuthInterceptor(),
      ErrorInterceptor(),
      // Release builds must never log request bodies or Authorization headers.
      if (kDebugMode)
        LogInterceptor(
          requestBody: false,
          requestHeader: false,
          responseHeader: false,
        ),
    ]);
  }

  factory ApiClient() => _instance ??= ApiClient._();

  Dio get dio => _dio;
}
