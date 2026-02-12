import 'package:flutter/foundation.dart';
import 'package:liftly/core/models/workout_session.dart';
import 'package:liftly/core/services/isar_service.dart';
import 'package:liftly/features/stats/bloc/stats_state.dart';

class WorkoutLocalDataSource {
  static const String _logTag = 'WorkoutLocalDataSource';

  /// Log database operations
  static void _log(String operation, String message) {
    if (kDebugMode) {
      print('[$_logTag] $operation: $message');
    }
  }

  /// Create a new workout with exercises, sets, and segments
  Future<WorkoutSession> createWorkout(WorkoutSession workout) async {
    try {
      _log('CREATE', 'Workout id=${workout.id}, userId=${workout.userId}');
      await IsarService.createWorkout(workout);
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
    int? limit = 20,
    int offset = 0,
    bool includeDrafts = false,
  }) async {
    try {
      _log('SELECT', 'workouts userId=$userId limit=$limit offset=$offset');
      // Pass pagination params to IsarService for DB-level optimization
      final workouts = await IsarService.getWorkouts(userId,
          includeDrafts: includeDrafts, limit: limit, offset: offset);

      return workouts;
    } catch (e) {
      _log('SELECT', 'workouts: FAILED - $e');
      rethrow;
    }
  }

  /// Get a single workout by ID with all related exercises, sets, and segments
  Future<WorkoutSession> getWorkout(String workoutId) async {
    _log('SELECT', 'workout id=$workoutId');
    final workout = await IsarService.getWorkoutById(workoutId);
    if (workout == null) {
      throw Exception('Workout not found');
    }
    return workout;
  }

  /// Get the latest draft workout for a user
  Future<WorkoutSession?> getDraftWorkout(String userId) async {
    try {
      _log('SELECT', 'Draft workout for userId=$userId');
      return await IsarService.getDraftWorkout(userId);
    } catch (e) {
      _log('SELECT', 'getDraftWorkout: FAILED - $e');
      return null;
    }
  }

  /// Update an existing workout
  Future<WorkoutSession> updateWorkout(WorkoutSession workout) async {
    try {
      _log('UPDATE', 'workout id=${workout.id}');
      await IsarService.updateWorkout(workout);
      return workout;
    } catch (e) {
      _log('UPDATE', 'FAILED - $e');
      rethrow;
    }
  }

  /// Delete a workout and all related exercises, sets, and segments
  Future<void> deleteWorkout(String workoutId) async {
    try {
      _log('DELETE', 'workout id=$workoutId');
      await IsarService.deleteWorkout(workoutId);
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
      final workouts =
          await IsarService.getWorkouts(userId, includeDrafts: true);
      for (final w in workouts) {
        await IsarService.deleteWorkout(w.id);
      }
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
      return await IsarService.getLastExerciseLog(userId, exerciseName);
    } catch (e) {
      _log('SELECT', 'getLastExerciseLog: FAILED - $e');
      return null;
    }
  }

  /// Get the Personal Record (PR) for a specific exercise
  Future<PersonalRecord?> getExercisePR(
    String userId,
    String exerciseName,
  ) async {
    try {
      return await IsarService.getExercisePR(userId, exerciseName);
    } catch (e) {
      _log('SELECT', 'getExercisePR: FAILED - $e');
      return null;
    }
  }

  /// Get distinct exercise names
  Future<List<String>> getExerciseNames(String userId) async {
    try {
      return await IsarService.getExerciseNames(userId);
    } catch (e) {
      _log('SELECT', 'getExerciseNames: FAILED - $e');
      return [];
    }
  }

  /// Get all personal records
  Future<Map<String, PersonalRecord>> getAllPersonalRecords(
    String userId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      return await IsarService.getAllPersonalRecords(userId,
          startDate: startDate, endDate: endDate);
    } catch (e) {
      _log('SELECT', 'getAllPersonalRecords: FAILED - $e');
      return {};
    }
  }
}
