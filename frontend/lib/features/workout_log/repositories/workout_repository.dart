import '../../../core/models/workout_session.dart';
import '../data_sources/workout_local_data_source.dart';

class WorkoutRepository {
  final WorkoutLocalDataSource _localDataSource = WorkoutLocalDataSource();

  Future<WorkoutSession> createWorkout({
    required String userId,
    required WorkoutSession workout,
  }) async {
    try {
      return await _localDataSource.createWorkout(workout);
    } catch (e) {
      throw Exception(_parseErrorMessage(e.toString()));
    }
  }

  Future<List<WorkoutSession>> getWorkouts({
    required String userId,
  }) async {
    try {
      final workouts = await _localDataSource.getWorkouts(userId);
      print('[REPO] getWorkouts: userId=$userId, found ${workouts.length} workouts');
      for (var w in workouts) {
        print('[REPO]   - Workout: id=${w.id}, date=${w.workoutDate}, exercises=${w.exercises.length}');
      }
      return workouts;
    } catch (e) {
      rethrow;
    }
  }

  Future<WorkoutSession> getWorkout({
    required String workoutId,
  }) async {
    try {
      return await _localDataSource.getWorkout(workoutId);
    } catch (e) {
      rethrow;
    }
  }

  Future<WorkoutSession> updateWorkout({
    required String userId,
    required String workoutId,
    required WorkoutSession workout,
  }) async {
    try {
      return await _localDataSource.updateWorkout(workout);
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

  String _parseErrorMessage(String error) {
    if (error.contains('Exception:')) {
      return error.split('Exception:').last.trim();
    }
    return error;
  }
}

