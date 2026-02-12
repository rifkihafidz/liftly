import 'package:liftly/core/services/isar_service.dart';
import 'package:liftly/core/models/workout_plan.dart';
import 'package:liftly/core/services/sqlite_service.dart';
import 'package:liftly/features/workout_log/data_sources/legacy_workout_data_source.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Using SharedPreferences for migration flag as it's separate from DBs

class MigrationService {
  static const String _migrationKey = 'is_sqlite_migrated_v1';

  /// Performs migration from SQLite to Isar if not already done.
  /// Returns true if migration was performed, false otherwise.
  static Future<bool> migrateIfNeeded() async {
    // Only run migration on mobile/desktop where SQLite exists.
    // Web has no SQLite data to migrate (it was failing anyway).
    if (kIsWeb) return false;

    final prefs = await SharedPreferences.getInstance();
    final isMigrated = prefs.getBool(_migrationKey) ?? false;

    if (isMigrated) {
      if (kDebugMode) {
        print('[Migration] Already migrated.');
      }
      return false;
    }

    if (kDebugMode) {
      print('[Migration] Starting migration from SQLite to Isar...');
    }

    try {
      // 1. Initialize SQLite (Legacy)
      await SQLiteService.initDatabase();

      // 2. Fetch all data using existing DataSource methodology
      // We use the existing data source which is tied to SQLiteService currently
      final legacyDataSource = LegacyWorkoutDataSource();

      // Get ALL workouts including drafts
      // Note: passing userId is tricky if we support multiple users.
      // Assuming single local user or logic to fetch all.
      // WorkoutLocalDataSource requires userId.
      // We need to fetch ALL workouts regardless of user for full migration.
      // But DataSource is user-scoped.

      // Approach: Query raw table list of user_ids from SQLite first?
      // Or just fetch for current user?
      // The app seems to use hardcoded 'user_1' or similar in some places?
      // Let's check how userId is handled.
      // If we can't easily get all users, for a personal app, maybe migration
      // happens when user logs in?
      // BETTER: Query distinct user_ids from 'workouts' table directly via SQLiteService.

      final usersResult = await SQLiteService.database
          .rawQuery('SELECT DISTINCT user_id FROM workouts');
      final userIds =
          usersResult.map((row) => row['user_id'] as String).toList();

      if (userIds.isEmpty) {
        if (kDebugMode) {
          print('[Migration] No users found in SQLite. Marking as migrated.');
        }
        await prefs.setBool(_migrationKey, true);
        return true;
      }

      for (final userId in userIds) {
        if (kDebugMode) {
          print('[Migration] Migrating data for user: $userId');
        }
        // Use includeDrafts: true to get everything
        final workouts = await legacyDataSource.getWorkouts(userId,
            includeDrafts: true, limit: 0);

        for (final workout in workouts) {
          await IsarService.createWorkout(workout);
        }

        // Also migrate preferences?
        // SQLiteService has preferences table.
        // Let's migrate them too.
        final prefsResult = await SQLiteService.database.query('preferences');
        for (final row in prefsResult) {
          final key = row['key'] as String;
          final value = row['value'] as String;

          await IsarService.savePreference(key, value);
        }
      }

      // 4. Migrate Plans
      if (kDebugMode) print('[Migration] Migrating Plans...');
      final plansData = await SQLiteService.database.query('plans');
      for (final pRow in plansData) {
        try {
          final planId = pRow['id'] as String;
          final planUserId = pRow['user_id'] as String;

          final exercisesData = await SQLiteService.database.query(
            'plan_exercises',
            where: 'plan_id = ?',
            whereArgs: [planId],
            orderBy: 'exercise_order ASC',
          );

          final exercises = exercisesData.map((eRow) {
            // Assuming ID exists or generating one
            String exId =
                eRow['id'] as String? ?? '${planId}_${eRow['exercise_order']}';
            return PlanExercise(
              id: exId,
              name: eRow['name'] as String,
              order: eRow['exercise_order'] as int,
            );
          }).toList();

          final plan = WorkoutPlan(
            id: planId,
            userId: planUserId,
            name: pRow['name'] as String,
            description: pRow['description'] as String?,
            exercises: exercises,
            createdAt: DateTime.tryParse(pRow['created_at'] as String? ?? '') ??
                DateTime.now(),
            updatedAt: DateTime.tryParse(pRow['updated_at'] as String? ?? '') ??
                DateTime.now(),
          );

          await IsarService.createPlan(plan);
        } catch (e) {
          if (kDebugMode) {
            print('[Migration] Failed to migrate plan ${pRow['id']}: $e');
          }
        }
      }

      // 3. Mark as migrated
      await prefs.setBool(_migrationKey, true);

      // 4. Cleanup
      // We keep SQLite DB file for backup, but won't use it.
      await SQLiteService.closeDatabase();

      if (kDebugMode) print('[Migration] Migration completed successfully.');
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('[Migration] FAILED: $e');
      }
      // Do not mark as migrated so we retry next time
      rethrow;
    }
  }
}
