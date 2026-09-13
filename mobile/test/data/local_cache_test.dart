import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:testo/data/datasources/local_cache.dart';
import 'package:testo/data/models/models.dart';

void main() {
  late LocalCache cache;
  late Directory tmpDir;

  setUp(() {
    sqfliteFfiInit();
    // The ffi in-memory database is shared per-isolate, so use a unique file.
    tmpDir = Directory.systemTemp.createTempSync('testo_cache_test');
    cache = LocalCache(
      databaseFactory: databaseFactoryFfi,
      path: '${tmpDir.path}\\test.db',
    );
  });

  tearDown(() async {
    await cache.close();
    tmpDir.deleteSync(recursive: true);
  });

  ExamDetail sampleExam() => const ExamDetail(
        id: 'exam-1',
        title: 'Biology 101',
        status: 'ready',
        questions: [
          Question(
            id: 'q1',
            content: 'What is photosynthesis?',
            options: ['A', 'B', 'C', 'D'],
            questionType: 'mcq',
            topic: 'Plants',
            difficulty: 'easy',
            orderIndex: 0,
          ),
          Question(
            id: 'q2',
            content: 'What powers the Calvin cycle?',
            options: ['A', 'B', 'C', 'D'],
            questionType: 'mcq',
            topic: 'Plants',
            difficulty: 'medium',
            orderIndex: 1,
          ),
        ],
      );

  test('round-trips exam through cache', () async {
    await cache.cacheExam(sampleExam());
    final cached = await cache.getCachedExam('exam-1');
    expect(cached, isNotNull);
    expect(cached!.title, 'Biology 101');
    expect(cached.questions.length, 2);
    expect(cached.questions.first.options, ['A', 'B', 'C', 'D']);
  });

  test('returns null for unknown exam', () async {
    expect(await cache.getCachedExam('missing'), isNull);
  });

  test('re-caching same exam replaces it', () async {
    await cache.cacheExam(sampleExam());
    const trimmed = ExamDetail(
      id: 'exam-1',
      title: 'Updated',
      status: 'ready',
      questions: [],
    );
    await cache.cacheExam(trimmed);
    final cached = await cache.getCachedExam('exam-1');
    expect(cached!.title, 'Updated');
    expect(cached.questions, isEmpty);
  });

  test('answers start unsynced and mark as synced', () async {
    await cache.cacheAnswer('s1', 'q1', 2);
    await cache.cacheAnswer('s1', 'q2', 0);

    var unsynced = await cache.getUnsyncedAnswers('s1');
    expect(unsynced.length, 2);

    await cache.markAnswerSynced('s1', 'q1');
    unsynced = await cache.getUnsyncedAnswers('s1');
    expect(unsynced.map((a) => a.questionId), ['q2']);
  });

  test('re-selecting an answer replaces the cached value', () async {
    await cache.cacheAnswer('s1', 'q1', 2);
    await cache.cacheAnswer('s1', 'q1', 3);
    final unsynced = await cache.getUnsyncedAnswers('s1');
    expect(unsynced.single.selectedIdx, 3);
  });

  test('clearSession removes all cached answers', () async {
    await cache.cacheAnswer('s1', 'q1', 0);
    await cache.cacheAnswer('s1', 'q2', 1);
    await cache.clearSession('s1');
    expect(await cache.getUnsyncedAnswers('s1'), isEmpty);
  });

  test('session id is cached per exam', () async {
    expect(await cache.getCachedSessionId('exam-1'), isNull);
    await cache.cacheSessionId('exam-1', 'session-abc');
    expect(await cache.getCachedSessionId('exam-1'), 'session-abc');
  });
}
