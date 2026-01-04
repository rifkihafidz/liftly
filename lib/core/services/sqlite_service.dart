import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';

class SQLiteService {
  static late Database _database;
  static bool _isInitialized = false;

  /// Log database operations
  static void _log(String operation, String message) {
    if (kDebugMode) {
      print('[SQLite] $operation: $message');
    }
  }

  /// Initialize SQLite database
  static Future<void> initDatabase() async {
    try {
      final databasesPath = await getDatabasesPath();
      final path = join(databasesPath, 'liftly.db');

      _log('INIT', 'Opening database at: $path');

      _database = await openDatabase(
        path,
        version: 6,
        onConfigure: (db) async {
          await db.execute('PRAGMA foreign_keys = ON');
        },
        onCreate: (Database db, int version) async {
          _log('INIT', 'Creating tables (version $version)');
          await _createTables(db);
        },
        onUpgrade: (Database db, int oldVersion, int newVersion) async {
          _log('INIT', 'Upgrading database from v$oldVersion to v$newVersion');
          if (oldVersion < 3) {
            await _createTables(db);
          }
          if (oldVersion < 4) {
            _log('INIT', 'Adding is_draft column to workouts table');
            try {
              final columns = await db.rawQuery('PRAGMA table_info(workouts)');
              final hasIsDraft = columns.any((c) => c['name'] == 'is_draft');
              if (!hasIsDraft) {
                await db.execute(
                  'ALTER TABLE workouts ADD COLUMN is_draft INTEGER DEFAULT 0',
                );
              }
            } catch (e) {
              _log('INIT', 'Error migrate is_draft: $e');
            }
          }
          if (oldVersion < 5) {
            _log(
              'INIT',
              'Adding is_template column to workout_exercises table',
            );
            try {
              final columns = await db.rawQuery(
                'PRAGMA table_info(workout_exercises)',
              );
              final hasIsTemplate = columns.any(
                (c) => c['name'] == 'is_template',
              );
              if (!hasIsTemplate) {
                await db.execute(
                  'ALTER TABLE workout_exercises ADD COLUMN is_template INTEGER DEFAULT 0',
                );
              }
            } catch (e) {
              _log('INIT', 'Error migrate is_template: $e');
            }
          }
          if (oldVersion < 6) {
            _log('INIT', 'Creating indexes for performance optimization');
            try {
              // Workouts indexes
              await db.execute(
                'CREATE INDEX IF NOT EXISTS idx_workouts_user_draft ON workouts(user_id, is_draft)',
              );
              await db.execute(
                'CREATE INDEX IF NOT EXISTS idx_workouts_date ON workouts(workout_date DESC)',
              );

              // Exercises indexes
              await db.execute(
                'CREATE INDEX IF NOT EXISTS idx_exercises_workout_id ON workout_exercises(workout_id)',
              );
              await db.execute(
                'CREATE INDEX IF NOT EXISTS idx_exercises_name ON workout_exercises(name)',
              );

              // Sets & Segments indexes
              await db.execute(
                'CREATE INDEX IF NOT EXISTS idx_sets_exercise_id ON workout_sets(exercise_id)',
              );
              await db.execute(
                'CREATE INDEX IF NOT EXISTS idx_segments_set_id ON set_segments(set_id)',
              );
            } catch (e) {
              _log('INIT', 'Error creating indexes: $e');
            }
          }
        },
      );

      _isInitialized = true;
      _log('INIT', 'Database initialized successfully');
    } catch (e) {
      _log('INIT', 'Database initialization failed: $e');
      rethrow;
    }
  }

