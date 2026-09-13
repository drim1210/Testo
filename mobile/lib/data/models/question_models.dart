class Question {
  final String id;
  final String content;
  final List<String> options;
  final String questionType;
  final String? topic;
  final String? difficulty;
  final int orderIndex;

  const Question({
    required this.id,
    required this.content,
    required this.options,
    required this.questionType,
    this.topic,
    this.difficulty,
    required this.orderIndex,
  });

  factory Question.fromJson(Map<String, dynamic> json) => Question(
        id: json['id'] as String,
        content: json['content'] as String,
        options: (json['options'] as List).cast<String>(),
        questionType: json['question_type'] as String? ?? 'mcq',
        topic: json['topic'] as String?,
        difficulty: json['difficulty'] as String?,
        orderIndex: json['order_index'] as int? ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'content': content,
        'options': options,
        'question_type': questionType,
        'topic': topic,
        'difficulty': difficulty,
        'order_index': orderIndex,
      };
}
