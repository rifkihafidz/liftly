import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:liftly/core/models/workout_metadata.dart';
import 'package:liftly/core/models/workout_plan.dart';
import 'package:liftly/core/models/workout_session.dart';
import 'package:liftly/core/models/personal_record.dart';
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

  static void _invalidatePRCache({String? userId, String? exerciseName}) {
    if (userId != null && exerciseName != null) {
      _prCache.remove('$userId:${exerciseName.toLowerCase()}');
    } else if (userId != null) {
      _prCache.removeWhere((key, _) => key.startsWith('$userId:'));
    } else {
      _prCache.clear();
    }
  }

  static void _invalidateExerciseHistoryCache(
      {String? userId, String? exerciseName}) {
    if (userId != null && exerciseName != null) {
      _exerciseHistoryCache.remove('$userId:${exerciseName.toLowerCase()}');
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

  static Future<void> _checkMetadataIntegrity() async {
    if (_metaBox.isEmpty && _workoutBox.isNotEmpty) {
      debugPrint('[HiveService] Meta box empty, rebuilding index...');
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
      debugPrint('[HiveService] Index rebuilt with ${metaMap.length} items.');
    }
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
      _invalidatePRCache(userId: workout.userId, exerciseName: exercise.name);
      _invalidateExerciseHistoryCache(
          userId: workout.userId, exerciseName: exercise.name);
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
        _invalidatePRCache(userId: workout.userId, exerciseName: exercise.name);
        _invalidateExerciseHistoryCache(
            userId: workout.userId, exerciseName: exercise.name);
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
      _invalidatePRCache(userId: workout.userId, exerciseName: exercise.name);
      _invalidateExerciseHistoryCache(
          userId: workout.userId, exerciseName: exercise.name);
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

  static Future<void> cleanDrafts(String userId) async {
    await init();
    final drafts = _workoutBox.values
        .where((w) => w.userId == userId && w.isDraft)
        .map((w) => w.id)
        .toList();

    await _workoutBox.deleteAll(drafts);
    await _metaBox.deleteAll(drafts);
    _invalidateWorkoutCache(userId: userId);
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
      String userId, String exerciseName) async {
    await init();

    // Check cache first
    final cacheKey = '$userId:${exerciseName.toLowerCase()}';
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
            !ex.skipped) {
          double sessionMaxWeight = 0;
          int sessionMaxWeightReps = 0;
          double sessionTotalVolume = 0;
          double bestSetVolume = 0;
          String bestSetVolumeBreakdown = '';
          double bestSetVolumeWeight = 0;
          int bestSetVolumeReps = 0;
          int sessionTotalReps = 0;

          for (final set in ex.sets) {
            final segments = set.segments;
            double currentSetVolume = 0;
            List<String> breakdownParts = [];
            double firstSegmentWeight = 0;
            int totalSetReps = 0;

            for (int i = 0; i < segments.length; i++) {
              final seg = segments[i];
              final effectiveReps = seg.repsTo - seg.repsFrom + 1;

              if (i == 0) firstSegmentWeight = seg.weight;

              totalSetReps += effectiveReps;
              sessionTotalReps += effectiveReps;

              // Max Weight
              if (seg.weight > sessionMaxWeight) {
                sessionMaxWeight = seg.weight;
                sessionMaxWeightReps = effectiveReps;
              } else if (seg.weight == sessionMaxWeight) {
                if (effectiveReps > sessionMaxWeightReps) {
                  sessionMaxWeightReps = effectiveReps;
                }
              }

              final vol = seg.weight * effectiveReps;
              currentSetVolume += vol;
              sessionTotalVolume += vol;

              breakdownParts.add(
                  '${seg.weight % 1 == 0 ? seg.weight.toInt() : seg.weight} kg x $effectiveReps');
            }

            if (currentSetVolume > bestSetVolume) {
              bestSetVolume = currentSetVolume;
              bestSetVolumeBreakdown = breakdownParts.join(' + ');
              bestSetVolumeWeight = firstSegmentWeight;
              bestSetVolumeReps = totalSetReps;
            }
          }

          if (sessionTotalVolume > 0 || sessionMaxWeight > 0) {
            history.add({
              'workoutDate': w.workoutDate.toIso8601String(),
              'totalVolume': sessionTotalVolume,
              'totalReps': sessionTotalReps,
              'maxWeight': sessionMaxWeight,
              'maxWeightReps': sessionMaxWeightReps,
              'bestSetVolume': bestSetVolume,
              'bestSetVolumeBreakdown': bestSetVolumeBreakdown,
              'bestSetVolumeWeight': bestSetVolumeWeight,
              'bestSetVolumeReps': bestSetVolumeReps,
              'sets': ex.sets,
            });
          }
        }
      }
    }

    // Cache the result
    _exerciseHistoryCache[cacheKey] = history;
    return history;
  }

  static Future<WorkoutSession?> getLastExerciseLog(
      String userId, String exerciseName) async {
    await init();
    final workouts = _workoutBox.values
        .where((w) => w.userId == userId && !w.isDraft)
        .toList()
      ..sort((a, b) => b.workoutDate.compareTo(a.workoutDate)); // DESC

    for (final w in workouts) {
      for (final ex in w.exercises) {
        if (ex.name.toLowerCase() == exerciseName.toLowerCase() &&
            !ex.skipped) {
          return w;
        }
      }
    }
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

  static Future<PersonalRecord?> getExercisePR(
      String userId, String exerciseName,
      {DateTime? startDate, DateTime? endDate}) async {
    // Check cache
    if (startDate == null && endDate == null) {
      final cacheKey = '$userId:${exerciseName.toLowerCase()}';
      if (_prCache.containsKey(cacheKey)) {
        return _prCache[cacheKey];
      }
    }

    final history = await getExerciseHistory(
        userId, exerciseName); // Note: swapped args in my impl vs call

    if (history.isEmpty) return null;

    double globalMaxWeight = 0;
    int globalMaxWeightReps = 0;

    double globalMaxSetVolume = 0;
    double globalMaxSetVolumeWeight = 0;
    int globalMaxSetVolumeReps = 0;
    String globalMaxSetVolumeBreakdown = '';

    double globalBestSessionVolume = 0;
    int globalBestSessionReps = 0;
    String? globalBestSessionDate;
    List<ExerciseSet>? globalBestSessionSets;

    for (final record in history) {
      final dateStr = record['workoutDate'] as String;
      final date = DateTime.parse(dateStr);

      if (startDate != null && date.isBefore(startDate)) continue;
      if (endDate != null && date.isAfter(endDate)) continue;

      // 1. Max Weight
      final rMaxWeight = record['maxWeight'] as double;
      if (rMaxWeight > globalMaxWeight) {
        globalMaxWeight = rMaxWeight;
        globalMaxWeightReps = record['maxWeightReps'] as int;
      }

      // 2. Max Set Volume
      final rBestSetVol = record['bestSetVolume'] as double;
      if (rBestSetVol > globalMaxSetVolume) {
        globalMaxSetVolume = rBestSetVol;
        globalMaxSetVolumeWeight = record['bestSetVolumeWeight'] as double;
        globalMaxSetVolumeReps = record['bestSetVolumeReps'] as int;
        globalMaxSetVolumeBreakdown =
            record['bestSetVolumeBreakdown'] as String;
      }

      // 3. Best Session Volume
      final rSessionVol = record['totalVolume'] as double;
      final rSessionReps = record['totalReps'] as int? ?? 0;

      bool isNewBest = false;
      if (rSessionVol > globalBestSessionVolume) {
        isNewBest = true;
      } else if (globalBestSessionVolume == 0 && rSessionVol == 0) {
        if (rSessionReps > globalBestSessionReps) {
          isNewBest = true;
        }
      }

      if (isNewBest) {
        globalBestSessionVolume = rSessionVol;
        globalBestSessionReps = rSessionReps;
        globalBestSessionDate = dateStr;
        globalBestSessionSets = record['sets'] as List<ExerciseSet>;
      }
    }

    if (globalMaxWeight == 0 &&
        globalMaxSetVolume == 0 &&
        globalBestSessionVolume == 0 &&
        globalBestSessionReps == 0) {
      return null;
    }

    final pr = PersonalRecord(
      maxWeight: globalMaxWeight,
      maxWeightReps: globalMaxWeightReps,
      maxVolume: globalMaxSetVolume,
      maxVolumeWeight: globalMaxSetVolumeWeight,
      maxVolumeReps: globalMaxSetVolumeReps,
      maxVolumeBreakdown: globalMaxSetVolumeBreakdown,
      bestSessionVolume: globalBestSessionVolume,
      bestSessionReps: globalBestSessionReps,
      bestSessionDate: globalBestSessionDate,
      bestSessionSets: globalBestSessionSets,
      exerciseName: exerciseName,
    );

    // Cache
    if (startDate == null && endDate == null) {
      final cacheKey = '$userId:${exerciseName.toLowerCase()}';
      _prCache[cacheKey] = pr;
    }

    return pr;
  }

  static Future<Map<String, PersonalRecord>> getAllPersonalRecords(
      String userId,
      {DateTime? startDate,
      DateTime? endDate}) async {
    await init();

    // Single-pass optimization: collect all exercise data in one iteration
    final exerciseHistories = <String, List<Map<String, dynamic>>>{};

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
    for (final w in filteredWorkouts) {
      for (final ex in w.exercises) {
        if (ex.skipped) continue;

        final exerciseNameLower = ex.name.toLowerCase();
        exerciseHistories.putIfAbsent(exerciseNameLower, () => []);

        // Calculate session metrics (same logic as getExerciseHistory)
        double sessionMaxWeight = 0;
        int sessionMaxWeightReps = 0;
        double sessionTotalVolume = 0;
        double bestSetVolume = 0;
        String bestSetVolumeBreakdown = '';
        double bestSetVolumeWeight = 0;
        int bestSetVolumeReps = 0;
        int sessionTotalReps = 0;

        for (final set in ex.sets) {
          final segments = set.segments;
          double currentSetVolume = 0;
          List<String> breakdownParts = [];
          double firstSegmentWeight = 0;
          int totalSetReps = 0;

          for (int i = 0; i < segments.length; i++) {
            final seg = segments[i];
            final effectiveReps = seg.repsTo - seg.repsFrom + 1;

            if (i == 0) firstSegmentWeight = seg.weight;

            totalSetReps += effectiveReps;
            sessionTotalReps += effectiveReps;

            if (seg.weight > sessionMaxWeight) {
              sessionMaxWeight = seg.weight;
              sessionMaxWeightReps = effectiveReps;
            } else if (seg.weight == sessionMaxWeight) {
              if (effectiveReps > sessionMaxWeightReps) {
                sessionMaxWeightReps = effectiveReps;
              }
            }

            final vol = seg.weight * effectiveReps;
            currentSetVolume += vol;
            sessionTotalVolume += vol;

            breakdownParts.add(
                '${seg.weight % 1 == 0 ? seg.weight.toInt() : seg.weight} kg x $effectiveReps');
          }

          if (currentSetVolume > bestSetVolume) {
            bestSetVolume = currentSetVolume;
            bestSetVolumeBreakdown = breakdownParts.join(' + ');
            bestSetVolumeWeight = firstSegmentWeight;
            bestSetVolumeReps = totalSetReps;
          }
        }

        if (sessionTotalVolume > 0 || sessionMaxWeight > 0) {
          exerciseHistories[exerciseNameLower]!.add({
            'workoutDate': w.workoutDate.toIso8601String(),
            'totalVolume': sessionTotalVolume,
            'totalReps': sessionTotalReps,
            'maxWeight': sessionMaxWeight,
            'maxWeightReps': sessionMaxWeightReps,
            'bestSetVolume': bestSetVolume,
            'bestSetVolumeBreakdown': bestSetVolumeBreakdown,
            'bestSetVolumeWeight': bestSetVolumeWeight,
            'bestSetVolumeReps': bestSetVolumeReps,
            'sets': ex.sets,
          });
        }
      }
    }

    // Calculate PRs from collected data
    final results = <String, PersonalRecord>{};
    for (final entry in exerciseHistories.entries) {
      final pr = _calculatePRFromHistory(entry.key, entry.value);
      if (pr != null) {
        results[entry.key] = pr;
      }
    }

    return results;
  }

  // Helper method to calculate PR from history data
  static PersonalRecord? _calculatePRFromHistory(
      String exerciseName, List<Map<String, dynamic>> history) {
    if (history.isEmpty) return null;

    double globalMaxWeight = 0;
    int globalMaxWeightReps = 0;

    double globalMaxSetVolume = 0;
    double globalMaxSetVolumeWeight = 0;
    int globalMaxSetVolumeReps = 0;
    String globalMaxSetVolumeBreakdown = '';

    double globalBestSessionVolume = 0;
    int globalBestSessionReps = 0;
    String? globalBestSessionDate;
    List<ExerciseSet>? globalBestSessionSets;

    for (final record in history) {
      // 1. Max Weight
      final rMaxWeight = record['maxWeight'] as double;
      if (rMaxWeight > globalMaxWeight) {
        globalMaxWeight = rMaxWeight;
        globalMaxWeightReps = record['maxWeightReps'] as int;
      }

      // 2. Max Set Volume
      final rBestSetVol = record['bestSetVolume'] as double;
      if (rBestSetVol > globalMaxSetVolume) {
        globalMaxSetVolume = rBestSetVol;
        globalMaxSetVolumeWeight = record['bestSetVolumeWeight'] as double;
        globalMaxSetVolumeReps = record['bestSetVolumeReps'] as int;
        globalMaxSetVolumeBreakdown =
            record['bestSetVolumeBreakdown'] as String;
      }

      // 3. Best Session Volume
      final rSessionVol = record['totalVolume'] as double;
      final rSessionReps = record['totalReps'] as int? ?? 0;

      bool isNewBest = false;
      if (rSessionVol > globalBestSessionVolume) {
        isNewBest = true;
      } else if (globalBestSessionVolume == 0 && rSessionVol == 0) {
        if (rSessionReps > globalBestSessionReps) {
          isNewBest = true;
        }
      }

      if (isNewBest) {
        globalBestSessionVolume = rSessionVol;
        globalBestSessionReps = rSessionReps;
        globalBestSessionDate = record['workoutDate'] as String;
        globalBestSessionSets = record['sets'] as List<ExerciseSet>;
      }
    }

    if (globalMaxWeight == 0 &&
        globalMaxSetVolume == 0 &&
        globalBestSessionVolume == 0 &&
        globalBestSessionReps == 0) {
      return null;
    }

    return PersonalRecord(
      maxWeight: globalMaxWeight,
      maxWeightReps: globalMaxWeightReps,
      maxVolume: globalMaxSetVolume,
      maxVolumeWeight: globalMaxSetVolumeWeight,
      maxVolumeReps: globalMaxSetVolumeReps,
      maxVolumeBreakdown: globalMaxSetVolumeBreakdown,
      bestSessionVolume: globalBestSessionVolume,
      bestSessionReps: globalBestSessionReps,
      bestSessionDate: globalBestSessionDate,
      bestSessionSets: globalBestSessionSets,
      exerciseName: exerciseName,
    );
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
