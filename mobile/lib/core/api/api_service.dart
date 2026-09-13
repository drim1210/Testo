import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart' show basename;
import 'package:uuid/uuid.dart';

import '../../data/models/models.dart';
import '../network/api_client.dart';
import '../network/interceptors/error_interceptor.dart';

/// Extract a user-friendly message from any Dio error.
String extractErrorMessage(Object error) {
  if (error is DioException) {
    final apiError = error.error;
    if (apiError is ApiException) return apiError.message;
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return 'Server is taking too long. Please try again.';
    }
    if (error.type == DioExceptionType.connectionError) {
      return 'Cannot reach server. Check your connection.';
    }
  }
  return 'Something went wrong. Please try again.';
}

/// Handles anonymous device auth and token persistence.
class AuthService {
  static const tokenKey = 'access_token';
  static const deviceIdKey = 'device_id';
  static const storage = FlutterSecureStorage();

  Future<void> ensureAuthenticated() async {
    final token = await storage.read(key: tokenKey);
    if (token != null && token.isNotEmpty) return;

    var deviceId = await storage.read(key: deviceIdKey);
    if (deviceId == null) {
      deviceId = const Uuid().v4();
      await storage.write(key: deviceIdKey, value: deviceId);
    }

    final response = await ApiClient().dio.post(
      '/auth/anonymous',
      data: {'device_id': deviceId},
    );
    final accessToken = response.data['access_token'] as String;
    await storage.write(key: tokenKey, value: accessToken);
  }

  Future<void> logout() async {
    await storage.delete(key: tokenKey);
  }
}

/// Typed API wrapper over all backend endpoints used by the app.
class ApiService {
  ApiService._();
  static final ApiService instance = ApiService._();

  final auth = AuthService();

  Dio get _dio => ApiClient().dio;

  Future<Map<String, dynamic>> getOverview() async {
    await auth.ensureAuthenticated();
    final resp = await _dio.get('/stats/overview');
    return resp.data as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> getTopicStats() async {
    await auth.ensureAuthenticated();
    final resp = await _dio.get('/stats/topics');
    return (resp.data as List).cast<Map<String, dynamic>>();
  }

  Future<DocumentInfo> uploadDocument(
    File file, {
    void Function(double progress)? onProgress,
  }) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(file.path, filename: basename(file.path)),
    });
    final response = await _dio.post(
      '/documents/upload',
      data: formData,
      onSendProgress: (sent, total) {
        if (total > 0) onProgress?.call(sent / total);
      },
      options: Options(contentType: 'multipart/form-data'),
    );
    return DocumentInfo.fromJson(response.data as Map<String, dynamic>);
  }

  Future<DocumentStatus> getDocumentStatus(String docId) async {
    final response = await _dio.get('/documents/$docId/status');
    return DocumentStatus.fromJson(response.data as Map<String, dynamic>);
  }

  Future<String> createExam({
    required String documentId,
    required int numQuestions,
    required String difficulty,
    required String questionType,
    required bool focusImportant,
  }) async {
    final response = await _dio.post('/exams/', data: {
      'document_id': documentId,
      'config': {
        'num_questions': numQuestions,
        'difficulty': difficulty,
        'question_type': questionType,
        'focus_important': focusImportant,
      },
    });
    return response.data['exam_id'] as String;
  }

  Future<ExamStatus> getExamStatus(String examId) async {
    final response = await _dio.get('/exams/$examId/status');
    return ExamStatus.fromJson(response.data as Map<String, dynamic>);
  }

  Future<ExamDetail> getExam(String examId) async {
    final response = await _dio.get('/exams/$examId');
    return ExamDetail.fromJson(response.data as Map<String, dynamic>);
  }

  Future<String> startSession(String examId) async {
    final response = await _dio.post('/sessions/$examId/start');
    return response.data['session_id'] as String;
  }

  Future<void> saveAnswer(
    String sessionId,
    String questionId,
    int selectedIdx,
    int? timeSpent,
  ) async {
    await _dio.patch('/sessions/$sessionId/answer', data: {
      'question_id': questionId,
      'selected_idx': selectedIdx,
      'time_spent': timeSpent,
    });
  }

  Future<void> toggleBookmark(
    String sessionId,
    String questionId,
    bool isBookmarked,
  ) async {
    await _dio.patch('/sessions/$sessionId/bookmark', data: {
      'question_id': questionId,
      'is_bookmarked': isBookmarked,
    });
  }

  Future<ExamResult> submitSession(String sessionId) async {
    final response = await _dio.post('/sessions/$sessionId/submit');
    return ExamResult.fromJson(response.data as Map<String, dynamic>);
  }

  Future<ExamResult> getResult(String sessionId) async {
    final response = await _dio.get('/sessions/$sessionId/result');
    return ExamResult.fromJson(response.data as Map<String, dynamic>);
  }

  Future<ExamReview> getReview(String sessionId) async {
    final response = await _dio.get('/sessions/$sessionId/review');
    return ExamReview.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<SessionHistoryItem>> getHistory() async {
    final response = await _dio.get('/sessions/');
    return (response.data as List)
        .map((e) => SessionHistoryItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<String> generatePractice({
    required String documentId,
    int numQuestions = 10,
  }) async {
    final response = await _dio.post('/practice/generate', data: {
      'document_id': documentId,
      'num_questions': numQuestions,
    });
    return response.data['exam_id'] as String;
  }
}
