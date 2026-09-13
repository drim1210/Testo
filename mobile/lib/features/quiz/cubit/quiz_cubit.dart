import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/api/api_service.dart';
import '../../../../data/datasources/local_cache.dart';
import '../../../../data/models/models.dart';

class QuizState extends Equatable {
  final bool isLoading;
  final bool isSubmitting;
  final bool isOffline;
  final String? error;
  final ExamDetail? exam;
  final String? sessionId;
  final int currentIndex;
  final Map<String, int> answers;
  final Set<String> bookmarks;

  const QuizState({
    this.isLoading = true,
    this.isSubmitting = false,
    this.isOffline = false,
    this.error,
    this.exam,
    this.sessionId,
    this.currentIndex = 0,
    this.answers = const {},
    this.bookmarks = const {},
  });

  Question? get currentQuestion {
    final questions = exam?.questions;
    if (questions == null || questions.isEmpty) return null;
    if (currentIndex < 0 || currentIndex >= questions.length) return null;
    return questions[currentIndex];
  }

  int? get currentAnswer =>
      currentQuestion == null ? null : answers[currentQuestion!.id];

  bool get isBookmarked =>
      currentQuestion != null && bookmarks.contains(currentQuestion!.id);

  int get answeredCount => answers.length;

  int get totalQuestions => exam?.questions.length ?? 0;

  bool get isLast => currentIndex >= totalQuestions - 1;

  QuizState copyWith({
    bool? isLoading,
    bool? isSubmitting,
    bool? isOffline,
    String? error,
    ExamDetail? exam,
    String? sessionId,
    int? currentIndex,
    Map<String, int>? answers,
    Set<String>? bookmarks,
    bool clearError = false,
  }) =>
      QuizState(
        isLoading: isLoading ?? this.isLoading,
        isSubmitting: isSubmitting ?? this.isSubmitting,
        isOffline: isOffline ?? this.isOffline,
        error: clearError ? null : (error ?? this.error),
        exam: exam ?? this.exam,
        sessionId: sessionId ?? this.sessionId,
        currentIndex: currentIndex ?? this.currentIndex,
        answers: answers ?? this.answers,
        bookmarks: bookmarks ?? this.bookmarks,
      );

  @override
  List<Object?> get props => [
        isLoading,
        isSubmitting,
        isOffline,
        error,
        exam,
        sessionId,
        currentIndex,
        answers,
        bookmarks,
      ];
}

class QuizCubit extends Cubit<QuizState> {
  QuizCubit({ApiService? api, LocalCache? cache})
      : _api = api ?? ApiService.instance,
        _cache = cache ?? LocalCache.instance,
        super(const QuizState());

  final ApiService _api;
  final LocalCache _cache;

  Future<void> load(String examId) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final exam = await _api.getExam(examId);
      await _cache.cacheExam(exam);
      final sessionId = await _api.startSession(examId);
      await _cache.cacheSessionId(examId, sessionId);
      emit(state.copyWith(
        isLoading: false,
        isOffline: false,
        exam: exam,
        sessionId: sessionId,
      ));
    } catch (e) {
      // Offline / crash recovery: fall back to the locally cached exam.
      final cached = await _cache.getCachedExam(examId);
      if (cached == null) {
        emit(state.copyWith(isLoading: false, error: extractErrorMessage(e)));
        return;
      }
      final sessionId = await _cache.getCachedSessionId(examId);
      final restored = <String, int>{};
      if (sessionId != null) {
        for (final a in await _cache.getUnsyncedAnswers(sessionId)) {
          restored[a.questionId] = a.selectedIdx;
        }
      }
      emit(state.copyWith(
        isLoading: false,
        isOffline: true,
        exam: cached,
        sessionId: sessionId,
        answers: restored,
      ));
    }
  }

  void selectAnswer(int idx) {
    final question = state.currentQuestion;
    final sessionId = state.sessionId;
    if (question == null || sessionId == null) return;

    final answers = Map<String, int>.from(state.answers)..[question.id] = idx;
    emit(state.copyWith(answers: answers));

    // Local-first: persist before syncing so answers survive a crash.
    unawaited(_persistAndSync(sessionId, question.id, idx));
  }

  Future<void> _persistAndSync(String sessionId, String questionId, int idx) async {
    await _cache.cacheAnswer(sessionId, questionId, idx);
    try {
      await _api.saveAnswer(sessionId, questionId, idx, null);
      await _cache.markAnswerSynced(sessionId, questionId);
    } catch (_) {
      // stays unsynced; retried on next sync pass or at submit time
    }
  }

  void toggleBookmark() {
    final question = state.currentQuestion;
    final sessionId = state.sessionId;
    if (question == null || sessionId == null) return;

    final bookmarks = Set<String>.from(state.bookmarks);
    final willBookmark = !bookmarks.contains(question.id);
    if (willBookmark) {
      bookmarks.add(question.id);
    } else {
      bookmarks.remove(question.id);
    }
    emit(state.copyWith(bookmarks: bookmarks));

    _api
        .toggleBookmark(sessionId, question.id, willBookmark)
        .catchError((_) {});
  }

  void goTo(int index) {
    if (state.exam == null) return;
    final clamped = index.clamp(0, state.totalQuestions - 1);
    emit(state.copyWith(currentIndex: clamped));
  }

  void next() => goTo(state.currentIndex + 1);

  void previous() => goTo(state.currentIndex - 1);

  Future<ExamResult?> submit() async {
    final sessionId = state.sessionId;
    if (sessionId == null) return null;
    emit(state.copyWith(isSubmitting: true));
    try {
      await _syncPendingAnswers(sessionId);
      final result = await _api.submitSession(sessionId);
      await _cache.clearSession(sessionId);
      emit(state.copyWith(isSubmitting: false));
      return result;
    } catch (e) {
      // Answers remain cached; user can retry when back online.
      emit(state.copyWith(isSubmitting: false, error: extractErrorMessage(e)));
      return null;
    }
  }

  /// Push any locally-cached answers that never reached the server.
  Future<void> _syncPendingAnswers(String sessionId) async {
    for (final a in await _cache.getUnsyncedAnswers(sessionId)) {
      await _api.saveAnswer(sessionId, a.questionId, a.selectedIdx, null);
      await _cache.markAnswerSynced(sessionId, a.questionId);
    }
  }
}
