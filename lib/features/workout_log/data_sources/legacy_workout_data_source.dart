import 'package:sqflite/sqflite.dart';
import 'package:flutter/foundation.dart';
import 'package:liftly/core/models/workout_session.dart';
import 'package:liftly/core/services/sqlite_service.dart';

class LegacyWorkoutDataSource {
  /// Log database operations
  static void _log(String operation, String message) {
    if (kDebugMode) {
      print('[LegacyDB] $operation: $message');
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
      await database.insert(
          'workouts',
          {
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
          },
          conflictAlgorithm: ConflictAlgorithm.replace);
      _log('INSERT', 'workouts: SUCCESS');

      // Insert exercises with sets and segments
      for (final exercise in workout.exercises) {
        _log(
          'INSERT',
          'workout_exercises: id=${exercise.id}, name=${exercise.name}',
        );
        await database.insert(
            'workout_exercises',
            {
              'id': exercise.id,
              'workout_id': workout.id,
              'name': exercise.name,
              'exercise_order': exercise.order,
              'skipped': exercise.skipped ? 1 : 0,
              'is_template': exercise.isTemplate ? 1 : 0,
            },
            conflictAlgorithm: ConflictAlgorithm.replace);

        // Insert sets and segments for this exercise
        for (final set in exercise.sets) {
          _log(
            'INSERT',
            'workout_sets: id=${set.id}, setNumber=${set.setNumber}',
          );
          await database.insert(
              'workout_sets',
              {
                'id': set.id,
                'exercise_id': exercise.id,
                'set_number': set.setNumber,
              },
              conflictAlgorithm: ConflictAlgorithm.replace);

          // Insert segments for this set
          for (final segment in set.segments) {
            _log(
              'INSERT',
              'set_segments: id=${segment.id}, weight=${segment.weight}',
            );
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
                conflictAlgorithm: ConflictAlgorithm.replace);
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
    bool includeDrafts = false, // Added for migration support
  }) async {
    try {
      _log(
        'SELECT_OPTIMIZED',
        'workouts JOIN exercises JOIN sets JOIN segments WHERE userId=$userId',
      );
      final database = SQLiteService.database;

      // 1. Get the workout IDs first to apply limit correctly
      String whereClause = 'user_id = ?';
      if (!includeDrafts) {
        whereClause += ' AND is_draft = 0';
      }

      final workoutIdsResult = await database.query(
        'workouts',
        columns: ['id'],
        where: whereClause,
        whereArgs: [userId],
        orderBy: 'workout_date DESC',
        limit: limit > 0 ? limit : null,
        offset: offset,
      );

      if (workoutIdsResult.isEmpty) return [];
      final workoutIds =
          workoutIdsResult.map((w) => w['id'] as String).toList();
      final placeholders = List.filled(workoutIds.length, '?').join(',');

      // 2. Fetch EVERYTHING in one big joined query
      // We join all related tables to get all data at once

      // Note: The above query has a bug with double join on set_segments (wsss alias unused).
      // Correcting it below in logic, but standard query was:
      /*
        LEFT JOIN set_segments ss ON ws.id = ss.set_id
      */
      // Re-writing correct query string here for rawQuery cleanliness
      final correctedQuery = await database.rawQuery('''
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

      for (final row in correctedQuery) {
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

  // ... (Other methods omitted for brevity as they are for reading single instances, which migration loop does not necessarily use if query above works)
  // For migration purposes, getWorkouts(userId, includeDrafts: true) is key.
}
