import '../../../core/models/workout_plan.dart';
import '../data_sources/plan_local_data_source.dart';

class PlanRepository {
  final PlanLocalDataSource _localDataSource = PlanLocalDataSource();

  Future<WorkoutPlan> createPlan({
    required String userId,
    required String name,
    String? description,
    required List<String> exercises,
    List<String>? exerciseVariations,
  }) async {
    try {
      // Generate local ID (timestamp based)
      final id = DateTime.now().millisecondsSinceEpoch.toString();

      // Convert exercise strings to PlanExercise objects with order
      final planExercises = exercises
          .asMap()
          .entries
          .map((entry) {
            final variation = (exerciseVariations != null &&
                    entry.key < exerciseVariations.length)
                ? exerciseVariations[entry.key]
                : '';
            return PlanExercise(
              id: '${id}_${entry.key}',
              name: entry.value,
              order: entry.key,
              variation: variation,
            );
          })
          .toList();

      // Save to local database
      final plan = await _localDataSource.createPlan(
        id: id,
        userId: userId,
        name: name,
        description: description,
        exercises: planExercises,
      );

      return plan;
    } catch (e) {
      throw Exception(_parseErrorMessage(e.toString()));
    }
  }

  Future<List<WorkoutPlan>> getPlans({required String userId}) async {
    try {
      // Get from local database
      final plans = await _localDataSource.getPlans(userId: userId);
      return plans;
    } catch (e) {
      throw Exception(_parseErrorMessage(e.toString()));
    }
  }

  Future<WorkoutPlan> getPlan({
    required String userId,
    required String planId,
  }) async {
    try {
      // Get from local database
      final plan = await _localDataSource.getPlan(planId: planId);
      return plan;
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
    List<String>? exerciseVariations,
  }) async {
    try {
      // Convert exercise strings to PlanExercise objects with order
      final planExercises = exercises
          .asMap()
          .entries
          .map((entry) {
            final variation = (exerciseVariations != null &&
                    entry.key < exerciseVariations.length)
                ? exerciseVariations[entry.key]
                : '';
            return PlanExercise(
              id: '${planId}_${entry.key}',
              name: entry.value,
              order: entry.key,
              variation: variation,
            );
          })
          .toList();

      // Update in local database
      final plan = await _localDataSource.updatePlan(
        planId: planId,
        name: name,
        description: description,
        exercises: planExercises,
      );

      return plan;
    } catch (e) {
      throw Exception(_parseErrorMessage(e.toString()));
    }
  }

  Future<void> deletePlan({
    required String userId,
    required String planId,
  }) async {
    try {
      // Delete from local database
      await _localDataSource.deletePlan(planId: planId);
    } catch (e) {
      throw Exception(_parseErrorMessage(e.toString()));
    }
  }

  String _parseErrorMessage(String error) {
    if (error.contains('Exception: ')) {
      return error.replaceAll('Exception: ', '');
    }
    return error;
  }
}
