import 'package:liftly/core/models/workout_session.dart';
import 'package:liftly/core/services/hive_service.dart';
import '../../../core/models/personal_record.dart';
import '../../../core/utils/app_logger.dart';

class WorkoutLocalDataSource {
  static const String _tag = 'WorkoutLocalDS';

  /// Create a new workout with exercises, sets, and segments
  Future<WorkoutSession> createWorkout(WorkoutSession workout) async {
    try {
      AppLogger.debug(_tag, 'CREATE: Workout id=${workout.id}, userId=${workout.userId}');
      await HiveService.createWorkout(workout);
      AppLogger.debug(_tag, 'CREATE: Workout creation SUCCESSFUL');
      return workout;
    } catch (e) {
      AppLogger.error(_tag, 'CREATE: FAILED', e);
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
      AppLogger.debug(_tag, 'SELECT: workouts userId=$userId limit=$limit offset=$offset');
      // Pass pagination params for DB-level optimization
      final workouts = await HiveService.getWorkouts(userId,
          includeDrafts: includeDrafts, limit: limit, offset: offset);

      return workouts;
    } catch (e) {
      AppLogger.error(_tag, 'SELECT: workouts FAILED', e);
      rethrow;
    }
  }

  /// Get a single workout by ID with all related exercises, sets, and segments
  Future<WorkoutSession> getWorkout(String workoutId) async {
    AppLogger.debug(_tag, 'SELECT: workout id=$workoutId');
    final workout = await HiveService.getWorkout(workoutId);
    if (workout == null) {
      throw Exception('Workout not found');
    }
    return workout;
  }

  /// Get the latest draft workout for a user
  Future<WorkoutSession?> getDraftWorkout(String userId) async {
    try {
      AppLogger.debug(_tag, 'SELECT: Draft workout for userId=$userId');
      return await HiveService.getDraftWorkout(userId);
    } catch (e) {
      AppLogger.error(_tag, 'SELECT: getDraftWorkout FAILED', e);
      return null;
    }
  }

  /// Update an existing workout
  Future<WorkoutSession> updateWorkout(WorkoutSession workout) async {
    try {
      AppLogger.debug(_tag, 'UPDATE: workout id=${workout.id}, exercises count=${workout.exercises.length}');
      for (int i = 0; i < workout.exercises.length; i++) {
        final ex = workout.exercises[i];
        AppLogger.debug(_tag, 'UPDATE:   [$i] ${ex.name} | variation="${ex.variation}"');
      }
      
      await HiveService.updateWorkout(workout);
      
      AppLogger.debug(_tag, 'UPDATE: SUCCESSFUL - workout id=${workout.id}');
      return workout;
    } catch (e) {
      AppLogger.error(_tag, 'UPDATE: FAILED', e);
      rethrow;
    }
  }

  /// Discard (delete) all drafts for a specific user
  Future<void> discardDrafts(String userId) async {
    try {
      AppLogger.debug(_tag, 'DELETE: drafts userId=$userId');
      await HiveService.discardDrafts(userId);
      AppLogger.debug(_tag, 'DELETE: drafts SUCCESS');
    } catch (e) {
      AppLogger.error(_tag, 'DELETE: drafts FAILED', e);
      rethrow;
    }
  }

  /// Delete a workout and all related exercises, sets, and segments
  Future<void> deleteWorkout(String workoutId) async {
    try {
      AppLogger.debug(_tag, 'DELETE: workout id=$workoutId');
      await HiveService.deleteWorkout(workoutId);
      AppLogger.debug(_tag, 'DELETE: workout SUCCESS');
    } catch (e) {
      AppLogger.error(_tag, 'DELETE: workout FAILED', e);
      rethrow;
    }
  }

  /// Get all workouts for a user and clear them (for cleanup)
  Future<void> clearUserWorkouts(String userId) async {
    try {
      AppLogger.debug(_tag, 'DELETE: workouts WHERE userId=$userId');
      final workouts =
          await HiveService.getWorkouts(userId, includeDrafts: true);
      for (final w in workouts) {
        await HiveService.deleteWorkout(w.id);
      }
      AppLogger.debug(_tag, 'DELETE: workouts user SUCCESS');
    } catch (e) {
      AppLogger.error(_tag, 'DELETE: workouts user FAILED', e);
      rethrow;
    }
  }

  /// Get the last logged session for a specific exercise
  Future<WorkoutSession?> getLastExerciseLog(
    String userId,
    String exerciseName,
    String exerciseVariation,
  ) async {
    try {
      return await HiveService.getLastExerciseLog(userId, exerciseName,
          exerciseVariation: exerciseVariation);
    } catch (e) {
      AppLogger.error(_tag, 'SELECT: getLastExerciseLog FAILED', e);
      return null;
    }
  }

  /// Get the Personal Record (PR) for a specific exercise
  Future<PersonalRecord?> getExercisePR(
    String userId,
    String exerciseName,
    String exerciseVariation,
  ) async {
    try {
      return await HiveService.getExercisePR(userId, exerciseName,
          exerciseVariation: exerciseVariation);
    } catch (e) {
      AppLogger.error(_tag, 'SELECT: getExercisePR FAILED', e);
      return null;
    }
  }

  /// Get distinct exercise names
  Future<List<String>> getExerciseNames(String userId) async {
    try {
      return await HiveService.getExerciseNames(userId);
    } catch (e) {
      AppLogger.error(_tag, 'SELECT: getExerciseNames FAILED', e);
      return [];
    }
  }

  /// Get record of variations for a specific exercise and user
  Future<List<String>> getExerciseVariations(
    String userId,
    String exerciseName,
  ) async {
    try {
      return await HiveService.getExerciseVariations(userId, exerciseName);
    } catch (e) {
      AppLogger.error(_tag, 'SELECT: getExerciseVariations FAILED', e);
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
      return await HiveService.getAllPersonalRecords(userId,
          startDate: startDate, endDate: endDate);
    } catch (e) {
      AppLogger.error(_tag, 'SELECT: getAllPersonalRecords FAILED', e);
      return {};
    }
  }
}
