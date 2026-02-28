import '../../../core/models/workout_session.dart';
import '../data_sources/workout_local_data_source.dart';
import '../../../core/models/personal_record.dart';
import '../../../core/utils/app_logger.dart';

class WorkoutRepository {
  final WorkoutLocalDataSource _localDataSource = WorkoutLocalDataSource();

  static const String _tag = 'WorkoutRepository';

  Future<WorkoutSession> createWorkout({
    required String userId,
    required WorkoutSession workout,
  }) async {
    try {
      AppLogger.debug(_tag, 'createWorkout: planName=${workout.planName}');
      return await _localDataSource.createWorkout(workout);
    } catch (e) {
      throw Exception(_parseErrorMessage(e.toString()));
    }
  }

  Future<List<WorkoutSession>> getWorkouts({
    required String userId,
    int? limit = 20,
    int offset = 0,
  }) async {
    try {
      final workouts = await _localDataSource.getWorkouts(
        userId,
        limit: limit,
        offset: offset,
      );
      return workouts;
    } catch (e) {
      rethrow;
    }
  }

  Future<WorkoutSession> getWorkout({required String workoutId}) async {
    return await _localDataSource.getWorkout(workoutId);
  }

  Future<WorkoutSession> updateWorkout({
    required String userId,
    required String workoutId,
    required WorkoutSession workout,
  }) async {
    try {
      final result = await _localDataSource.updateWorkout(workout);
      return result;
    } catch (e) {
      throw Exception(_parseErrorMessage(e.toString()));
    }
  }

  Future<void> deleteWorkout({
    required String userId,
    required String workoutId,
  }) async {
    try {
      await _localDataSource.deleteWorkout(workoutId);
    } catch (e) {
      throw Exception(_parseErrorMessage(e.toString()));
    }
  }

  Future<WorkoutSession?> getLastExerciseLog({
    required String userId,
    required String exerciseName,
    String exerciseVariation = '',
  }) async {
    try {
      return await _localDataSource.getLastExerciseLog(
          userId, exerciseName, exerciseVariation);
    } catch (e) {
      return null;
    }
  }

  Future<PersonalRecord?> getExercisePR({
    required String userId,
    required String exerciseName,
    String exerciseVariation = '',
  }) async {
    try {
      return await _localDataSource.getExercisePR(
          userId, exerciseName, exerciseVariation);
    } catch (e) {
      return null;
    }
  }

  Future<void> discardDrafts({required String userId}) async {
    try {
      await _localDataSource.discardDrafts(userId);
    } catch (e) {
      throw Exception(_parseErrorMessage(e.toString()));
    }
  }

  Future<WorkoutSession?> getDraftWorkout({required String userId}) async {
    try {
      final draft = await _localDataSource.getDraftWorkout(userId);
      AppLogger.debug(_tag, 'getDraftWorkout: draft?.planName=${draft?.planName}');
      return draft;
    } catch (e) {
      return null;
    }
  }

  Future<List<String>> getExerciseNames({required String userId}) async {
    try {
      return await _localDataSource.getExerciseNames(userId);
    } catch (e) {
      return [];
    }
  }

  Future<List<String>> getExerciseVariations({
    required String userId,
    required String exerciseName,
  }) async {
    try {
      return await _localDataSource.getExerciseVariations(userId, exerciseName);
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, PersonalRecord>> getAllPersonalRecords({
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      return await _localDataSource.getAllPersonalRecords(
        userId,
        startDate: startDate,
        endDate: endDate,
      );
    } catch (e) {
      return {};
    }
  }

  String _parseErrorMessage(String error) {
    if (error.contains('Exception:')) {
      return error.split('Exception:').last.trim();
    }
    return error;
  }
}
