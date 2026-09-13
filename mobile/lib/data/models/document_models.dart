import 'models.dart';

class DocumentInfo {
  final String id;
  final String filename;
  final int? fileSize;
  final int? pageCount;
  final String status;

  const DocumentInfo({
    required this.id,
    required this.filename,
    this.fileSize,
    this.pageCount,
    required this.status,
  });

  factory DocumentInfo.fromJson(Map<String, dynamic> json) => DocumentInfo(
        id: json['id'] as String,
        filename: json['filename'] as String,
        fileSize: json['file_size'] as int?,
        pageCount: json['page_count'] as int?,
        status: json['status'] as String,
      );
}

class DocumentStatus {
  final String id;
  final String status;
  final String? errorMessage;

  const DocumentStatus({required this.id, required this.status, this.errorMessage});

  factory DocumentStatus.fromJson(Map<String, dynamic> json) => DocumentStatus(
        id: json['id'] as String,
        status: json['status'] as String,
        errorMessage: json['error_message'] as String?,
      );
}

class ExamStatus {
  final String id;
  final String status;
  final int progressStep;
  final String? progressMessage;
  final int totalSteps;
  final String? errorMessage;

  const ExamStatus({
    required this.id,
    required this.status,
    required this.progressStep,
    this.progressMessage,
    this.totalSteps = 6,
    this.errorMessage,
  });

  factory ExamStatus.fromJson(Map<String, dynamic> json) => ExamStatus(
        id: json['id'] as String,
        status: json['status'] as String,
        progressStep: json['progress_step'] as int? ?? 0,
        progressMessage: json['progress_message'] as String?,
        totalSteps: json['total_steps'] as int? ?? 6,
        errorMessage: json['error_message'] as String?,
      );
}

class ExamDetail {
  final String id;
  final String? title;
  final String status;
  final List<Question> questions;

  const ExamDetail({
    required this.id,
    this.title,
    required this.status,
    required this.questions,
  });

  factory ExamDetail.fromJson(Map<String, dynamic> json) => ExamDetail(
        id: json['id'] as String,
        title: json['title'] as String?,
        status: json['status'] as String,
        questions: (json['questions'] as List)
            .map((e) => Question.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'status': status,
        'questions': questions.map((q) => q.toJson()).toList(),
      };
}
