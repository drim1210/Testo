import 'package:dio/dio.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;
  const ApiException({required this.statusCode, required this.message});

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final response = err.response;
    if (response != null) {
      final detail = response.data is Map
          ? response.data['detail'] ?? 'Unknown error'
          : 'Unknown error';
      handler.reject(DioException(
        requestOptions: err.requestOptions,
        error: ApiException(statusCode: response.statusCode ?? 0, message: detail.toString()),
        type: err.type,
        response: response,
      ));
    } else {
      handler.reject(DioException(
        requestOptions: err.requestOptions,
        error: const ApiException(
          statusCode: 0,
          message: 'Network error: cannot reach server',
        ),
        type: DioExceptionType.unknown,
      ));
    }
  }
}
