import 'package:sqflite/sqflite.dart';
import 'package:flutter/foundation.dart';
import '../../../core/models/workout_plan.dart';
import '../../../core/services/sqlite_service.dart';

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

      // Insert plan
      await SQLiteService.database.insert(
        'plans',
        {
          'id': plan.id,
          'user_id': plan.userId,
          'name': plan.name,
          'description': plan.description,
          'created_at': SQLiteService.formatDateTime(plan.createdAt),
          'updated_at': SQLiteService.formatDateTime(plan.updatedAt),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // Insert exercises
      for (final exercise in exercises) {
        await SQLiteService.database.insert(
          'plan_exercises',
          {
            'id': exercise.id,
            'plan_id': plan.id,
            'name': exercise.name,
            'exercise_order': exercise.order,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      return plan;
    } catch (e) {
      throw Exception('Failed to create plan: $e');
    }
  }

  /// Get all plans for a user from local database
  Future<List<WorkoutPlan>> getPlans({required String userId}) async {
    try {
      _log('SELECT', 'plans WHERE userId=$userId');
      final planRows = await SQLiteService.database.query(
        'plans',
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'updated_at DESC',
      );

      _log('SELECT', 'plans: Found ${planRows.length} records');
      final plans = <WorkoutPlan>[];
      for (final planRow in planRows) {
        final planId = planRow['id'] as String;
        _log('SELECT', 'plan_exercises WHERE planId=$planId');
        final exerciseRows = await SQLiteService.database.query(
          'plan_exercises',
          where: 'plan_id = ?',
          whereArgs: [planId],
          orderBy: 'exercise_order ASC',
        );

        _log('SELECT', 'plan_exercises: Found ${exerciseRows.length} records');        final exercises = exerciseRows
            .map((row) => PlanExercise(
                  id: row['id'] as String,
                  name: row['name'] as String,
                  order: row['exercise_order'] as int,
                ))
            .toList();

        plans.add(WorkoutPlan(
          id: planId,
          userId: planRow['user_id'] as String,
          name: planRow['name'] as String,
          description: planRow['description'] as String?,
          exercises: exercises,
          createdAt: SQLiteService.parseDateTime(planRow['created_at'] as String),
          updatedAt: SQLiteService.parseDateTime(planRow['updated_at'] as String),
        ));
      }

      return plans;
    } catch (e) {
      throw Exception('Failed to get plans: $e');
    }
  }

  /// Get a single plan from local database
  Future<WorkoutPlan> getPlan({required String planId}) async {
    try {
      final planRows = await SQLiteService.database.query(
        'plans',
        where: 'id = ?',
        whereArgs: [planId],
      );

      if (planRows.isEmpty) {
        throw Exception('Plan not found');
      }

      final planRow = planRows.first;
      final exerciseRows = await SQLiteService.database.query(
        'plan_exercises',
        where: 'plan_id = ?',
        whereArgs: [planId],
        orderBy: 'exercise_order ASC',
      );

      final exercises = exerciseRows
          .map((row) => PlanExercise(
                id: row['id'] as String,
                name: row['name'] as String,
                order: row['exercise_order'] as int,
              ))
          .toList();

      return WorkoutPlan(
        id: planId,
        userId: planRow['user_id'] as String,
        name: planRow['name'] as String,
        description: planRow['description'] as String?,
        exercises: exercises,
        createdAt: SQLiteService.parseDateTime(planRow['created_at'] as String),
        updatedAt: SQLiteService.parseDateTime(planRow['updated_at'] as String),
      );
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

      // Update plan
      await SQLiteService.database.update(
        'plans',
        {
          'name': name,
          'description': description,
          'updated_at': SQLiteService.formatDateTime(updatedPlan.updatedAt),
        },
        where: 'id = ?',
        whereArgs: [planId],
      );

      // Delete old exercises
      await SQLiteService.database.delete(
        'plan_exercises',
        where: 'plan_id = ?',
        whereArgs: [planId],
      );

      // Insert new exercises
      for (final exercise in exercises) {
        await SQLiteService.database.insert(
          'plan_exercises',
          {
            'id': exercise.id,
            'plan_id': planId,
            'name': exercise.name,
            'exercise_order': exercise.order,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      return updatedPlan;
    } catch (e) {
      throw Exception('Failed to update plan: $e');
    }
  }

  /// Delete a plan from local database
  Future<void> deletePlan({required String planId}) async {
    try {
      // Delete exercises first (cascade)
      await SQLiteService.database.delete(
        'plan_exercises',
        where: 'plan_id = ?',
        whereArgs: [planId],
      );

      // Delete plan
      await SQLiteService.database.delete(
        'plans',
        where: 'id = ?',
        whereArgs: [planId],
      );
    } catch (e) {
      throw Exception('Failed to delete plan: $e');
    }
  }

  /// Clear all plans for a user (useful for testing or reset)
  Future<void> clearUserPlans({required String userId}) async {
    try {
      // Get all plan IDs for the user
      final planRows = await SQLiteService.database.query(
        'plans',
        columns: ['id'],
        where: 'user_id = ?',
        whereArgs: [userId],
      );

      // Delete exercises for each plan
      for (final planRow in planRows) {
        await SQLiteService.database.delete(
          'plan_exercises',
          where: 'plan_id = ?',
          whereArgs: [planRow['id']],
        );
      }

      // Delete all plans for user
      await SQLiteService.database.delete(
        'plans',
        where: 'user_id = ?',
        whereArgs: [userId],
      );
    } catch (e) {
      throw Exception('Failed to clear user plans: $e');
    }
  }
}
