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

      if (!response.success || response.data == null) {
        throw Exception(response.message);
      }

      return _mapPlanResponseToWorkoutPlan(response.data!);
    } catch (e) {
      throw Exception(_parseErrorMessage(e.toString()));
    }
  }

  Future<List<WorkoutPlan>> getPlans({required String userId}) async {
    try {
      final response = await ApiService.getPlans(userId: userId);

      if (!response.success || response.data == null) {
        throw Exception(response.message);
      }

      return response.data!.map((plan) => _mapPlanResponseToWorkoutPlan(plan)).toList();
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

      if (!response.success || response.data == null) {
        throw Exception(response.message);
      }

      return _mapPlanResponseToWorkoutPlan(response.data!);
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

      if (!response.success || response.data == null) {
        throw Exception(response.message);
      }

      return _mapPlanResponseToWorkoutPlan(response.data!);
    } catch (e) {
      throw Exception(_parseErrorMessage(e.toString()));
    }
  }

  Future<void> deletePlan({
    required String userId,
    required String planId,
  }) async {
    try {
      final response = await ApiService.deletePlan(userId: userId, planId: planId);
      if (!response.success) {
        throw Exception(response.message);
      }
    } catch (e) {
      throw Exception(_parseErrorMessage(e.toString()));
    }
  }

  WorkoutPlan _mapPlanResponseToWorkoutPlan(PlanResponse planResponse) {
    final exercises = planResponse.exercises
        .map((ex) => PlanExercise(
              id: ex.id,
              name: ex.name,
              order: ex.order,
            ))
        .toList();

    return WorkoutPlan(
      id: planResponse.id,
      userId: planResponse.userId,
      name: planResponse.name,
      description: planResponse.description,
      exercises: exercises,
      createdAt: planResponse.createdAt,
      updatedAt: planResponse.updatedAt,
    );
  }

  String _parseErrorMessage(String error) {
    if (error.contains('Exception: ')) {
      return error.replaceAll('Exception: ', '');
    }
    return error;
  }
}
