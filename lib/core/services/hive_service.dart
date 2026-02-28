import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:liftly/core/models/workout_metadata.dart';
import 'package:liftly/core/models/workout_plan.dart';
import 'package:liftly/core/models/workout_session.dart';
import 'package:liftly/core/models/personal_record.dart';
import 'package:liftly/core/services/statistics_service.dart';
import 'package:liftly/core/utils/app_logger.dart';
import 'package:liftly/core/utils/persistence_helper.dart';
import 'package:liftly/core/constants/app_constants.dart';
import 'package:path_provider/path_provider.dart';

class HiveService {
  static const String _workoutBoxName = AppConstants.workoutBox;
  static const String _planBoxName = AppConstants.planBox;
  static const String _settingsBoxName = AppConstants.settingsBox;
  static const String _metaBoxName = AppConstants.metaBox;

  static late Box<WorkoutSession> _workoutBox;
  static late Box<WorkoutPlan> _planBox;
  static late Box<String> _settingsBox;
  static late Box<WorkoutMetadata> _metaBox;

  static bool _isInitialized = false;
  static Completer<void>? _initCompleter;

  // Cache for PRs to avoid re-calculating on every request
  static final Map<String, PersonalRecord> _prCache = {};

  // Cache for exercise history to avoid re-scanning workouts
  // Key: "userId:exerciseName", Value: List of history records
  static final Map<String, List<Map<String, dynamic>>> _exerciseHistoryCache =
      {};

  // Cache for exercise names to avoid re-scanning workouts
  // Key: userId, Value: Set of exercise names
  static final Map<String, Set<String>> _exerciseNamesCache = {};

  // Lightweight Index for History Page Optimization
  // Key: userId, Value: List of (id, date) sorted by date DESC.
  static final Map<String, List<({String id, DateTime date, bool isDraft})>>
      _workoutIndexCache = {};

  // Cache for getLastExerciseLog to avoid a full scan per exercise on every call.
  // Key: "userId:exerciseName:variation", Value: last WorkoutSession (nullable).
  static final Map<String, WorkoutSession?> _lastExerciseLogCache = {};

  // Initialize Hive
  static Future<void> init() async {
    if (_isInitialized) return;

    if (_initCompleter != null) {
      return _initCompleter!.future;
    }

    _initCompleter = Completer<void>();

    try {
      if (!kIsWeb) {
        final dir = await getApplicationDocumentsDirectory();
        await Hive.initFlutter(dir.path);
      } else {
        await Hive.initFlutter();
        // Request storage persistence on web
        await requestPersistence();
      }

      // Register Adapters
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(WorkoutSessionAdapter());
      }
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(SessionExerciseAdapter());
      }
      if (!Hive.isAdapterRegistered(2)) {
        Hive.registerAdapter(ExerciseSetAdapter());
      }
      if (!Hive.isAdapterRegistered(3)) {
        Hive.registerAdapter(SetSegmentAdapter());
      }
      if (!Hive.isAdapterRegistered(4)) {
        Hive.registerAdapter(WorkoutPlanAdapter());
      }
      if (!Hive.isAdapterRegistered(5)) {
        Hive.registerAdapter(PlanExerciseAdapter());
      }
      if (!Hive.isAdapterRegistered(6)) {
        Hive.registerAdapter(WorkoutMetadataAdapter());
      }

      // Open Boxes
      _workoutBox = await Hive.openBox<WorkoutSession>(_workoutBoxName);
      _planBox = await Hive.openBox<WorkoutPlan>(_planBoxName);
      _settingsBox = await Hive.openBox<String>(_settingsBoxName);
      _metaBox = await Hive.openBox<WorkoutMetadata>(_metaBoxName);

      // Startup Integrity Check
      await _checkMetadataIntegrity();

      // Data Migration: notes -> variation
      await _migrateVariationField();

