import 'package:flutter/material.dart';

import '../../../core/models/workout_session.dart';
import '../data_sources/workout_local_data_source.dart';
import '../../../core/models/personal_record.dart';

class WorkoutRepository {
  final WorkoutLocalDataSource _localDataSource = WorkoutLocalDataSource();

  void _log(String message) {
    debugPrint('[WorkoutRepository] $message');
  }

  Future<WorkoutSession> createWorkout({
    required String userId,
    required WorkoutSession workout,
  }) async {
    try {
      _log('createWorkout: planName=${workout.planName}');
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

  Future<WorkoutSession?> getLastExerciseLog({
    required String userId,
    required String exerciseName,
  }) async {
    try {
      return await _localDataSource.getLastExerciseLog(userId, exerciseName);
    } catch (e) {
      // Don't throw for stats, just return null
      return null;
    }
  }

  Future<PersonalRecord?> getExercisePR({
    required String userId,
    required String exerciseName,
  }) async {
    try {
      return await _localDataSource.getExercisePR(userId, exerciseName);
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
      _log('getDraftWorkout: draft?.planName=${draft?.planName}');
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
