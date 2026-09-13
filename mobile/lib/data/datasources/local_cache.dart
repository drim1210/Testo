import 'dart:convert';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:sqflite_common/sqlite_api.dart';

import '../../data/models/models.dart';

/// Locally cached answer waiting to be synced to the backend.
class CachedAnswer {
  final String questionId;
  final int selectedIdx;

  const CachedAnswer({required this.questionId, required this.selectedIdx});
}

/// Offline cache for exam questions and in-progress answers (crash recovery).
class LocalCache {
  LocalCache({DatabaseFactory? databaseFactory, String? path})
      : _factory = databaseFactory,
        _path = path;

  static final LocalCache instance = LocalCache();

  final DatabaseFactory? _factory;
  final String? _path;
  Database? _db;

  Future<Database> get _database async {
    final existing = _db;
    if (existing != null) return existing;

    final factory = _factory ?? sqflite.databaseFactory;
    final path = _path ??
        p.join(await sqflite.getDatabasesPath(), 'testo_cache.db');

    _db = await factory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, _) async {
          await db.execute('''
            CREATE TABLE exams (
              exam_id TEXT PRIMARY KEY,
              json TEXT NOT NULL,
              cached_at INTEGER NOT NULL
            )
          ''');
          await db.execute('''
            CREATE TABLE cached_answers (
              session_id TEXT NOT NULL,
              question_id TEXT NOT NULL,
              selected_idx INTEGER NOT NULL,
              synced INTEGER NOT NULL DEFAULT 0,
              PRIMARY KEY (session_id, question_id)
            )
          ''');
          await db.execute('''
            CREATE TABLE kv (
              key TEXT PRIMARY KEY,
              value TEXT NOT NULL
            )
          ''');
        },
      ),
    );
    return _db!;
  }

  Future<void> cacheExam(ExamDetail exam) async {
    final db = await _database;
    await db.insert('exams', {
      'exam_id': exam.id,
      'json': jsonEncode(exam.toJson()),
      'cached_at': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<ExamDetail?> getCachedExam(String examId) async {
    final db = await _database;
    final rows = await db.query('exams', where: 'exam_id = ?', whereArgs: [examId], limit: 1);
    if (rows.isEmpty) return null;
    return ExamDetail.fromJson(
        jsonDecode(rows.first['json'] as String) as Map<String, dynamic>);
  }

  /// Store session id associated with a local in-progress attempt.
  Future<void> cacheSessionId(String examId, String sessionId) async {
    final db = await _database;
    await db.insert('kv', {'key': 'session:$examId', 'value': sessionId},
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<String?> getCachedSessionId(String examId) async {
    final db = await _database;
    final rows = await db.query('kv', where: 'key = ?', whereArgs: ['session:$examId'], limit: 1);
    return rows.isEmpty ? null : rows.first['value'] as String;
  }

  Future<void> cacheAnswer(String sessionId, String questionId, int selectedIdx) async {
    final db = await _database;
    await db.insert('cached_answers', {
      'session_id': sessionId,
      'question_id': questionId,
      'selected_idx': selectedIdx,
      'synced': 0,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> markAnswerSynced(String sessionId, String questionId) async {
    final db = await _database;
    await db.update(
      'cached_answers',
      {'synced': 1},
      where: 'session_id = ? AND question_id = ?',
      whereArgs: [sessionId, questionId],
    );
  }

  Future<List<CachedAnswer>> getUnsyncedAnswers(String sessionId) async {
    final db = await _database;
    final rows = await db.query(
      'cached_answers',
      where: 'session_id = ? AND synced = 0',
      whereArgs: [sessionId],
    );
    return rows
        .map((r) => CachedAnswer(
              questionId: r['question_id'] as String,
              selectedIdx: r['selected_idx'] as int,
            ))
        .toList();
  }

  Future<void> clearSession(String sessionId) async {
    final db = await _database;
    await db.delete('cached_answers', where: 'session_id = ?', whereArgs: [sessionId]);
  }

  Future<void> close() async {
    final db = _db;
    _db = null;
    if (db != null) await db.close();
  }
}
