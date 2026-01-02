import 'package:sqflite/sqflite.dart';
import 'package:flutter/foundation.dart';
import 'package:liftly/core/models/workout_session.dart';
import 'package:liftly/core/services/sqlite_service.dart';

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
      _log('CREATE', 'Workout id=${workout.id}, userId=${workout.userId}, exercises=${workout.exercises.length}');
      final database = SQLiteService.database;

      // Insert workout
      _log('INSERT', 'workouts table: id=${workout.id}');
      await database.insert(
        'workouts',
        {
          'id': workout.id,
          'user_id': workout.userId,
          'plan_id': workout.planId,
          'workout_date': SQLiteService.formatDateTime(workout.workoutDate),
          'started_at': workout.startedAt != null ? SQLiteService.formatDateTime(workout.startedAt!) : null,
          'ended_at': workout.endedAt != null ? SQLiteService.formatDateTime(workout.endedAt!) : null,
          'created_at': SQLiteService.formatDateTime(workout.createdAt),
          'updated_at': SQLiteService.formatDateTime(workout.updatedAt),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      _log('INSERT', 'workouts: SUCCESS');

      // Insert exercises with sets and segments
      for (final exercise in workout.exercises) {
        _log('INSERT', 'workout_exercises: id=${exercise.id}, name=${exercise.name}');
        await database.insert(
          'workout_exercises',
          {
            'id': exercise.id,
            'workout_id': workout.id,
            'name': exercise.name,
            'exercise_order': exercise.order,
            'skipped': exercise.skipped ? 1 : 0,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        // Insert sets and segments for this exercise
        for (final set in exercise.sets) {
          _log('INSERT', 'workout_sets: id=${set.id}, setNumber=${set.setNumber}');
          await database.insert(
            'workout_sets',
            {
              'id': set.id,
              'exercise_id': exercise.id,
              'set_number': set.setNumber,
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );

          // Insert segments for this set
          for (final segment in set.segments) {
            _log('INSERT', 'set_segments: id=${segment.id}, weight=${segment.weight}');
            await database.insert(
              'set_segments',
              {
                'id': segment.id,
                'set_id': set.id,
                'weight': segment.weight,
                'reps_from': segment.repsFrom,
                'reps_to': segment.repsTo,
                'segment_order': segment.segmentOrder,
                'notes': segment.notes,
              },
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
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
  Future<List<WorkoutSession>> getWorkouts(String userId) async {
    try {
      _log('SELECT', 'workouts WHERE userId=$userId');
      final database = SQLiteService.database;

      final workouts = await database.query(
        'workouts',
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'workout_date DESC',
      );

      _log('SELECT', 'workouts: Found ${workouts.length} records');
      final result = await Future.wait(
        workouts.map((w) => _buildWorkoutFromRows(w['id'] as String)),
      );
      
      // Log the result
      for (final workout in result) {
        int totalSets = 0;
        for (final ex in workout.exercises) {
          totalSets += ex.sets.length;
        }
        _log('SELECT', 'Loaded workout ${workout.id}: ${workout.exercises.length} exercises, $totalSets total sets');
      }
      
      return result;
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

  /// Build complete workout object from database rows
  Future<WorkoutSession> _buildWorkoutFromRows(String workoutId) async {
    try {
      final database = SQLiteService.database;

      // Get workout
      _log('SELECT', 'workouts id=$workoutId');
      final workoutRows = await database.query(
        'workouts',
        where: 'id = ?',
        whereArgs: [workoutId],
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
          _log('DEBUG', 'Exercise row $i: id=${row['id']}, name=${row['name']}, workoutId=${row['workout_id']}');
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

        _log('SELECT', 'workout_sets: Found ${setRows.length} records for exercise $exerciseId');
        // Log set IDs for debugging - show each set row
        if (setRows.isNotEmpty) {
          final setIds = setRows.map((s) => s['id']).join(',');
          _log('DEBUG', 'Exercise $exerciseId has set IDs: $setIds');
          for (int i = 0; i < setRows.length; i++) {
            final row = setRows[i];
            _log('DEBUG', 'Row $i: id=${row['id']}, setNumber=${row['set_number']}, exerciseId=${row['exercise_id']}');
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
                  weight: seg['weight'] as double,
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
          _log('DEBUG', 'Added set $setId with ${segments.length} segments to exercise');
        }

        exercises.add(
          SessionExercise(
            id: exerciseId,
            name: exerciseRow['name'] as String,
            order: exerciseRow['exercise_order'] as int,
            sets: sets,
            skipped: (exerciseRow['skipped'] as int) == 1,
          ),
        );
        _log('DEBUG', 'Added exercise $exerciseId with ${sets.length} sets');
      }

      final result = WorkoutSession(
        id: workoutRow['id'] as String,
        userId: workoutRow['user_id'] as String,
        planId: workoutRow['plan_id'] as String?,
        workoutDate: SQLiteService.parseDateTime(workoutRow['workout_date'] as String),
        startedAt: workoutRow['started_at'] != null
            ? SQLiteService.parseDateTime(workoutRow['started_at'] as String)
            : null,
        endedAt: workoutRow['ended_at'] != null
            ? SQLiteService.parseDateTime(workoutRow['ended_at'] as String)
            : null,
        exercises: exercises,
        createdAt: SQLiteService.parseDateTime(workoutRow['created_at'] as String),
        updatedAt: SQLiteService.parseDateTime(workoutRow['updated_at'] as String),
      );
      
      // Log the final result
      int totalSets = 0;
      for (final ex in result.exercises) {
        totalSets += ex.sets.length;
      }
      _log('SELECT', 'Built workout ${result.id}: ${result.exercises.length} exercises, $totalSets total sets');
      
      return result;
    } catch (e) {
      _log('SELECT', 'Build workout: FAILED - $e');
      rethrow;
    }
  }

  /// Update an existing workout
  Future<WorkoutSession> updateWorkout(WorkoutSession workout) async {
    final database = SQLiteService.database;

    print('[EDIT DEBUG] updateWorkout called for workout: ${workout.id}');
    print('[EDIT DEBUG] Updating startedAt: ${workout.startedAt}');
    print('[EDIT DEBUG] Updating endedAt: ${workout.endedAt}');

    // Update workout basic info
    await database.update(
      'workouts',
      {
        'plan_id': workout.planId,
        'workout_date': SQLiteService.formatDateTime(workout.workoutDate),
        'started_at': workout.startedAt != null ? SQLiteService.formatDateTime(workout.startedAt!) : null,
        'ended_at': workout.endedAt != null ? SQLiteService.formatDateTime(workout.endedAt!) : null,
        'updated_at': SQLiteService.formatDateTime(workout.updatedAt),
      },
      where: 'id = ?',
      whereArgs: [workout.id],
    );

    print('[EDIT DEBUG] Database update completed');

    // Fetch existing exercises for exercises that are skipped to preserve their sets
    final existingExercisesResult = await database.query(
      'workout_exercises',
      where: 'workout_id = ?',
      whereArgs: [workout.id],
    );
    
    final existingExercisesMap = <String, Map<String, dynamic>>{};
    for (final exRow in existingExercisesResult) {
      existingExercisesMap[exRow['id'].toString()] = exRow;
    }

    // Delete existing exercises (cascade will delete sets and segments)
    await database.delete(
      'workout_exercises',
      where: 'workout_id = ?',
      whereArgs: [workout.id],
    );

    print('[EDIT DEBUG] Deleted existing exercises, now re-inserting ${workout.exercises.length} exercises');

    // Re-insert all exercises with their sets and segments
    for (final exercise in workout.exercises) {
      print('[EDIT DEBUG] Inserting exercise: ${exercise.id} (${exercise.name}) with ${exercise.sets.length} sets, skipped: ${exercise.skipped}');
      
      await database.insert(
        'workout_exercises',
        {
          'id': exercise.id,
          'workout_id': workout.id,
          'name': exercise.name,
          'exercise_order': exercise.order,
          'skipped': exercise.skipped ? 1 : 0,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // If exercise is skipped and has no sets, preserve existing sets from database
      var setsToInsert = exercise.sets;
      if (exercise.skipped && exercise.sets.isEmpty && existingExercisesMap.containsKey(exercise.id)) {
        print('[EDIT DEBUG] Exercise ${exercise.id} is skipped with no sets, fetching existing sets from database');
        final existingSetsResult = await database.query(
          'workout_sets',
          where: 'exercise_id = ?',
          whereArgs: [exercise.id],
        );
        
        // Reconstruct sets from database
        final reconstructedSets = <ExerciseSet>[];
        for (final setRow in existingSetsResult) {
          final setId = setRow['id'].toString();
          final segmentsResult = await database.query(
            'set_segments',
            where: 'set_id = ?',
            whereArgs: [setId],
          );
          
          final segments = <SetSegment>[];
          for (final segRow in segmentsResult) {
            segments.add(SetSegment(
              id: segRow['id'].toString(),
              weight: (segRow['weight'] as num?)?.toDouble() ?? 0,
              repsFrom: segRow['reps_from'] as int? ?? 0,
              repsTo: segRow['reps_to'] as int? ?? 0,
              segmentOrder: segRow['segment_order'] as int? ?? 0,
              notes: segRow['notes'] as String? ?? '',
            ));
          }
          
          reconstructedSets.add(ExerciseSet(
            id: setId,
            setNumber: setRow['set_number'] as int? ?? 1,
            segments: segments,
          ));
        }
        setsToInsert = reconstructedSets;
        print('[EDIT DEBUG] Preserved ${setsToInsert.length} sets for skipped exercise ${exercise.id}');
      }

      for (final set in setsToInsert) {
        await database.insert(
          'workout_sets',
          {
            'id': set.id,
            'exercise_id': exercise.id,
            'set_number': set.setNumber,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        for (final segment in set.segments) {
          await database.insert(
            'set_segments',
            {
              'id': segment.id,
              'set_id': set.id,
              'weight': segment.weight,
              'reps_from': segment.repsFrom,
              'reps_to': segment.repsTo,
              'segment_order': segment.segmentOrder,
              'notes': segment.notes,
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }
    }

    // Fetch and return the updated workout from database to ensure fresh data
    print('[EDIT DEBUG] Fetching updated workout from database for id: ${workout.id}');
    try {
      // Query the updated workout directly from database using workout ID
      final workoutResult = await database.query(
        'workouts',
        where: 'id = ?',
        whereArgs: [workout.id],
      );

      if (workoutResult.isEmpty) {
        print('[EDIT DEBUG] ERROR: Workout not found after update!');
        throw Exception('Workout not found after update');
      }

      final workoutRow = workoutResult.first;
      print('[EDIT DEBUG] Found workout in database');
      print('[EDIT DEBUG] Database row data:');
      print('[EDIT DEBUG]   started_at column: ${workoutRow['started_at']}');
      print('[EDIT DEBUG]   ended_at column: ${workoutRow['ended_at']}');
      print('[EDIT DEBUG]   updated_at column: ${workoutRow['updated_at']}');

      // Build exercises list from database
      final exercisesResult = await database.query(
        'workout_exercises',
        where: 'workout_id = ?',
        whereArgs: [workout.id],
        orderBy: 'exercise_order ASC',
      );

      print('[EDIT DEBUG] Found ${exercisesResult.length} exercises');
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
            segments.add(SetSegment(
              id: segRow['id'].toString(),
              weight: (segRow['weight'] as num?)?.toDouble() ?? 0,
              repsFrom: segRow['reps_from'] as int? ?? 0,
              repsTo: segRow['reps_to'] as int? ?? 0,
              segmentOrder: segRow['segment_order'] as int? ?? 0,
              notes: segRow['notes'] as String? ?? '',
            ));
          }

          sets.add(ExerciseSet(
            id: setId,
            setNumber: setRow['set_number'] as int? ?? 1,
            segments: segments,
          ));
        }

        exercises.add(SessionExercise(
          id: exerciseId,
          name: exRow['name'].toString(),
          order: exRow['exercise_order'] as int? ?? 0,
          skipped: ((exRow['skipped'] as int?) ?? 0) == 1,
          sets: sets,
        ));
      }

      final updatedWorkout = WorkoutSession(
        id: workoutRow['id'].toString(),
        userId: workoutRow['user_id'].toString(),
        planId: workoutRow['plan_id'].toString(),
        workoutDate: SQLiteService.parseDateTime(workoutRow['workout_date'] as String),
        startedAt: workoutRow['started_at'] != null
            ? SQLiteService.parseDateTime(workoutRow['started_at'] as String)
            : null,
        endedAt: workoutRow['ended_at'] != null
            ? SQLiteService.parseDateTime(workoutRow['ended_at'] as String)
            : null,
        exercises: exercises,
        createdAt: SQLiteService.parseDateTime(workoutRow['created_at'] as String),
        updatedAt: SQLiteService.parseDateTime(workoutRow['updated_at'] as String),
      );

      print('[EDIT DEBUG] Fetched startedAt: ${updatedWorkout.startedAt}');
      print('[EDIT DEBUG] Fetched endedAt: ${updatedWorkout.endedAt}');
      
      return updatedWorkout;
    } catch (e) {
      print('[EDIT DEBUG] Error fetching updated workout: $e');
      // Fallback: return the original workout with updated fields
      print('[EDIT DEBUG] Returning original workout as fallback');
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
}
