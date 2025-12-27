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

      if (!response.success) {
        throw Exception(response.message);
      }

      return response.data ?? {};
    } catch (e) {
      throw Exception(_parseErrorMessage(e.toString()));
    }
  }

  Future<List<Map<String, dynamic>>> getWorkouts({
    required String userId,
  }) async {
    try {
      final response = await ApiService.getWorkoutsTyped(userId: userId);

      if (!response.success) {
        throw Exception(response.message);
      }

      return response.data ?? [];
    } catch (e) {
      throw Exception(_parseErrorMessage(e.toString()));
    }
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

      if (!response.success) {
        throw Exception(response.message);
      }

      return response.data ?? {};
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
}
