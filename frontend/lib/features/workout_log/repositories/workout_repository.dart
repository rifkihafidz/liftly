import '../../../core/models/workout_session.dart';
import '../../../core/services/api_service.dart';

class WorkoutRepository {
  Future<Map<String, dynamic>> createWorkout({
    required String userId,
    required Map<String, dynamic> workoutData,
  }) async {
    try {
      final response = await ApiService.createWorkout(
        userId: userId,
        workoutData: workoutData,
      );

      
      if (!response.success || response.data == null) {
        throw Exception(response.message);
      }

      return _workoutResponseToMap(response.data!);
    } catch (e) {
      throw Exception(_parseErrorMessage(e.toString()));
    }
  }

  Future<List<WorkoutSession>> getWorkouts({
    required String userId,
  }) async {
    try {
      final response = await ApiService.getWorkouts(userId: userId);

      if (!response.success || response.data == null) {
        throw Exception(response.message);
      }

      
      return response.data!.map((workoutResponse) {
        return _convertWorkoutResponseToSession(workoutResponse);
      }).toList();
    } catch (e) {
      rethrow;
    }
  }

  WorkoutSession _convertWorkoutResponseToSession(WorkoutResponse response) {
    // Convert WorkoutResponse directly to WorkoutSession
    final exercises = response.exercises.map((exercise) {
      final sets = exercise.sets.map((set) {
        final segments = set.segments.map((segment) {
          return SetSegment(
            id: segment.id,
            weight: segment.weight,
            repsFrom: segment.repsFrom,
            repsTo: segment.repsTo,
            segmentOrder: segment.segmentOrder,
            notes: segment.notes,
          );
        }).toList();
        
        return ExerciseSet(
          id: set.id,
          setNumber: set.setNumber,
          segments: segments,
        );
      }).toList();
      
      return SessionExercise(
        id: exercise.id,
        name: exercise.name,
        order: exercise.order,
        skipped: exercise.skipped,
        sets: sets,
      );
    }).toList();

    return WorkoutSession(
      id: response.id,
      userId: response.userId,
      planId: response.planId,
      workoutDate: response.workoutDate,
      startedAt: response.startedAt,
      endedAt: response.endedAt,
      exercises: exercises,
      createdAt: response.createdAt,
      updatedAt: response.updatedAt,
    );
  }

  Future<Map<String, dynamic>> updateWorkout({
    required String userId,
    required String workoutId,
    required Map<String, dynamic> workoutData,
  }) async {
    try {
      final response = await ApiService.updateWorkout(
        userId: userId,
        workoutId: workoutId,
        workoutData: workoutData,
      );

      if (!response.success || response.data == null) {
        throw Exception(response.message);
      }

      return _workoutResponseToMap(response.data!);
    } catch (e) {
      throw Exception(_parseErrorMessage(e.toString()));
    }
  }

  Future<void> deleteWorkout({
    required String userId,
    required String workoutId,
  }) async {
    try {
      final response = await ApiService.deleteWorkout(
        userId: userId,
        workoutId: workoutId,
      );

      if (!response.success) {
        throw Exception(response.message);
      }
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

  Map<String, dynamic> _workoutResponseToMap(dynamic response) {
    // If it's already a Map, return as-is
    if (response is Map<String, dynamic>) {
      return response;
    }
    
    // Handle WorkoutResponse typed object
    // Access properties directly, not with []
    try {
      final map = {
        'id': response.id ?? '',
        'userId': response.userId ?? '',
        'planId': response.planId ?? '',
        'workoutDate': response.date?.toIso8601String() ?? DateTime.now().toIso8601String(),
        'startedAt': response.date?.toIso8601String(),
        'endedAt': response.date?.toIso8601String(),
        'exercises': [],
        'createdAt': response.createdAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
        'updatedAt': response.updatedAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
      };
      return map;
    } catch (e) {
      
      // Last resort - try to convert dynamically
      try {
        return {
          'id': response.id.toString(),
          'userId': response.userId.toString(),
          'planId': response.planId.toString(),
          'workoutDate': response.date.toIso8601String(),
          'startedAt': response.date.toIso8601String(),
          'endedAt': response.date.toIso8601String(),
          'exercises': [],
          'createdAt': response.createdAt.toIso8601String(),
          'updatedAt': response.updatedAt.toIso8601String(),
        };
      } catch (e2) {
        return {};
      }
    }
  }
}

