import 'package:flutter/foundation.dart';
import 'package:liftly/core/services/hive_service.dart';
import 'package:liftly/core/models/workout_plan.dart';

class PlanLocalDataSource {
  /// Log database operations
  static void _log(String operation, String message) {
    if (kDebugMode) {
      print('[PlanDB] $operation: $message');
    }
  }

  /// Create a new plan in local database
  Future<WorkoutPlan> createPlan({
    required String id,
    required String userId,
    required String name,
    String? description,
    required List<PlanExercise> exercises,
  }) async {
    try {
      final plan = WorkoutPlan(
        id: id,
        userId: userId,
        name: name,
        description: description,
        exercises: exercises,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await HiveService.createPlan(plan);
      _log('CREATE', 'Created plan: ${plan.id}');

      return plan;
    } catch (e) {
      throw Exception('Failed to create plan: $e');
    }
  }

  /// Get all plans for a user from local database
  Future<List<WorkoutPlan>> getPlans({required String userId}) async {
    try {
      final plans = await HiveService.getPlans(userId);
      _log('SELECT', 'Found ${plans.length} plans for user $userId');
      return plans;
    } catch (e) {
      throw Exception('Failed to get plans: $e');
    }
  }

  /// Get a single plan from local database
  Future<WorkoutPlan> getPlan({required String planId}) async {
    try {
      final plan = await HiveService.getPlan(planId);
      if (plan == null) {
        throw Exception('Plan not found');
      }
      return plan;
    } catch (e) {
      throw Exception('Failed to get plan: $e');
    }
  }

  /// Update an existing plan in local database
  Future<WorkoutPlan> updatePlan({
    required String planId,
    required String name,
    String? description,
    required List<PlanExercise> exercises,
  }) async {
    try {
      // Get existing plan to preserve user_id and creation date
      final existingPlan = await getPlan(planId: planId);

      final updatedPlan = WorkoutPlan(
        id: planId,
        userId: existingPlan.userId,
        name: name,
        description: description,
        exercises: exercises,
        createdAt: existingPlan.createdAt,
        updatedAt: DateTime.now(),
      );

      await HiveService.createPlan(updatedPlan); // Update overwrites in Hive
      _log('UPDATE', 'Updated plan: $planId');

      return updatedPlan;
    } catch (e) {
      throw Exception('Failed to update plan: $e');
    }
  }

  /// Delete a plan from local database
  Future<void> deletePlan({required String planId}) async {
    try {
      await HiveService.deletePlan(planId);
      _log('DELETE', 'Deleted plan: $planId');
    } catch (e) {
      throw Exception('Failed to delete plan: $e');
    }
  }
}
