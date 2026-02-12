import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:liftly/core/database/hive_models.dart';
import 'package:liftly/core/models/workout_plan.dart';
import 'package:liftly/core/models/workout_session.dart';
import 'package:liftly/features/stats/bloc/stats_state.dart';

class HiveService {
  static const String _workoutBoxName = 'workouts';
  static const String _planBoxName = 'plans';
  static const String _settingsBoxName = 'settings';

  static late Box<HiveWorkoutSession> _workoutBox;
  static late Box<HiveWorkoutPlan> _planBox;
  static late Box<HivePreference> _settingsBox;

  static bool _isInitialized = false;
  static bool get isInitialized => _isInitialized;

  // PR Cache: Map<"userId:exerciseName", PersonalRecord>
  static final Map<String, PersonalRecord> _prCache = {};

  static void _invalidatePRCache({String? userId, String? exerciseName}) {
    if (userId != null && exerciseName != null) {
      _prCache.remove('$userId:${exerciseName.toLowerCase()}');
    } else if (userId != null) {
      _prCache.removeWhere((key, _) => key.startsWith('$userId:'));
    } else {
      _prCache.clear();
    }
  }

  static Future<void> init() async {
    if (_isInitialized) return;

    try {
      await Hive.initFlutter();

      Hive.registerAdapter(HiveWorkoutSessionAdapter());
      Hive.registerAdapter(HiveSessionExerciseAdapter());
      Hive.registerAdapter(HiveExerciseSetAdapter());
      Hive.registerAdapter(HiveSetSegmentAdapter());
      Hive.registerAdapter(HiveWorkoutPlanAdapter());
      Hive.registerAdapter(HivePlanExerciseAdapter());
      Hive.registerAdapter(HivePreferenceAdapter());

      _workoutBox = await Hive.openBox<HiveWorkoutSession>(_workoutBoxName);
      _planBox = await Hive.openBox<HiveWorkoutPlan>(_planBoxName);
      _settingsBox = await Hive.openBox<HivePreference>(_settingsBoxName);

      _isInitialized = true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Hive init error: $e');
      }
      rethrow;
    }
  }

  // ============= Conversion Helpers =============

  static HiveWorkoutSession _toHiveWorkout(WorkoutSession workout) {
    return HiveWorkoutSession()
      ..id = workout.id
      ..userId = workout.userId
      ..planId = workout.planId
      ..planName = workout.planName
      ..workoutDate = workout.workoutDate
      ..startedAt = workout.startedAt
      ..endedAt = workout.endedAt
      ..createdAt = workout.createdAt
      ..updatedAt = workout.updatedAt
      ..isDraft = workout.isDraft
      ..exercises = workout.exercises.map((e) {
        return HiveSessionExercise()
          ..id = e.id
          ..name = e.name
          ..order = e.order
          ..skipped = e.skipped
          ..isTemplate = e.isTemplate
          ..sets = e.sets.map((s) {
            return HiveExerciseSet()
              ..id = s.id
              ..setNumber = s.setNumber
              ..segments = s.segments.map((seg) {
                return HiveSetSegment()
                  ..id = seg.id
                  ..weight = seg.weight
                  ..repsFrom = seg.repsFrom
                  ..repsTo = seg.repsTo
                  ..segmentOrder = seg.segmentOrder
                  ..notes = seg.notes;
              }).toList();
          }).toList();
      }).toList();
  }

  static WorkoutSession _fromHiveWorkout(HiveWorkoutSession hw) {
    return WorkoutSession(
      id: hw.id,
      userId: hw.userId,
      planId: hw.planId,
      planName: hw.planName,
      workoutDate: hw.workoutDate,
      startedAt: hw.startedAt,
      endedAt: hw.endedAt,
      createdAt: hw.createdAt,
      updatedAt: hw.updatedAt,
      isDraft: hw.isDraft,
      exercises: hw.exercises.map((he) {
        return SessionExercise(
          id: he.id,
          name: he.name,
          order: he.order,
          skipped: he.skipped,
          isTemplate: he.isTemplate,
          sets: he.sets.map((hs) {
            return ExerciseSet(
              id: hs.id,
              setNumber: hs.setNumber,
              segments: hs.segments.map((hg) {
                return SetSegment(
                  id: hg.id,
                  weight: hg.weight,
                  repsFrom: hg.repsFrom,
                  repsTo: hg.repsTo,
                  segmentOrder: hg.segmentOrder,
                  notes: hg.notes ?? '',
                );
              }).toList(),
            );
          }).toList(),
        );
      }).toList(),
    );
  }

  static HiveWorkoutPlan _toHivePlan(WorkoutPlan plan) {
    return HiveWorkoutPlan()
      ..id = plan.id
      ..userId = plan.userId
      ..name = plan.name
      ..description = plan.description
      ..createdAt = plan.createdAt
      ..updatedAt = plan.updatedAt
      ..exercises = plan.exercises.map((e) {
        return HivePlanExercise()
          ..id = e.id
          ..name = e.name
          ..order = e.order;
      }).toList();
  }

  static WorkoutPlan _fromHivePlan(HiveWorkoutPlan hp) {
    return WorkoutPlan(
      id: hp.id,
      userId: hp.userId,
      name: hp.name,
      description: hp.description,
      createdAt: hp.createdAt,
      updatedAt: hp.updatedAt,
      exercises: hp.exercises.map((he) {
        return PlanExercise(
          id: he.id,
          name: he.name,
          order: he.order,
        );
      }).toList(),
    );
  }

  // ============= Workout Operations =============

  static Future<void> createWorkout(WorkoutSession workout) async {
    final hiveWorkout = _toHiveWorkout(workout);
    await _workoutBox.put(workout.id, hiveWorkout);

    for (final exercise in workout.exercises) {
      _invalidatePRCache(userId: workout.userId, exerciseName: exercise.name);
    }
  }

  static Future<WorkoutSession?> getWorkoutById(String id) async {
    final hw = _workoutBox.get(id);
    if (hw == null) return null;
    return _fromHiveWorkout(hw);
  }

  static Future<List<WorkoutSession>> getWorkouts(String userId,
      {bool includeDrafts = false, int? limit, int? offset}) async {
    var workouts = _workoutBox.values
        .where((w) => w.userId == userId)
        .where((w) => includeDrafts || !w.isDraft)
        .toList();

    // Sort by workoutDate DESC
    workouts.sort((a, b) => b.workoutDate.compareTo(a.workoutDate));

    if (offset != null) {
      if (offset >= workouts.length) return [];
      workouts = workouts.skip(offset).toList();
    }

    if (limit != null) {
      workouts = workouts.take(limit).toList();
    }

    return workouts.map((w) => _fromHiveWorkout(w)).toList();
  }

  static Future<WorkoutSession?> getDraftWorkout(String userId) async {
    final drafts = _workoutBox.values
        .where((w) => w.userId == userId && w.isDraft)
        .toList();

    if (drafts.isEmpty) return null;

    // Sort by updatedAt DESC
    drafts.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    return _fromHiveWorkout(drafts.first);
  }

  static Future<void> updateWorkout(WorkoutSession workout) async {
    // Overwrite existing key
    await createWorkout(workout);
  }

  static Future<void> deleteWorkout(String workoutId) async {
    final workout = await getWorkoutById(workoutId); // For cache invalidation
    await _workoutBox.delete(workoutId);

    if (workout != null) {
      for (var exercise in workout.exercises) {
        _invalidatePRCache(userId: workout.userId, exerciseName: exercise.name);
      }
    }
  }

  static Future<int> getWorkoutCount(String userId) async {
    return _workoutBox.values
        .where((w) => w.userId == userId && !w.isDraft)
        .length;
  }

  static Future<void> importWorkouts(List<WorkoutSession> workouts) async {
    final Map<String, HiveWorkoutSession> batch = {};
    for (final w in workouts) {
      batch[w.id] = _toHiveWorkout(w);
    }
    await _workoutBox.putAll(batch);
  }

  static Future<Map<String, List<dynamic>>> getAllDataForExport() async {
    final workouts =
        _workoutBox.values.map((w) => _fromHiveWorkout(w)).toList();
    final plans = _planBox.values.map((p) => _fromHivePlan(p)).toList();

    return {
      'workouts': workouts,
      'plans': plans,
    };
  }

  static Future<void> clearAllData() async {
    await _workoutBox.clear();
    await _planBox.clear();
    await _settingsBox.clear();
  }

  // ============= Plans Operations =============

  static Future<void> createPlan(WorkoutPlan plan) async {
    await _planBox.put(plan.id, _toHivePlan(plan));
  }

  static Future<List<WorkoutPlan>> getPlans(String userId) async {
    final plans = _planBox.values.where((p) => p.userId == userId).toList();

    // Sort by createdAt DESC
    plans.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return plans.map((p) => _fromHivePlan(p)).toList();
  }

  static Future<WorkoutPlan?> getPlan(String planId) async {
    final hp = _planBox.get(planId);
    if (hp == null) return null;
    return _fromHivePlan(hp);
  }

  static Future<void> deletePlan(String planId) async {
    await _planBox.delete(planId);
  }

  static Future<void> importPlans(List<WorkoutPlan> plans) async {
    final Map<String, HiveWorkoutPlan> batch = {};
    for (final p in plans) {
      batch[p.id] = _toHivePlan(p);
    }
    await _planBox.putAll(batch);
  }

  // ============= Preferences Operations =============

  static Future<void> savePreference(String key, String value) async {
    final pref = HivePreference()
      ..prefKey = key
      ..value = value
      ..updatedAt = DateTime.now();
    await _settingsBox.put(key, pref);
  }

  static Future<String?> getPreference(String key) async {
    final pref = _settingsBox.get(key);
    return pref?.value;
  }

  static Future<void> deletePreference(String key) async {
    await _settingsBox.delete(key);
  }

  static Future<void> clearAllPreferences() async {
    await _settingsBox.clear();
  }

  // ============= Stats Logic (In-Memory) =============

  static Future<SessionExercise?> getLastExerciseLog(
      String userId, String exerciseName) async {
    // Filter workouts that contain this exercise
    final candidateWorkouts = _workoutBox.values
        .where((w) => w.userId == userId && !w.isDraft)
        .where((w) => w.exercises.any((e) =>
            e.name.toLowerCase() == exerciseName.toLowerCase() && !e.skipped))
        .toList();

    if (candidateWorkouts.isEmpty) return null;

    // Sort by date DESC
    candidateWorkouts.sort((a, b) => b.workoutDate.compareTo(a.workoutDate));

    final latestWorkout = candidateWorkouts.first;

    // Extract the exercise
    // Extract the exercise
    try {
      final fullWorkout = _fromHiveWorkout(latestWorkout);
      return fullWorkout.exercises.firstWhere((e) => e.name == exerciseName);
    } catch (_) {
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>> getExerciseHistory(
      String exerciseName, String userId) async {
    final workouts = _workoutBox.values
        .where((w) => w.userId == userId && !w.isDraft)
        .toList();

    // Sort by date
    workouts.sort((a, b) => b.workoutDate.compareTo(a.workoutDate));

    List<Map<String, dynamic>> result = [];

    for (final hw in workouts) {
      final hasExercise = hw.exercises
          .any((e) => e.name.toLowerCase() == exerciseName.toLowerCase());

      if (!hasExercise) continue;

      final workout = _fromHiveWorkout(hw);

      for (final ex in workout.exercises) {
        if (ex.name.toLowerCase() != exerciseName.toLowerCase()) continue;

        double sessionMaxWeight = 0;
        int sessionMaxWeightReps = 0;
        double sessionTotalVolume = 0;
        double bestSetVolume = 0;
        String bestSetVolumeBreakdown = '';
        double bestSetVolumeWeight = 0;
        int bestSetVolumeReps = 0;
        int sessionTotalReps = 0;

        for (final set in ex.sets) {
          double setVolume = 0;
          double setMaxWeight = 0;
          int setReps = 0;
          List<String> breakdownParts = [];

          for (final segment in set.segments) {
            int reps = segment.repsFrom;
            setVolume += segment.weight * reps;
            if (segment.weight > setMaxWeight) {
              setMaxWeight = segment.weight;
            }
            setReps += reps;
            breakdownParts.add('${segment.weight}kg x $reps');
          }

          sessionTotalVolume += setVolume;
          sessionTotalReps += setReps;

          if (setMaxWeight > sessionMaxWeight) {
            sessionMaxWeight = setMaxWeight;
            sessionMaxWeightReps = setReps;
          }

          if (setVolume > bestSetVolume) {
            bestSetVolume = setVolume;
            bestSetVolumeWeight = setMaxWeight;
            bestSetVolumeReps = setReps;
            bestSetVolumeBreakdown = breakdownParts.join(' + ');
          }
        }

        if (sessionTotalVolume > 0 || sessionMaxWeight > 0) {
          result.add({
            'date': workout.workoutDate,
            'maxWeight': sessionMaxWeight,
            'maxWeightReps': sessionMaxWeightReps,
            'totalVolume': sessionTotalVolume,
            'totalReps': sessionTotalReps,
            'bestSetVolume': bestSetVolume,
            'bestSetVolumeWeight': bestSetVolumeWeight,
            'bestSetVolumeReps': bestSetVolumeReps,
            'bestSetBreakdown': bestSetVolumeBreakdown,
            'workoutId': workout.id,
          });
        }
      }
    }

    return result;
  }

  // Copy paste getExercisePR from previous implementation but adapted for Hive
  static Future<PersonalRecord?> getExercisePR(
      String userId, String exerciseName,
      {DateTime? startDate, DateTime? endDate}) async {
    // Note: Caching logic needs to account for dates or be disabled when dates are used.
    // For simplicity, disable cache if dates are provided or include them in key.
    // With infinite variations of dates, caching is less effective.
    // Let's skip cache if dates are present.

    if (startDate == null && endDate == null) {
      final cacheKey = '$userId:${exerciseName.toLowerCase()}';
      if (_prCache.containsKey(cacheKey)) {
        return _prCache[cacheKey];
      }
    }

    final history = await getExerciseHistory(exerciseName, userId);

    if (history.isEmpty) return null;

    Map<String, dynamic>? bestMaxWeightLog;
    double maxWeight = 0;

    Map<String, dynamic>? bestSessionVolumeLog;
    double bestSessionVolume = 0;

    Map<String, dynamic>? bestSetVolumeLog;
    double maxSetVolume = 0;

    for (final log in history) {
      // Date filtering
      if (startDate != null || endDate != null) {
        final date = log['date'] as DateTime;
        if (startDate != null && date.isBefore(startDate)) continue;
        if (endDate != null && date.isAfter(endDate)) continue;
      }

      // 1. Max Weight
      final weight = (log['maxWeight'] as num).toDouble();
      if (weight > maxWeight) {
        maxWeight = weight;
        bestMaxWeightLog = log;
      }

      // 2. Best Session Volume
      final sessionVol = (log['totalVolume'] as num).toDouble();
      if (sessionVol > bestSessionVolume) {
        bestSessionVolume = sessionVol;
        bestSessionVolumeLog = log;
      }

      // 3. Max Volume Set (Best Set Volume)
      final setVol = (log['bestSetVolume'] as num).toDouble();
      if (setVol > maxSetVolume) {
        maxSetVolume = setVol;
        bestSetVolumeLog = log;
      }
    }

    if (bestMaxWeightLog == null) return null;

    final pr = PersonalRecord(
      // maxWeight (Heaviest Set)
      maxWeight: maxWeight,
      maxWeightReps: bestMaxWeightLog['maxWeightReps'] as int,

      // maxVolume (Best Set Volume)
      maxVolume: maxSetVolume,
      maxVolumeWeight:
          (bestSetVolumeLog?['bestSetVolumeWeight'] as num?)?.toDouble() ?? 0,
      maxVolumeReps:
          (bestSetVolumeLog?['bestSetVolumeReps'] as num?)?.toInt() ?? 0,
      maxVolumeBreakdown:
          (bestSetVolumeLog?['bestSetBreakdown'] as String?) ?? '',

      // bestSession (Best Session Volume)
      bestSessionVolume: bestSessionVolume,
      bestSessionReps:
          (bestSessionVolumeLog?['totalReps'] as num?)?.toInt() ?? 0,
      bestSessionDate: bestSessionVolumeLog?['date']?.toString(),
    );

    if (startDate == null && endDate == null) {
      final cacheKey = '$userId:${exerciseName.toLowerCase()}';
      _prCache[cacheKey] = pr;
    }

    return pr;
  }

  static Future<List<String>> getExerciseNames(String userId) async {
    final names = <String>{};
    for (final w in _workoutBox.values.where((w) => w.userId == userId)) {
      for (final e in w.exercises) {
        names.add(e.name);
      }
    }
    return names.toList()..sort();
  }

  static Future<Map<String, PersonalRecord>> getAllPersonalRecords(
      String userId,
      {DateTime? startDate,
      DateTime? endDate}) async {
    final names = await getExerciseNames(userId);
    final result = <String, PersonalRecord>{};

    for (final name in names) {
      final pr = await getExercisePR(userId, name,
          startDate: startDate, endDate: endDate);
      if (pr != null) {
        result[name] = pr;
      }
    }
    return result;
  }
}
