class TopicResult {
  final String topic;
  final int total;
  final int correct;
  final double percentage;

  const TopicResult({
    required this.topic,
    required this.total,
    required this.correct,
    required this.percentage,
  });

  factory TopicResult.fromJson(Map<String, dynamic> json) => TopicResult(
        topic: json['topic'] as String,
        total: json['total'] as int,
        correct: json['correct'] as int,
        percentage: (json['percentage'] as num).toDouble(),
      );
}

class ExamResult {
  final String sessionId;
  final String examId;
  final String documentId;
  final double score;
  final int correctCount;
  final int totalCount;
  final double percentage;
  final int? timeSpent;
  final List<TopicResult> topicResults;
  final List<TopicResult> strongTopics;
  final List<TopicResult> weakTopics;

  const ExamResult({
    required this.sessionId,
    required this.examId,
    required this.documentId,
    required this.score,
    required this.correctCount,
    required this.totalCount,
    required this.percentage,
    this.timeSpent,
    required this.topicResults,
    required this.strongTopics,
    required this.weakTopics,
  });

  factory ExamResult.fromJson(Map<String, dynamic> json) => ExamResult(
        sessionId: json['session_id'] as String,
        examId: json['exam_id'] as String? ?? '',
        documentId: json['document_id'] as String? ?? '',
        score: (json['score'] as num).toDouble(),
        correctCount: json['correct_count'] as int,
        totalCount: json['total_count'] as int,
        percentage: (json['percentage'] as num).toDouble(),
        timeSpent: json['time_spent'] as int?,
        topicResults: (json['topic_results'] as List)
            .map((e) => TopicResult.fromJson(e as Map<String, dynamic>))
            .toList(),
        strongTopics: (json['strong_topics'] as List)
            .map((e) => TopicResult.fromJson(e as Map<String, dynamic>))
            .toList(),
        weakTopics: (json['weak_topics'] as List)
            .map((e) => TopicResult.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class ReviewAnswer {
  final String questionId;
  final String content;
  final List<String> options;
  final int? selectedIdx;
  final int correctIndex;
  final bool isCorrect;
  final bool isBookmarked;
  final String? explanation;
  final String? sourceRef;
  final String? topic;

  const ReviewAnswer({
    required this.questionId,
    required this.content,
    required this.options,
    this.selectedIdx,
    required this.correctIndex,
    required this.isCorrect,
    required this.isBookmarked,
    this.explanation,
    this.sourceRef,
    this.topic,
  });

  factory ReviewAnswer.fromJson(Map<String, dynamic> json) => ReviewAnswer(
        questionId: json['question_id'] as String,
        content: json['content'] as String,
        options: (json['options'] as List).cast<String>(),
        selectedIdx: json['selected_idx'] as int?,
        correctIndex: json['correct_index'] as int,
        isCorrect: json['is_correct'] as bool,
        isBookmarked: json['is_bookmarked'] as bool? ?? false,
        explanation: json['explanation'] as String?,
        sourceRef: json['source_ref'] as String?,
        topic: json['topic'] as String?,
      );
}

class ExamReview {
  final String sessionId;
  final List<ReviewAnswer> answers;

  const ExamReview({required this.sessionId, required this.answers});

  factory ExamReview.fromJson(Map<String, dynamic> json) => ExamReview(
        sessionId: json['session_id'] as String,
        answers: (json['answers'] as List)
            .map((e) => ReviewAnswer.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class SessionHistoryItem {
  final String sessionId;
  final String examId;
  final String? examTitle;
  final double score;
  final int correctCount;
  final int totalCount;
  final DateTime? completedAt;

  const SessionHistoryItem({
    required this.sessionId,
    required this.examId,
    this.examTitle,
    required this.score,
    required this.correctCount,
    required this.totalCount,
    this.completedAt,
  });

  factory SessionHistoryItem.fromJson(Map<String, dynamic> json) => SessionHistoryItem(
        sessionId: json['session_id'] as String,
        examId: json['exam_id'] as String,
        examTitle: json['exam_title'] as String?,
        score: (json['score'] as num).toDouble(),
        correctCount: json['correct_count'] as int,
        totalCount: json['total_count'] as int,
        completedAt: json['completed_at'] == null
            ? null
            : DateTime.tryParse(json['completed_at'] as String),
      );
}
