import '../../../core/models/workout_plan.dart';
import '../../../core/services/api_service.dart';

class PlanRepository {
  Future<WorkoutPlan> createPlan({
    required String userId,
    required String name,
    String? description,
    required List<String> exercises,
  }) async {
    try {
      final response = await ApiService.createPlan(
        userId: userId,
        name: name,
        description: description,
        exercises: exercises,
      );

      return _mapToWorkoutPlan(response);
    } catch (e) {
      throw Exception(_parseErrorMessage(e.toString()));
    }
  }

  Future<List<WorkoutPlan>> getPlans({required String userId}) async {
    try {
      final response = await ApiService.getPlans(userId: userId);

      return response.map((plan) => _mapToWorkoutPlan(plan)).toList();
    } catch (e) {
      throw Exception(_parseErrorMessage(e.toString()));
    }
  }

  Future<WorkoutPlan> getPlan({
    required String userId,
    required String planId,
  }) async {
    try {
      final response = await ApiService.getPlan(userId: userId, planId: planId);
      return _mapToWorkoutPlan(response);
    } catch (e) {
      throw Exception(_parseErrorMessage(e.toString()));
    }
  }

  Future<WorkoutPlan> updatePlan({
    required String userId,
    required String planId,
    required String name,
    String? description,
    required List<String> exercises,
  }) async {
    try {
      final response = await ApiService.updatePlan(
        userId: userId,
        planId: planId,
        name: name,
        description: description,
        exercises: exercises,
      );

      return _mapToWorkoutPlan(response);
    } catch (e) {
      throw Exception(_parseErrorMessage(e.toString()));
    }
  }

  Future<void> deletePlan({
    required String userId,
    required String planId,
  }) async {
    try {
      await ApiService.deletePlan(userId: userId, planId: planId);
    } catch (e) {
      throw Exception(_parseErrorMessage(e.toString()));
    }
  }

  WorkoutPlan _mapToWorkoutPlan(Map<String, dynamic> data) {
    final exercisesData = data['exercises'] as List<dynamic>? ?? [];
    final exercises = exercisesData
        .map((ex) => PlanExercise(
              id: ex['id'].toString(),
              name: ex['name'],
              order: ex['order'] as int? ?? 0,
            ))
        .toList();

    return WorkoutPlan(
      id: data['id'].toString(),
      userId: data['userId'].toString(),
      name: data['name'],
      description: data['description'],
      exercises: exercises,
      createdAt: data['createdAt'] != null
          ? DateTime.parse(data['createdAt'])
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null
          ? DateTime.parse(data['updatedAt'])
          : DateTime.now(),
    );
  }

  String _parseErrorMessage(String error) {
    if (error.contains('Exception: ')) {
      return error.replaceAll('Exception: ', '');
    }
    return error;
  }
}