      _isInitialized = true;
      _initCompleter!.complete();
    } catch (e) {
      if (_initCompleter != null && !_initCompleter!.isCompleted) {
        _initCompleter!.completeError(e);
      }
      rethrow;
    } finally {
      _initCompleter = null;
    }
  }

  static void _invalidatePRCache(
      {String? userId, String? exerciseName, String? exerciseVariation}) {
    if (userId != null && exerciseName != null) {
      final variation = exerciseVariation ?? '';
      final key =
          '$userId:${exerciseName.toLowerCase()}:${variation.toLowerCase()}';
      _prCache.remove(key);
    } else if (userId != null) {
      _prCache.removeWhere((key, _) => key.startsWith('$userId:'));
    } else {
      _prCache.clear();
    }
  }

  static void _invalidateExerciseHistoryCache(
      {String? userId, String? exerciseName, String? exerciseVariation}) {
    if (userId != null && exerciseName != null) {
      final variation = exerciseVariation ?? '';
      final key =
          '$userId:${exerciseName.toLowerCase()}:${variation.toLowerCase()}';
      _exerciseHistoryCache.remove(key);
    } else if (userId != null) {
      _exerciseHistoryCache.removeWhere((key, _) => key.startsWith('$userId:'));
    } else {
      _exerciseHistoryCache.clear();
    }
  }

  static void _invalidateExerciseNamesCache({String? userId}) {
    if (userId != null) {
      _exerciseNamesCache.remove(userId);
    } else {
      _exerciseNamesCache.clear();
    }
  }

  static void _invalidateWorkoutCache({String? userId}) {
    if (userId != null) {
      _workoutIndexCache.remove(userId);
    } else {
      _workoutIndexCache.clear();
    }
  }

  static void _invalidateLastExerciseLogCache(
      {String? userId, String? exerciseName, String? exerciseVariation}) {
    if (userId != null && exerciseName != null) {
      final variation = exerciseVariation ?? '';
      final key =
          '$userId:${exerciseName.toLowerCase()}:${variation.toLowerCase()}';
      _lastExerciseLogCache.remove(key);
    } else if (userId != null) {
      _lastExerciseLogCache.removeWhere((key, _) => key.startsWith('$userId:'));
    } else {
      _lastExerciseLogCache.clear();
    }
  }

  static Future<void> _checkMetadataIntegrity() async {
    if (_metaBox.isEmpty && _workoutBox.isNotEmpty) {
      AppLogger.debug('HiveService', 'Meta box empty, rebuilding index...');
      final metaMap = <String, WorkoutMetadata>{};
      for (final w in _workoutBox.values) {
        metaMap[w.id] = WorkoutMetadata(
          id: w.id,
          userId: w.userId,
          date: w.workoutDate,
          isDraft: w.isDraft,
        );
      }
      await _metaBox.putAll(metaMap);
      AppLogger.debug('HiveService', 'Index rebuilt with ${metaMap.length} items.');
    }
  }

  static Future<void> _migrateVariationField() async {
    final migrationKey = 'variation_migration_complete';
    final isComplete = _settingsBox.get(migrationKey) == 'true';

    if (isComplete) return;

    // The notes→variation field migration was applied in-place at the Hive
    // adapter level. Writing this marker prevents re-running on future launches.
    await _settingsBox.put(migrationKey, 'true');
  }

  // ================= Workouts =================

  static Future<void> createWorkout(WorkoutSession workout) async {
    await init();
    await _workoutBox.put(workout.id, workout);
    await _metaBox.put(
        workout.id,
        WorkoutMetadata(
          id: workout.id,
          userId: workout.userId,
          date: workout.workoutDate,
          isDraft: workout.isDraft,
        ));

    // Invalidate caches for affected exercises
    for (final exercise in workout.exercises) {
      _invalidatePRCache(
          userId: workout.userId,
          exerciseName: exercise.name,
          exerciseVariation: exercise.variation);
      _invalidateExerciseHistoryCache(
          userId: workout.userId,
          exerciseName: exercise.name,
          exerciseVariation: exercise.variation);
      _invalidateLastExerciseLogCache(
          userId: workout.userId,
          exerciseName: exercise.name,
          exerciseVariation: exercise.variation);
    }
    _invalidateWorkoutCache(userId: workout.userId);
    _invalidateExerciseNamesCache(userId: workout.userId);
  }

  static Future<void> importWorkouts(List<WorkoutSession> workouts) async {
    await init();
    final workoutMap = {for (var w in workouts) w.id: w};
    final metaMap = {
      for (var w in workouts)
        w.id: WorkoutMetadata(
          id: w.id,
          userId: w.userId,
          date: w.workoutDate,
          isDraft: w.isDraft,
        )
    };

    await _workoutBox.putAll(workoutMap);
    await _metaBox.putAll(metaMap);

    // Clear all caches on import
    _invalidatePRCache();
    _invalidateWorkoutCache();
    _invalidateExerciseHistoryCache();
    _invalidateLastExerciseLogCache();
    _invalidateExerciseNamesCache();
  }

  static Future<List<WorkoutSession>> getWorkouts(String userId,
      {bool includeDrafts = false, int offset = 0, int? limit}) async {
    await init();

    // 1. Get the sorted index (FAST: read from meta box)
    if (!_workoutIndexCache.containsKey(userId)) {
      final index = _metaBox.values
          .where((m) => m.userId == userId)
          .map((m) => (id: m.id, date: m.date, isDraft: m.isDraft))
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date));
      _workoutIndexCache[userId] = index;
    }

    final fullIndex = _workoutIndexCache[userId]!;

    // 2. Filter index (still fast)
    Iterable<({String id, DateTime date, bool isDraft})> filteredIndex =
        fullIndex;
    if (!includeDrafts) {
      filteredIndex = filteredIndex.where((item) => !item.isDraft);
    }

    // 3. Apply pagination to the index
    final pagedIndex = limit == null
        ? filteredIndex.skip(offset)
        : filteredIndex.skip(offset).take(limit);

    // 4. Fetch full objects ONLY for the current page
    final results = <WorkoutSession>[];
    for (final item in pagedIndex) {
      final workout = _workoutBox.get(item.id);
      if (workout != null) {
        results.add(workout);
      }
    }

    return results;
  }

  static Future<WorkoutSession?> getWorkout(String id) async {
    await init();
    return _workoutBox.get(id);
  }

  static Future<void> deleteWorkout(String id) async {
    await init();
    final workout = _workoutBox.get(id);
    await _workoutBox.delete(id);
    await _metaBox.delete(id);

    if (workout != null) {
      for (final exercise in workout.exercises) {
        _invalidatePRCache(
            userId: workout.userId,
            exerciseName: exercise.name,
            exerciseVariation: exercise.variation);
        _invalidateExerciseHistoryCache(
            userId: workout.userId,
            exerciseName: exercise.name,
            exerciseVariation: exercise.variation);
        _invalidateLastExerciseLogCache(
            userId: workout.userId,
            exerciseName: exercise.name,
            exerciseVariation: exercise.variation);
      }
      _invalidateWorkoutCache(userId: workout.userId);
      _invalidateExerciseNamesCache(userId: workout.userId);
    }
  }

  static Future<void> updateWorkout(WorkoutSession workout) async {
    await init();
    await _workoutBox.put(workout.id, workout);
    
    await _metaBox.put(
        workout.id,
        WorkoutMetadata(
          id: workout.id,
          userId: workout.userId,
          date: workout.workoutDate,
          isDraft: workout.isDraft,
        ));
    for (final exercise in workout.exercises) {
      _invalidatePRCache(
          userId: workout.userId,
          exerciseName: exercise.name,
          exerciseVariation: exercise.variation);
      _invalidateExerciseHistoryCache(
          userId: workout.userId,
          exerciseName: exercise.name,
          exerciseVariation: exercise.variation);
      _invalidateLastExerciseLogCache(
          userId: workout.userId,
          exerciseName: exercise.name,
          exerciseVariation: exercise.variation);
    }
    _invalidateWorkoutCache(userId: workout.userId);
    _invalidateExerciseNamesCache(userId: workout.userId);
  }

  static Future<WorkoutSession?> getDraftWorkout(String userId) async {
    await init();
    try {
      // Find latest draft
      final drafts = _workoutBox.values
          .where((w) => w.userId == userId && w.isDraft)
          .toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

      if (drafts.isEmpty) return null;
      return drafts.first;
    } catch (e) {
      return null;
    }
  }

  static Future<void> discardDrafts(String userId) async {
    await init();
    final drafts = _workoutBox.values
        .where((w) => w.userId == userId && w.isDraft)
        .toList();

    for (final draft in drafts) {
      await deleteWorkout(draft.id);
    }
  }

  // ================= Plans =================

  static Future<void> createPlan(WorkoutPlan plan) async {
    await init();
    await _planBox.put(plan.id, plan);
  }

  static Future<void> importPlans(List<WorkoutPlan> plans) async {
    await init();
    final map = {for (var p in plans) p.id: p};
    await _planBox.putAll(map);
  }

  static Future<List<WorkoutPlan>> getPlans(String userId) async {
    await init();
    return _planBox.values.where((p) => p.userId == userId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  static Future<WorkoutPlan?> getPlan(String id) async {
    await init();
    return _planBox.get(id);
  }

  static Future<void> deletePlan(String id) async {
    await init();
    await _planBox.delete(id);
  }

  static Future<void> updatePlan(WorkoutPlan plan) async {
    await init();
    await _planBox.put(plan.id, plan);
  }

  // ================= Preferences =================

  static Future<void> savePreference(String key, String value) async {
    await init();
    await _settingsBox.put(key, value);
  }

  static Future<String?> getPreference(String key) async {
    await init();
    return _settingsBox.get(key);
  }

  // ================= Statistics / Analytics =================

  static Future<List<Map<String, dynamic>>> getExerciseHistory(
      String userId, String exerciseName,
      {String exerciseVariation = ''}) async {
    await init();

    // Check cache first
    final cacheKey =
        '$userId:${exerciseName.toLowerCase()}:${exerciseVariation.toLowerCase()}';
    if (_exerciseHistoryCache.containsKey(cacheKey)) {
      return _exerciseHistoryCache[cacheKey]!;
    }

    final history = <Map<String, dynamic>>[];
    final workouts = _workoutBox.values
        .where((w) => w.userId == userId && !w.isDraft)
        .toList()
      ..sort((a, b) => a.workoutDate.compareTo(b.workoutDate)); // Ascending

    for (final w in workouts) {
      for (final ex in w.exercises) {
        if (ex.name.toLowerCase() == exerciseName.toLowerCase() &&
            ex.variation.toLowerCase() == exerciseVariation.toLowerCase() &&
            !ex.skipped) {
          final metrics = StatisticsService.calculateSessionMetrics(
            ex,
            w.workoutDate,
            ex.sets,
          );
          history.add(metrics);
        }
      }
    }

    // Cache the result
    _exerciseHistoryCache[cacheKey] = history;
    return history;
  }

  static Future<WorkoutSession?> getLastExerciseLog(
      String userId, String exerciseName,
      {String exerciseVariation = ''}) async {
    await init();
    final cacheKey =
        '$userId:${exerciseName.toLowerCase()}:${exerciseVariation.toLowerCase()}';
    if (_lastExerciseLogCache.containsKey(cacheKey)) {
      return _lastExerciseLogCache[cacheKey];
    }

    final workouts = _workoutBox.values
        .where((w) => w.userId == userId && !w.isDraft)
        .toList()
      ..sort((a, b) => b.workoutDate.compareTo(a.workoutDate)); // DESC

    for (final w in workouts) {
      for (final ex in w.exercises) {
        if (ex.name.toLowerCase() == exerciseName.toLowerCase() &&
            ex.variation.toLowerCase() == exerciseVariation.toLowerCase() &&
            !ex.skipped) {
          _lastExerciseLogCache[cacheKey] = w;
          return w;
        }
      }
    }
    _lastExerciseLogCache[cacheKey] = null;
    return null;
  }

  static Future<List<String>> getExerciseNames(String userId) async {
    await init();

    // Check cache first
    if (_exerciseNamesCache.containsKey(userId)) {
      return _exerciseNamesCache[userId]!.toList()..sort();
    }

    final names = <String>{};
    for (final w in _workoutBox.values) {
      if (w.userId == userId) {
        for (final ex in w.exercises) {
          names.add(ex.name);
        }
      }
    }

    // Cache the result
    _exerciseNamesCache[userId] = names;
    return names.toList()..sort();
  }

  static Future<List<String>> getExerciseVariations(
    String userId,
    String exerciseName,
  ) async {
    await init();
    final variations = <String>{};
    final lowerName = exerciseName.toLowerCase();

    // Scan workout history
    for (final w in _workoutBox.values) {
      if (w.userId == userId) {
        for (final ex in w.exercises) {
          if (ex.name.toLowerCase() == lowerName && ex.variation.isNotEmpty) {
            variations.add(ex.variation);
          }
        }
      }
    }

    // Scan workout plans
    for (final p in _planBox.values) {
      if (p.userId == userId) {
        for (final ex in p.exercises) {
          if (ex.name.toLowerCase() == lowerName && ex.variation.isNotEmpty) {
            variations.add(ex.variation);
          }
        }
      }
    }

    return variations.toList()..sort();
  }

  static Future<PersonalRecord?> getExercisePR(
      String userId, String exerciseName,
      {DateTime? startDate,
      DateTime? endDate,
      String exerciseVariation = ''}) async {
    // Check cache
    if (startDate == null && endDate == null) {
      final cacheKey =
          '$userId:${exerciseName.toLowerCase()}:${exerciseVariation.toLowerCase()}';
      if (_prCache.containsKey(cacheKey)) {
        return _prCache[cacheKey];
      }
    }

    final history = await getExerciseHistory(userId, exerciseName,
        exerciseVariation: exerciseVariation);

    if (history.isEmpty) return null;

    final filteredHistory = history.where((record) {
      final date = DateTime.parse(record['workoutDate'] as String);
      if (startDate != null && date.isBefore(startDate)) return false;
      if (endDate != null && date.isAfter(endDate)) return false;
      return true;
    }).toList();

    final pr = StatisticsService.calculatePRFromHistory(
        exerciseName, filteredHistory,
        variation: exerciseVariation);

    // Cache
    if (startDate == null && endDate == null && pr != null) {
      final cacheKey =
          '$userId:${exerciseName.toLowerCase()}:${exerciseVariation.toLowerCase()}';
      _prCache[cacheKey] = pr;
    }

    return pr;
  }

  static Future<Map<String, PersonalRecord>> getAllPersonalRecords(
      String userId,
      {DateTime? startDate,
      DateTime? endDate}) async {
    await init();

    final workouts = _workoutBox.values
        .where((w) => w.userId == userId && !w.isDraft)
        .toList();

    // Filter by date if needed
    final filteredWorkouts = workouts.where((w) {
      if (startDate != null && w.workoutDate.isBefore(startDate)) return false;
      if (endDate != null && w.workoutDate.isAfter(endDate)) return false;
      return true;
    }).toList()
      ..sort((a, b) => a.workoutDate.compareTo(b.workoutDate));

    // Single pass: collect all exercise session data
    // Also track original exercise names and variations for display
    final exerciseHistories = <String, List<Map<String, dynamic>>>{};
    final originalExerciseData = <String, (String name, String variation)>{};
    
    for (final w in filteredWorkouts) {
      for (final ex in w.exercises) {
        if (ex.skipped) continue;

        final exerciseNameLower = ex.name.toLowerCase();
        final variationLower = ex.variation.toLowerCase();
        final key = '$exerciseNameLower:$variationLower';
        
        exerciseHistories.putIfAbsent(key, () => []);
        // Store original case for later display
        originalExerciseData[key] = (ex.name, ex.variation);

        final metrics = StatisticsService.calculateSessionMetrics(
          ex,
          w.workoutDate,
          ex.sets,
        );

        exerciseHistories[key]!.add(metrics);
      }
    }

    // Calculate PRs from collected data
    final results = <String, PersonalRecord>{};
    for (final entry in exerciseHistories.entries) {
      // Extract exercise name from key (format: exerciseName:variation)
      final originalData = originalExerciseData[entry.key];
      final originalExerciseName = originalData?.$1 ?? entry.key.split(':').first;
      final originalVariation = originalData?.$2 ?? '';
      
      final pr = StatisticsService.calculatePRFromHistory(
        originalExerciseName,
        entry.value,
        variation: originalVariation,
      );
      if (pr != null) {
        results[entry.key] = pr;
      }
    }

    return results;
  }

  // ================= Utility =================

  static Future<void> clearAllData() async {
    await init();
    await _workoutBox.clear();
    await _planBox.clear();
    await _settingsBox.clear();
    await _metaBox.clear();
    _prCache.clear();
    _exerciseHistoryCache.clear();
    _lastExerciseLogCache.clear();
    _exerciseNamesCache.clear();
    _invalidateWorkoutCache();
  }

  /// Returns a Map suitable for export logic
  static Future<Map<String, dynamic>> getAllDataForExport() async {
    await init();
    return {
      'workouts': _workoutBox.values.toList(),
      'plans': _planBox.values.toList(),
    };
  }
}