  /// Create all required tables
  static Future<void> _createTables(Database db) async {
    // Preferences table for storing app settings
    await db.execute('''
      CREATE TABLE IF NOT EXISTS preferences (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        key TEXT UNIQUE NOT NULL,
        value TEXT NOT NULL,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Plans table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS plans (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        name TEXT NOT NULL,
        description TEXT,
        created_at DATETIME NOT NULL,
        updated_at DATETIME NOT NULL
      )
    ''');

    // Plan exercises table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS plan_exercises (
        id TEXT PRIMARY KEY,
        plan_id TEXT NOT NULL,
        name TEXT NOT NULL,
        exercise_order INTEGER NOT NULL,
        FOREIGN KEY (plan_id) REFERENCES plans(id) ON DELETE CASCADE
      )
    ''');

    // Workouts table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS workouts (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        plan_id TEXT,
        workout_date DATETIME NOT NULL,
        started_at DATETIME,
        ended_at DATETIME,
        created_at DATETIME NOT NULL,
        updated_at DATETIME NOT NULL,
        is_draft INTEGER DEFAULT 0
      )
    ''');

    // Workout exercises table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS workout_exercises (
        id TEXT PRIMARY KEY,
        workout_id TEXT NOT NULL,
        name TEXT NOT NULL,
        exercise_order INTEGER NOT NULL,
        skipped INTEGER NOT NULL DEFAULT 0,
        is_template INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (workout_id) REFERENCES workouts(id) ON DELETE CASCADE
      )
    ''');

    // Workout sets table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS workout_sets (
        id TEXT PRIMARY KEY,
        exercise_id TEXT NOT NULL,
        set_number INTEGER NOT NULL,
        FOREIGN KEY (exercise_id) REFERENCES workout_exercises(id) ON DELETE CASCADE
      )
    ''');

    // Set segments table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS set_segments (
        id TEXT PRIMARY KEY,
        set_id TEXT NOT NULL,
        weight REAL NOT NULL,
        reps_from INTEGER NOT NULL,
        reps_to INTEGER NOT NULL,
        segment_order INTEGER NOT NULL,
        notes TEXT,
        FOREIGN KEY (set_id) REFERENCES workout_sets(id) ON DELETE CASCADE
      )
    ''');
  }

  /// Check if SQLite is initialized
  static bool get isInitialized => _isInitialized;

  /// Format DateTime to ISO 8601 for correct database sorting
  static String formatDateTime(DateTime dateTime) {
    return dateTime.toIso8601String();
  }

  /// Parse DateTime from dd-MM-yyyy HH:mm:ss format or ISO 8601 format
  static DateTime parseDateTime(String dateTimeStr) {
    // Handle both formats: dd-MM-yyyy HH:mm:ss and ISO 8601 (2024-01-01T12:00:00.000)
    if (dateTimeStr.contains('T')) {
      // ISO 8601 format
      return DateTime.parse(dateTimeStr);
    } else {
      // dd-MM-yyyy HH:mm:ss format
      final parts = dateTimeStr.split(' ');
      if (parts.length < 2) {
        // Fallback: try to parse as ISO
        return DateTime.parse(dateTimeStr);
      }
      final dateParts = parts[0].split('-'); // dd-MM-yyyy
      final timeParts = parts[1].split(':'); // HH:mm:ss

      return DateTime(
        int.parse(dateParts[2]), // year
        int.parse(dateParts[1]), // month
        int.parse(dateParts[0]), // day
        int.parse(timeParts[0]), // hour
        int.parse(timeParts[1]), // minute
        int.parse(timeParts[2]), // second
      );
    }
  }

  /// Get database instance
  static Database get database => _database;

  /// Close database
  static Future<void> closeDatabase() async {
    await _database.close();
  }

  // ============= Preferences Methods =============

  /// Save preference
  static Future<void> savePreference(String key, String value) async {
    try {
      _log('INSERT', 'preferences: key=$key, value=$value');
      await _database.insert('preferences', {
        'key': key,
        'value': value,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      _log('INSERT', 'preferences: SUCCESS');
    } catch (e) {
      _log('INSERT', 'preferences: FAILED - $e');
    }
  }

  /// Get preference
  static Future<String?> getPreference(String key) async {
    try {
      _log('SELECT', 'preferences WHERE key=$key');
      final result = await _database.query(
        'preferences',
        where: 'key = ?',
        whereArgs: [key],
      );

      if (result.isNotEmpty) {
        _log('SELECT', 'preferences: Found 1 record');
        return result.first['value'] as String?;
      }
      _log('SELECT', 'preferences: No records found');
      return null;
    } catch (e) {
      _log('SELECT', 'preferences: FAILED - $e');
      return null;
    }
  }

  /// Delete preference
  static Future<void> deletePreference(String key) async {
    try {
      _log('DELETE', 'preferences WHERE key=$key');
      await _database.delete('preferences', where: 'key = ?', whereArgs: [key]);
      _log('DELETE', 'preferences: SUCCESS');
    } catch (e) {
      _log('DELETE', 'preferences: FAILED - $e');
    }
  }

  /// Clear all preferences
  static Future<void> clearAllPreferences() async {
    try {
      _log('DELETE', 'preferences: ALL');
      await _database.delete('preferences');
      _log('DELETE', 'preferences ALL: SUCCESS');
    } catch (e) {
      _log('DELETE', 'preferences ALL: FAILED - $e');
    }
  }
}
