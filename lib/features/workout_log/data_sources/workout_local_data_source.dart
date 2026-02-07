import 'package:sqflite/sqflite.dart';
import 'package:flutter/foundation.dart';
import 'package:liftly/core/models/workout_session.dart';
import 'package:liftly/core/services/sqlite_service.dart';
import 'package:liftly/features/stats/bloc/stats_state.dart';

class WorkoutLocalDataSource {
  /// Log database operations
  static void _log(String operation, String message) {
    if (kDebugMode) {
      print('[WorkoutDB] $operation: $message');
    }
  }

  /// Create a new workout with exercises, sets, and segments
  Future<WorkoutSession> createWorkout(WorkoutSession workout) async {
    try {
      _log(
        'CREATE',
        'Workout id=${workout.id}, userId=${workout.userId}, exercises=${workout.exercises.length}',
      );
      final database = SQLiteService.database;

      // Insert workout
      _log('INSERT', 'workouts table: id=${workout.id}');
      await database.insert('workouts', {
        'id': workout.id,
        'user_id': workout.userId,
        'plan_id': workout.planId,
        'workout_date': SQLiteService.formatDateTime(workout.workoutDate),
        'started_at': workout.startedAt != null
            ? SQLiteService.formatDateTime(workout.startedAt!)
            : null,
        'ended_at': workout.endedAt != null
            ? SQLiteService.formatDateTime(workout.endedAt!)
            : null,
        'created_at': SQLiteService.formatDateTime(workout.createdAt),
        'updated_at': SQLiteService.formatDateTime(workout.updatedAt),
        'is_draft': workout.isDraft ? 1 : 0,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      _log('INSERT', 'workouts: SUCCESS');

      // Insert exercises with sets and segments
      for (final exercise in workout.exercises) {
        _log(
          'INSERT',
          'workout_exercises: id=${exercise.id}, name=${exercise.name}',
        );
        await database.insert('workout_exercises', {
          'id': exercise.id,
          'workout_id': workout.id,
          'name': exercise.name,
          'exercise_order': exercise.order,
          'skipped': exercise.skipped ? 1 : 0,
          'is_template': exercise.isTemplate ? 1 : 0,
        }, conflictAlgorithm: ConflictAlgorithm.replace);

        // Insert sets and segments for this exercise
        for (final set in exercise.sets) {
          _log(
            'INSERT',
            'workout_sets: id=${set.id}, setNumber=${set.setNumber}',
          );
          await database.insert('workout_sets', {
            'id': set.id,
            'exercise_id': exercise.id,
            'set_number': set.setNumber,
          }, conflictAlgorithm: ConflictAlgorithm.replace);

          // Insert segments for this set
          for (final segment in set.segments) {
            _log(
              'INSERT',
              'set_segments: id=${segment.id}, weight=${segment.weight}',
            );
            await database.insert('set_segments', {
              'id': segment.id,
              'set_id': set.id,
              'weight': segment.weight,
              'reps_from': segment.repsFrom,
              'reps_to': segment.repsTo,
              'segment_order': segment.segmentOrder,
              'notes': segment.notes,
            }, conflictAlgorithm: ConflictAlgorithm.replace);
          }
        }
      }

      _log('CREATE', 'Workout creation SUCCESSFUL');
      return workout;
    } catch (e) {
      _log('CREATE', 'FAILED - $e');
      rethrow;
    }
  }

  /// Get all workouts for a specific user
  Future<List<WorkoutSession>> getWorkouts(
    String userId, {
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      _log(
        'SELECT_OPTIMIZED',
        'workouts JOIN exercises JOIN sets JOIN segments WHERE userId=$userId',
      );
      final database = SQLiteService.database;

      // 1. Get the workout IDs first to apply limit correctly
      final workoutIdsResult = await database.query(
        'workouts',
        columns: ['id'],
        where: 'user_id = ? AND is_draft = 0',
        whereArgs: [userId],
        orderBy: 'workout_date DESC',
        limit: limit > 0 ? limit : null,
        offset: offset,
      );

      if (workoutIdsResult.isEmpty) return [];
      final workoutIds = workoutIdsResult
          .map((w) => w['id'] as String)
          .toList();
      final placeholders = List.filled(workoutIds.length, '?').join(',');

      // 2. Fetch EVERYTHING in one big joined query
      // We join all related tables to get all data at once
      final bigQuery = await database.rawQuery('''
        SELECT 
          w.*, 
          p.name as plan_name,
          we.id as ex_id, we.name as ex_name, we.exercise_order as ex_order, we.skipped as ex_skipped, we.is_template as ex_is_template,
          ws.id as set_id, ws.set_number as set_num,
          ss.id as seg_id, ss.weight as seg_weight, ss.reps_from as seg_reps_f, ss.reps_to as seg_reps_t, ss.segment_order as seg_order, ss.notes as seg_notes
        FROM workouts w
        LEFT JOIN plans p ON w.plan_id = p.id
        LEFT JOIN workout_exercises we ON w.id = we.workout_id
        LEFT JOIN workout_sets ws ON we.id = ws.exercise_id
        LEFT JOIN set_segments ss ON ws.id = ss.set_id
        WHERE w.id IN ($placeholders)
        ORDER BY w.workout_date DESC, we.exercise_order ASC, ws.set_number ASC, ss.segment_order ASC
      ''', workoutIds);

      // 3. Process the flat result into objects
      final Map<String, WorkoutSession> workoutMap = {};
      final Map<String, SessionExercise> exerciseMap = {};
      final Map<String, ExerciseSet> setMap = {};

      for (final row in bigQuery) {
        final workoutId = row['id'] as String;

        // Build WorkoutSession if not exists
        if (!workoutMap.containsKey(workoutId)) {
          workoutMap[workoutId] = WorkoutSession(
            id: workoutId,
            userId: row['user_id'] as String,
            planId: row['plan_id'] as String?,
            planName: row['plan_name'] as String?,
            workoutDate: SQLiteService.parseDateTime(
              row['workout_date'] as String,
            ),
            startedAt: row['started_at'] != null
                ? SQLiteService.parseDateTime(row['started_at'] as String)
                : null,
            endedAt: row['ended_at'] != null
                ? SQLiteService.parseDateTime(row['ended_at'] as String)
                : null,
            exercises: [],
            createdAt: SQLiteService.parseDateTime(row['created_at'] as String),
            updatedAt: SQLiteService.parseDateTime(row['updated_at'] as String),
            isDraft: (row['is_draft'] as int?) == 1,
          );
        }

        // Build Exercise if not exists
        final exId = row['ex_id'] as String?;
        if (exId != null) {
          if (!exerciseMap.containsKey(exId)) {
            final exercise = SessionExercise(
              id: exId,
              name: row['ex_name'] as String,
              order: row['ex_order'] as int,
              sets: [],
              skipped: (row['ex_skipped'] as int) == 1,
              isTemplate: (row['ex_is_template'] as int? ?? 0) == 1,
            );
            exerciseMap[exId] = exercise;
            workoutMap[workoutId]!.exercises.add(exercise);
          }

          // Build Set if not exists
          final setId = row['set_id'] as String?;
          if (setId != null) {
            if (!setMap.containsKey(setId)) {
              final workoutSet = ExerciseSet(
                id: setId,
                setNumber: row['set_num'] as int,
                segments: [],
              );
              setMap[setId] = workoutSet;
              exerciseMap[exId]!.sets.add(workoutSet);
            }

            // Build Segment
            final segId = row['seg_id'] as String?;
            if (segId != null) {
              final segment = SetSegment(
                id: segId,
                weight: (row['seg_weight'] as num).toDouble(),
                repsFrom: row['seg_reps_f'] as int,
                repsTo: row['seg_reps_t'] as int,
                segmentOrder: row['seg_order'] as int,
                notes: row['seg_notes'] as String? ?? '',
              );
              setMap[setId]!.segments.add(segment);
            }
          }
        }
      }

      // Preserve original order from workoutIds
      return workoutIds.map((id) => workoutMap[id]!).toList();
    } catch (e) {
      _log('SELECT', 'workouts: FAILED - $e');
      rethrow;
    }
  }

  /// Get a single workout by ID with all related exercises, sets, and segments
  Future<WorkoutSession> getWorkout(String workoutId) async {
    _log('SELECT', 'workout id=$workoutId');
    return _buildWorkoutFromRows(workoutId);
  }

  /// Get the latest draft workout for a user
  Future<WorkoutSession?> getDraftWorkout(String userId) async {
    try {
      _log('SELECT', 'Draft workout for userId=$userId');
      final database = SQLiteService.database;

      final result = await database.query(
        'workouts',
        where: 'user_id = ? AND is_draft = 1',
        whereArgs: [userId],
        orderBy: 'updated_at DESC',
        limit: 1,
      );

      if (result.isEmpty) return null;

      final draftId = result.first['id'] as String;
      return _buildWorkoutFromRows(draftId);
    } catch (e) {
      _log('SELECT', 'getDraftWorkout: FAILED - $e');
      return null;
    }
  }

  /// Build complete workout object from database rows
  Future<WorkoutSession> _buildWorkoutFromRows(String workoutId) async {
    try {
      final database = SQLiteService.database;

      // Get workout
      _log('SELECT', 'workouts id=$workoutId');
      // Get workout with plan name
      _log('SELECT', 'workouts id=$workoutId');
      final workoutRows = await database.rawQuery(
        '''
        SELECT w.*, p.name as plan_name 
        FROM workouts w
        LEFT JOIN plans p ON w.plan_id = p.id
        WHERE w.id = ?
      ''',
        [workoutId],
      );

      if (workoutRows.isEmpty) {
        throw Exception('Workout not found');
      }

      final workoutRow = workoutRows.first;
      _log('SELECT', 'workouts: Found 1 record');

      // Get exercises
      _log('SELECT', 'workout_exercises WHERE workoutId=$workoutId');
      final exerciseRows = await database.query(
        'workout_exercises',
        where: 'workout_id = ?',
        whereArgs: [workoutId],
        orderBy: 'exercise_order ASC',
      );

      _log('SELECT', 'workout_exercises: Found ${exerciseRows.length} records');
      // Log exercise IDs for debugging
      if (exerciseRows.isNotEmpty) {
        for (int i = 0; i < exerciseRows.length; i++) {
          final row = exerciseRows[i];
          _log(
            'DEBUG',
            'Exercise row $i: id=${row['id']}, name=${row['name']}, workoutId=${row['workout_id']}',
          );
        }
      }
      final List<SessionExercise> exercises = [];

      for (final exerciseRow in exerciseRows) {
        final exerciseId = exerciseRow['id'] as String;

        // Get sets for this exercise
        _log('SELECT', 'workout_sets WHERE exerciseId=$exerciseId');
        final setRows = await database.query(
          'workout_sets',
          where: 'exercise_id = ?',
          whereArgs: [exerciseId],
          orderBy: 'set_number ASC',
        );

        _log(
          'SELECT',
          'workout_sets: Found ${setRows.length} records for exercise $exerciseId',
        );
        // Log set IDs for debugging - show each set row
        if (setRows.isNotEmpty) {
          final setIds = setRows.map((s) => s['id']).join(',');
          _log('DEBUG', 'Exercise $exerciseId has set IDs: $setIds');
          for (int i = 0; i < setRows.length; i++) {
            final row = setRows[i];
            _log(
              'DEBUG',
              'Row $i: id=${row['id']}, setNumber=${row['set_number']}, exerciseId=${row['exercise_id']}',
            );
          }
        }
        final List<ExerciseSet> sets = [];

        for (final setRow in setRows) {
          final setId = setRow['id'] as String;

          // Get segments for this set
          _log('SELECT', 'set_segments WHERE setId=$setId');
          final segmentRows = await database.query(
            'set_segments',
            where: 'set_id = ?',
            whereArgs: [setId],
            orderBy: 'segment_order ASC',
          );

          _log('SELECT', 'set_segments: Found ${segmentRows.length} records');
          // Log segment IDs for debugging
          if (segmentRows.isNotEmpty) {
            final segIds = segmentRows.map((s) => s['id']).join(',');
            _log('DEBUG', 'Set $setId has segments: $segIds');
          }
          final List<SetSegment> segments = segmentRows
              .map(
                (seg) => SetSegment(
                  id: seg['id'] as String,
                  weight: (seg['weight'] as num).toDouble(),
                  repsFrom: seg['reps_from'] as int,
                  repsTo: seg['reps_to'] as int,
                  segmentOrder: seg['segment_order'] as int,
                  notes: seg['notes'] as String? ?? '',
                ),
              )
              .toList();

          sets.add(
            ExerciseSet(
              id: setId,
              setNumber: setRow['set_number'] as int,
              segments: segments,
            ),
          );
          _log(
            'DEBUG',
            'Added set $setId with ${segments.length} segments to exercise',
          );
        }

        exercises.add(
          SessionExercise(
            id: exerciseId,
            name: exerciseRow['name'] as String,
            order: exerciseRow['exercise_order'] as int,
            sets: sets,
            skipped: (exerciseRow['skipped'] as int) == 1,
            isTemplate: (exerciseRow['is_template'] as int? ?? 0) == 1,
          ),
        );
        _log('DEBUG', 'Added exercise $exerciseId with ${sets.length} sets');
      }

      final result = WorkoutSession(
        id: workoutRow['id'] as String,
        userId: workoutRow['user_id'] as String,
        planId: workoutRow['plan_id'] as String?,
        planName: workoutRow['plan_name'] as String?,
        workoutDate: SQLiteService.parseDateTime(
          workoutRow['workout_date'] as String,
        ),
        startedAt: workoutRow['started_at'] != null
            ? SQLiteService.parseDateTime(workoutRow['started_at'] as String)
            : null,
        endedAt: workoutRow['ended_at'] != null
            ? SQLiteService.parseDateTime(workoutRow['ended_at'] as String)
            : null,
        exercises: exercises,
        createdAt: SQLiteService.parseDateTime(
          workoutRow['created_at'] as String,
        ),
        updatedAt: SQLiteService.parseDateTime(
          workoutRow['updated_at'] as String,
        ),
        isDraft: (workoutRow['is_draft'] as int?) == 1,
      );

      // Log the final result
      int totalSets = 0;
      for (final ex in result.exercises) {
        totalSets += ex.sets.length;
      }
      _log(
        'SELECT',
        'Built workout ${result.id}: ${result.exercises.length} exercises, $totalSets total sets',
      );

      return result;
    } catch (e) {
      _log('SELECT', 'Build workout: FAILED - $e');
      rethrow;
    }
  }

  /// Update an existing workout
  Future<WorkoutSession> updateWorkout(WorkoutSession workout) async {
    final database = SQLiteService.database;

    // Update workout basic info
    await database.update(
      'workouts',
      {
        'plan_id': workout.planId,
        'workout_date': SQLiteService.formatDateTime(workout.workoutDate),
        'started_at': workout.startedAt != null
            ? SQLiteService.formatDateTime(workout.startedAt!)
            : null,
        'ended_at': workout.endedAt != null
            ? SQLiteService.formatDateTime(workout.endedAt!)
            : null,
        'updated_at': SQLiteService.formatDateTime(workout.updatedAt),
        'is_draft': workout.isDraft ? 1 : 0,
      },
      where: 'id = ?',
      whereArgs: [workout.id],
    );

    // Explicitly delete everything related to this workout to ensure no orphans
    // 1. Get all exercise IDs
    final oldExercises = await database.query(
      'workout_exercises',
      columns: ['id'],
      where: 'workout_id = ?',
      whereArgs: [workout.id],
    );
    final oldExerciseIds = oldExercises.map((e) => e['id'] as String).toList();

    if (oldExerciseIds.isNotEmpty) {
      // 2. Get all set IDs
      final placeholders = List.filled(oldExerciseIds.length, '?').join(',');
      final oldSets = await database.query(
        'workout_sets',
        columns: ['id'],
        where: 'exercise_id IN ($placeholders)',
        whereArgs: oldExerciseIds,
      );
      final oldSetIds = oldSets.map((s) => s['id'] as String).toList();

      // 3. Delete segments
      if (oldSetIds.isNotEmpty) {
        final setPlaceholders = List.filled(oldSetIds.length, '?').join(',');
        await database.delete(
          'set_segments',
          where: 'set_id IN ($setPlaceholders)',
          whereArgs: oldSetIds,
        );
      }

      // 4. Delete sets
      await database.delete(
        'workout_sets',
        where: 'exercise_id IN ($placeholders)',
        whereArgs: oldExerciseIds,
      );
    }

    // 5. Delete exercises
    await database.delete(
      'workout_exercises',
      where: 'workout_id = ?',
      whereArgs: [workout.id],
    );

    // Re-insert all exercises with their sets and segments
    for (final exercise in workout.exercises) {
      await database.insert('workout_exercises', {
        'id': exercise.id,
        'workout_id': workout.id,
        'name': exercise.name,
        'exercise_order': exercise.order,
        'skipped': exercise.skipped ? 1 : 0,
        'is_template': exercise.isTemplate ? 1 : 0,
      }, conflictAlgorithm: ConflictAlgorithm.replace);

      // If exercise is skipped and has no sets, preserve existing sets from database
      // NOTE: Since we just deleted everything, we can't preserve "existing sets" from the DB anymore.
      // We must rely on the incoming `workout` object having the sets if they are needed.
      // If the `workout` object doesn't have sets for skipped exercises, we lose them.
      // User requirement check: "Skipped exercises should keep their sets".
      // The `WorkoutEditPage` logic seems to clear sets when skipping?
      // "sets.clear(); sets.add(...)" in onSkipToggle.
      // So the UI logic handles "default sets".
      // If we are recovering a session, the bloc/repo should have loaded the sets.
      // So here we just save what we are given.

      for (final set in exercise.sets) {
        await database.insert('workout_sets', {
          'id': set.id,
          'exercise_id': exercise.id,
          'set_number': set.setNumber,
        }, conflictAlgorithm: ConflictAlgorithm.replace);

        for (final segment in set.segments) {
          await database.insert('set_segments', {
            'id': segment.id,
            'set_id': set.id,
            'weight': segment.weight,
            'reps_from': segment.repsFrom,
            'reps_to': segment.repsTo,
            'segment_order': segment.segmentOrder,
            'notes': segment.notes,
          }, conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }
    }

    // Fetch and return the updated workout from database to ensure fresh data
    try {
      // Query the updated workout directly from database using workout ID
      final workoutResult = await database.query(
        'workouts',
        where: 'id = ?',
        whereArgs: [workout.id],
      );

      if (workoutResult.isEmpty) {
        throw Exception('Workout not found after update');
      }

      final workoutRow = workoutResult.first;

      // Build exercises list from database
      final exercisesResult = await database.query(
        'workout_exercises',
        where: 'workout_id = ?',
        whereArgs: [workout.id],
        orderBy: 'exercise_order ASC',
      );

      final exercises = <SessionExercise>[];

      for (final exRow in exercisesResult) {
        final exerciseId = exRow['id'].toString();
        final sets = <ExerciseSet>[];

        final setsResult = await database.query(
          'workout_sets',
          where: 'exercise_id = ?',
          whereArgs: [exerciseId],
          orderBy: 'set_number ASC',
        );

        for (final setRow in setsResult) {
          final setId = setRow['id'].toString();
          final segments = <SetSegment>[];

          final segmentsResult = await database.query(
            'set_segments',
            where: 'set_id = ?',
            whereArgs: [setId],
            orderBy: 'segment_order ASC',
          );

          for (final segRow in segmentsResult) {
            segments.add(
              SetSegment(
                id: segRow['id'].toString(),
                weight: (segRow['weight'] as num?)?.toDouble() ?? 0,
                repsFrom: segRow['reps_from'] as int? ?? 0,
                repsTo: segRow['reps_to'] as int? ?? 0,
                segmentOrder: segRow['segment_order'] as int? ?? 0,
                notes: segRow['notes'] as String? ?? '',
              ),
            );
          }

          sets.add(
            ExerciseSet(
              id: setId,
              setNumber: setRow['set_number'] as int? ?? 1,
              segments: segments,
            ),
          );
        }

        exercises.add(
          SessionExercise(
            id: exerciseId,
            name: exRow['name'].toString(),
            order: exRow['exercise_order'] as int? ?? 0,
            skipped: ((exRow['skipped'] as int?) ?? 0) == 1,
            sets: sets,
          ),
        );
      }

      final updatedWorkout = WorkoutSession(
        id: workoutRow['id'].toString(),
        userId: workoutRow['user_id'].toString(),
        planId: workoutRow['plan_id'].toString(),
        workoutDate: SQLiteService.parseDateTime(
          workoutRow['workout_date'] as String,
        ),
        startedAt: workoutRow['started_at'] != null
            ? SQLiteService.parseDateTime(workoutRow['started_at'] as String)
            : null,
        endedAt: workoutRow['ended_at'] != null
            ? SQLiteService.parseDateTime(workoutRow['ended_at'] as String)
            : null,
        exercises: exercises,
        createdAt: SQLiteService.parseDateTime(
          workoutRow['created_at'] as String,
        ),
        updatedAt: SQLiteService.parseDateTime(
          workoutRow['updated_at'] as String,
        ),
        isDraft: (workoutRow['is_draft'] as int?) == 1,
      );

      return updatedWorkout;
    } catch (e) {
      return workout;
    }
  }

  /// Delete a workout and all related exercises, sets, and segments
  Future<void> deleteWorkout(String workoutId) async {
    try {
      _log('DELETE', 'workout id=$workoutId');
      final database = SQLiteService.database;
      await database.delete(
        'workouts',
        where: 'id = ?',
        whereArgs: [workoutId],
      );
      _log('DELETE', 'workout: SUCCESS');
    } catch (e) {
      _log('DELETE', 'workout: FAILED - $e');
      rethrow;
    }
  }

  /// Get all workouts for a user and clear them (for cleanup)
  Future<void> clearUserWorkouts(String userId) async {
    try {
      _log('DELETE', 'workouts WHERE userId=$userId');
      final database = SQLiteService.database;
      await database.delete(
        'workouts',
        where: 'user_id = ?',
        whereArgs: [userId],
      );
      _log('DELETE', 'workouts user: SUCCESS');
    } catch (e) {
      _log('DELETE', 'workouts user: FAILED - $e');
      rethrow;
    }
  }

  /// Get the last logged session for a specific exercise
  Future<SessionExercise?> getLastExerciseLog(
    String userId,
    String exerciseName,
  ) async {
    try {
      final database = SQLiteService.database;

      // Find the most recent workout that includes this exercise (NOT skipped)
      final result = await database.rawQuery(
        '''
        SELECT w.id, w.workout_date
        FROM workouts w
        JOIN workout_exercises we ON w.id = we.workout_id
        WHERE w.user_id = ? AND we.name = ? AND w.is_draft = 0 AND we.skipped = 0
        ORDER BY w.workout_date DESC
        LIMIT 1
      ''',
        [userId, exerciseName],
      );

      if (result.isEmpty) return null;

      final workoutId = result.first['id'] as String;

      // Get the exercise details (id, etc) from that workout
      final exerciseRows = await database.query(
        'workout_exercises',
        where: 'workout_id = ? AND name = ?',
        whereArgs: [workoutId, exerciseName],
      );

      if (exerciseRows.isEmpty) return null;
      final exerciseRow = exerciseRows.first;
      final exerciseId = exerciseRow['id'] as String;

      // Get sets
      final setRows = await database.query(
        'workout_sets',
        where: 'exercise_id = ?',
        whereArgs: [exerciseId],
        orderBy: 'set_number ASC',
      );

      final sets = <ExerciseSet>[];
      for (final setRow in setRows) {
        final setId = setRow['id'] as String;
        final segmentRows = await database.query(
          'set_segments',
          where: 'set_id = ?',
          whereArgs: [setId],
          orderBy: 'segment_order ASC',
        );

        final segments = segmentRows
            .map(
              (seg) => SetSegment(
                id: seg['id'] as String,
                weight: (seg['weight'] as num?)?.toDouble() ?? 0,
                repsFrom: seg['reps_from'] as int? ?? 0,
                repsTo: seg['reps_to'] as int? ?? 0,
                segmentOrder: seg['segment_order'] as int? ?? 0,
                notes: seg['notes'] as String? ?? '',
              ),
            )
            .toList();

        sets.add(
          ExerciseSet(
            id: setId,
            setNumber: setRow['set_number'] as int,
            segments: segments,
          ),
        );
      }

      return SessionExercise(
        id: exerciseId,
        name: exerciseName,
        order: exerciseRow['exercise_order'] as int,
        sets: sets,
        skipped: (exerciseRow['skipped'] as int) == 1,
      );
    } catch (e) {
      _log('SELECT', 'getLastExerciseLog: FAILED - $e');
      return null;
    }
  }

  /// Get the Personal Record (PR) for a specific exercise
  /// Returns the segment with the highest weight
  Future<PersonalRecord?> getExercisePR(
    String userId,
    String exerciseName,
  ) async {
    try {
      final database = SQLiteService.database;

      // Metric 1: Best Heavy Set (Max Weight)
      final heavyResult = await database.rawQuery(
        '''
        SELECT ss.weight, MAX(ss.reps_from, ss.reps_to) as reps
        FROM set_segments ss
        JOIN workout_sets ws ON ss.set_id = ws.id
        JOIN workout_exercises we ON ws.exercise_id = we.id
        JOIN workouts w ON we.workout_id = w.id
        WHERE w.user_id = ? AND we.name = ? AND w.is_draft = 0
        ORDER BY ss.weight DESC, reps DESC
        LIMIT 1
      ''',
        [userId, exerciseName],
      );

      // Metric 2: Best Volume Set (Total Set Volume: Main + Drop segments)
      final volumeResult = await database.rawQuery(
        '''
        SELECT 
          ws.id as set_id,
          ss.weight,
          MAX(ss.reps_from, ss.reps_to) as reps,
          SUM(ss.weight * MAX(ss.reps_from, ss.reps_to)) as total_volume,
          '(' || GROUP_CONCAT(ss.weight || ' kg x ' || MAX(ss.reps_from, ss.reps_to), ' + ') || ')' as breakdown
        FROM set_segments ss
        JOIN workout_sets ws ON ss.set_id = ws.id
        JOIN workout_exercises we ON ws.exercise_id = we.id
        JOIN workouts w ON we.workout_id = w.id
        WHERE w.user_id = ? AND we.name = ? AND w.is_draft = 0
        GROUP BY ws.id
        ORDER BY total_volume DESC, ss.weight DESC
        LIMIT 1
      ''',
        [userId, exerciseName],
      );

      // Metric 3: Best Session (Highest total volume for this exercise in one workout)
      final sessionResult = await database.rawQuery(
        '''
        SELECT 
          w.id as workout_id,
          w.workout_date,
          SUM(ss.weight * MAX(ss.reps_from, ss.reps_to)) as session_volume
        FROM set_segments ss
        JOIN workout_sets ws ON ss.set_id = ws.id
        JOIN workout_exercises we ON ws.exercise_id = we.id
        JOIN workouts w ON we.workout_id = w.id
        WHERE w.user_id = ? AND we.name = ? AND w.is_draft = 0
        GROUP BY w.id
        ORDER BY session_volume DESC, w.workout_date DESC
        LIMIT 1
      ''',
        [userId, exerciseName],
      );

      if (heavyResult.isEmpty &&
          volumeResult.isEmpty &&
          sessionResult.isEmpty) {
        return null;
      }

      final heavyRow = heavyResult.isNotEmpty ? heavyResult.first : null;
      final volRow = volumeResult.isNotEmpty ? volumeResult.first : null;
      final sessionRow = sessionResult.isNotEmpty ? sessionResult.first : null;

      List<ExerciseSet>? bestSets;
      if (sessionRow != null) {
        final workoutId = sessionRow['workout_id'] as String;

        // Fetch sets for this specific session and exercise
        final setsResult = await database.rawQuery(
          '''
          SELECT 
            ws.id as set_id,
            ws.set_number,
            ss.id as segment_id,
            ss.weight,
            ss.reps_from,
            ss.reps_to,
            ss.segment_order,
            ss.notes
          FROM workout_sets ws
          JOIN set_segments ss ON ws.id = ss.set_id
          JOIN workout_exercises we ON ws.exercise_id = we.id
          WHERE we.workout_id = ? AND we.name = ?
          ORDER BY ws.set_number ASC, ss.segment_order ASC
          ''',
          [workoutId, exerciseName],
        );

        final setsMap = <String, List<SetSegment>>{};
        final setNumbers = <String, int>{};

        for (final row in setsResult) {
          final sId = row['set_id'] as String;
          setNumbers[sId] = row['set_number'] as int;
          setsMap
              .putIfAbsent(sId, () => [])
              .add(
                SetSegment(
                  id: row['segment_id'] as String,
                  weight: (row['weight'] as num).toDouble(),
                  repsFrom: row['reps_from'] as int,
                  repsTo: row['reps_to'] as int,
                  segmentOrder: row['segment_order'] as int,
                  notes: row['notes'] as String? ?? '',
                ),
              );
        }

        bestSets = setsMap.entries.map((e) {
          return ExerciseSet(
            id: e.key,
            setNumber: setNumbers[e.key]!,
            segments: e.value,
          );
        }).toList();
        bestSets.sort((a, b) => a.setNumber.compareTo(b.setNumber));
      }

      return PersonalRecord(
        maxWeight: (heavyRow?['weight'] as num?)?.toDouble() ?? 0,
        maxWeightReps: heavyRow?['reps'] as int? ?? 0,
        maxVolume: (volRow?['total_volume'] as num?)?.toDouble() ?? 0,
        maxVolumeWeight: (volRow?['weight'] as num?)?.toDouble() ?? 0,
        maxVolumeReps: volRow?['reps'] as int? ?? 0,
        maxVolumeBreakdown: volRow?['breakdown'] as String? ?? '',
        bestSessionVolume:
            (sessionRow?['session_volume'] as num?)?.toDouble() ?? 0,
        bestSessionDate: sessionRow?['workout_date'] as String?,
        bestSessionSets: bestSets,
      );
    } catch (e) {
      _log('SELECT', 'getExercisePR: FAILED - $e');
      return null;
    }
  }

  /// Get all distinct exercise names used by a user
  Future<List<String>> getExerciseNames(String userId) async {
    try {
      final database = SQLiteService.database;
      _log('SELECT', 'DISTINCT exercise names');

      final result = await database.rawQuery(
        '''
        SELECT DISTINCT we.name
        FROM workout_exercises we
        JOIN workouts w ON we.workout_id = w.id
        WHERE w.user_id = ?
        ORDER BY we.name ASC
      ''',
        [userId],
      );

      return result.map((row) => row['name'] as String).toList();
    } catch (e) {
      _log('SELECT', 'getExerciseNames: FAILED - $e');
      return [];
    }
  }

  Future<Map<String, PersonalRecord>> getAllPersonalRecords(
    String userId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final database = SQLiteService.database;
      _log('SELECT', 'Personal Records (Max Weight & Max Volume Set)');

      String whereClause = 'w.user_id = ? AND w.is_draft = 0';
      List<dynamic> args = [userId];

      if (startDate != null && endDate != null) {
        whereClause += ' AND w.workout_date BETWEEN ? AND ?';
        args.add(SQLiteService.formatDateTime(startDate));
        args.add(SQLiteService.formatDateTime(endDate));
      }

      // 1. Get Best Heavy Set (Max Weight, then Max Reps) - Individual Segment based
      final weightResult = await database.rawQuery('''
        WITH ranked_weights AS (
            SELECT 
                we.name,
                ss.weight,
                (ss.reps_to - ss.reps_from + 1) as reps,
                ROW_NUMBER() OVER (
                    PARTITION BY we.name 
                    ORDER BY ss.weight DESC, (ss.reps_to - ss.reps_from + 1) DESC
                ) as rn
            FROM set_segments ss
            JOIN workout_sets ws ON ss.set_id = ws.id
            JOIN workout_exercises we ON ws.exercise_id = we.id
            JOIN workouts w ON we.workout_id = w.id
            WHERE $whereClause
        )
        SELECT name, weight, reps FROM ranked_weights WHERE rn = 1
      ''', args);

      final maxWeights = <String, Map<String, dynamic>>{};
      for (final row in weightResult) {
        final name = row['name'] as String;
        maxWeights[name] = {
          'weight': (row['weight'] as num?)?.toDouble() ?? 0.0,
          'reps': (row['reps'] as num?)?.toInt() ?? 0,
        };
      }

      // 2. Get Best Volume Set (Total Set Volume = Sum of segment volumes)
      final volumeResult = await database.rawQuery('''
        WITH set_volumes AS (
            SELECT 
                we.name,
                ws.id as set_id,
                ss.weight as main_weight,
                (ss.reps_to - ss.reps_from + 1) as main_reps,
                SUM(ss.weight * (ss.reps_to - ss.reps_from + 1)) as total_volume,
                '(' || GROUP_CONCAT(ss.weight || ' kg x ' || (ss.reps_to - ss.reps_from + 1), ' + ') || ')' as breakdown
            FROM set_segments ss
            JOIN workout_sets ws ON ss.set_id = ws.id
            JOIN workout_exercises we ON ws.exercise_id = we.id
            JOIN workouts w ON we.workout_id = w.id
            WHERE $whereClause
            GROUP BY ws.id
        ),
        ranked_volumes AS (
            SELECT 
                name, main_weight, main_reps, total_volume, breakdown,
                ROW_NUMBER() OVER (
                    PARTITION BY name 
                    ORDER BY total_volume DESC, main_weight DESC
                ) as rn
            FROM set_volumes
        )
        SELECT name, main_weight, main_reps, total_volume, breakdown 
        FROM ranked_volumes WHERE rn = 1
      ''', args);

      final maxVolumes = <String, Map<String, dynamic>>{};
      for (final row in volumeResult) {
        final name = row['name'] as String;
        maxVolumes[name] = {
          'volume': (row['total_volume'] as num?)?.toDouble() ?? 0.0,
          'weight': (row['main_weight'] as num?)?.toDouble() ?? 0.0,
          'reps': (row['main_reps'] as num?)?.toInt() ?? 0,
          'breakdown': row['breakdown'] as String? ?? '',
        };
      }

      // 3. Get Best Session (Highest total volume for this exercise in one workout)
      final sessionResult = await database.rawQuery('''
        WITH session_volumes AS (
            SELECT 
                we.name,
                w.id as workout_id,
                w.workout_date,
                SUM(ss.weight * (ss.reps_to - ss.reps_from + 1)) as total_volume
            FROM set_segments ss
            JOIN workout_sets ws ON ss.set_id = ws.id
            JOIN workout_exercises we ON ws.exercise_id = we.id
            JOIN workouts w ON we.workout_id = w.id
            WHERE $whereClause
            GROUP BY we.name, w.id
        ),
        ranked_sessions AS (
            SELECT 
                name, workout_date, total_volume,
                ROW_NUMBER() OVER (
                    PARTITION BY name 
                    ORDER BY total_volume DESC, workout_date DESC
                ) as rn
            FROM session_volumes
        )
        SELECT name, workout_date, total_volume 
        FROM ranked_sessions WHERE rn = 1
      ''', args);

      final maxSessions = <String, Map<String, dynamic>>{};
      for (final row in sessionResult) {
        final name = row['name'] as String;
        maxSessions[name] = {
          'volume': (row['total_volume'] as num?)?.toDouble() ?? 0.0,
          'date': row['workout_date'] as String?,
        };
      }

      // 3. Merge results
      final records = <String, PersonalRecord>{};
      final allNames = {
        ...maxWeights.keys,
        ...maxVolumes.keys,
        ...maxSessions.keys,
      };

      for (final name in allNames) {
        final weightData = maxWeights[name];
        final volumeData = maxVolumes[name];
        final sessionData = maxSessions[name];

        records[name] = PersonalRecord(
          maxWeight: (weightData?['weight'] as num?)?.toDouble() ?? 0.0,
          maxWeightReps: (weightData?['reps'] as num?)?.toInt() ?? 0,
          maxVolume: (volumeData?['volume'] as num?)?.toDouble() ?? 0.0,
          maxVolumeWeight: (volumeData?['weight'] as num?)?.toDouble() ?? 0.0,
          maxVolumeReps: (volumeData?['reps'] as num?)?.toInt() ?? 0,
          maxVolumeBreakdown: volumeData?['breakdown'] as String? ?? '',
          bestSessionVolume:
              (sessionData?['volume'] as num?)?.toDouble() ?? 0.0,
          bestSessionDate: sessionData?['date'] as String?,
        );
      }

      return records;
    } catch (e) {
      _log('SELECT', 'getAllPersonalRecords: FAILED - $e');
      return {};
    }
  }
}
