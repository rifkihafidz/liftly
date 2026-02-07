import 'package:isar/isar.dart';
import 'package:liftly/core/database/isar_models.dart';
import 'package:liftly/core/models/workout_plan.dart';
import 'package:liftly/core/models/workout_session.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:liftly/features/stats/bloc/stats_state.dart';

class IsarService {
  static late Isar _isar;
  static bool _isInitialized = false;

  static bool get isInitialized => _isInitialized;

  static Future<void> init() async {
    if (_isInitialized) return;

    final dir = kIsWeb ? '' : (await getApplicationDocumentsDirectory()).path;

    _isar = await Isar.open(
      [
        IsarWorkoutSessionSchema,
        IsarSessionExerciseSchema,
        IsarExerciseSetSchema,
        IsarSetSegmentSchema,
        IsarPreferenceSchema,
        IsarWorkoutPlanSchema,
        IsarPlanExerciseSchema,
      ],
      directory: dir,
      inspector: kDebugMode,
    );

    _isInitialized = true;
  }

  // ============= Conversion Helpers =============

  static IsarWorkoutSession _toIsarWorkout(WorkoutSession workout) {
    return IsarWorkoutSession()
      ..workoutId = workout.id
      ..userId = workout.userId
      ..planId = workout.planId
      ..planName = workout.planName
      ..workoutDate = workout.workoutDate
      ..startedAt = workout.startedAt
      ..endedAt = workout.endedAt
      ..createdAt = workout.createdAt
      ..updatedAt = workout.updatedAt
      ..isDraft = workout.isDraft;
  }

  static Future<WorkoutSession> _fromIsarWorkout(IsarWorkoutSession iw) async {
    await iw.exercises.load();

    // Sort exercises by order
    final sortedExercises = iw.exercises.toList()
      ..sort((a, b) => a.order.compareTo(b.order));

    final exercises = <SessionExercise>[];

    for (final ie in sortedExercises) {
      await ie.sets.load();

      // Sort sets by setNumber
      final sortedSets = ie.sets.toList()
        ..sort((a, b) => a.setNumber.compareTo(b.setNumber));

      final sets = <ExerciseSet>[];
      for (final iset in sortedSets) {
        await iset.segments.load();

        // Sort segments by segmentOrder
        final sortedSegments = iset.segments.toList()
          ..sort((a, b) => a.segmentOrder.compareTo(b.segmentOrder));

        final segments = sortedSegments.map((iseg) {
          return SetSegment(
            id: iseg.segmentId,
            weight: iseg.weight,
            repsFrom: iseg.repsFrom,
            repsTo: iseg.repsTo,
            segmentOrder: iseg.segmentOrder,
            notes: iseg.notes ?? '',
          );
        }).toList();

        sets.add(ExerciseSet(
          id: iset.setId,
          segments: segments,
          setNumber: iset.setNumber,
        ));
      }

      exercises.add(SessionExercise(
        id: ie.exerciseId,
        name: ie.name,
        order: ie.order,
        skipped: ie.skipped,
        isTemplate: ie.isTemplate,
        sets: sets,
      ));
    }

    return WorkoutSession(
      id: iw.workoutId,
      userId: iw.userId,
      planId: iw.planId,
      planName: iw.planName,
      workoutDate: iw.workoutDate,
      startedAt: iw.startedAt,
      endedAt: iw.endedAt,
      exercises: exercises,
      createdAt: iw.createdAt,
      updatedAt: iw.updatedAt,
      isDraft: iw.isDraft,
    );
  }

  // ============= Workout Operations =============

  static Future<void> createWorkout(WorkoutSession workout) async {
    await _isar.writeTxn(() async {
      // 1. Create Main Workout
      final isarWorkout = _toIsarWorkout(workout);
      await _isar.isarWorkoutSessions.put(isarWorkout);

      for (final exercise in workout.exercises) {
        // 2. Create Exercise
        final isarExercise = IsarSessionExercise()
          ..exerciseId = exercise.id
          ..name = exercise.name
          ..order = exercise.order
          ..skipped = exercise.skipped
          ..isTemplate = exercise.isTemplate;

        await _isar.isarSessionExercises.put(isarExercise);
        isarExercise.workout.value = isarWorkout;
        await isarExercise.workout.save();

        for (final set in exercise.sets) {
          // 3. Create Set
          final isarSet = IsarExerciseSet()
            ..setId = set.id
            ..setNumber = set.setNumber;

          await _isar.isarExerciseSets.put(isarSet);
          isarSet.exercise.value = isarExercise;
          await isarSet.exercise.save();

          for (final segment in set.segments) {
            // 4. Create Segment
            final isarSegment = IsarSetSegment()
              ..segmentId = segment.id
              ..weight = segment.weight
              ..repsFrom = segment.repsFrom
              ..repsTo = segment.repsTo
              ..segmentOrder = segment.segmentOrder
              ..notes = segment.notes;

            await _isar.isarSetSegments.put(isarSegment);
            isarSegment.set.value = isarSet;
            await isarSegment.set.save();
          }
        }
      }
    });
  }

  static Future<WorkoutSession?> getWorkoutById(String id) async {
    final isarWorkout = await _isar.isarWorkoutSessions
        .filter()
        .workoutIdEqualTo(id)
        .findFirst();

    if (isarWorkout == null) return null;
    return _fromIsarWorkout(isarWorkout);
  }

  static Future<List<WorkoutSession>> getWorkouts(String userId,
      {bool includeDrafts = false}) async {
    var query = _isar.isarWorkoutSessions.filter().userIdEqualTo(userId);

    if (!includeDrafts) {
      query = query.isDraftEqualTo(false);
    }

    final isarWorkouts = await query.sortByWorkoutDateDesc().findAll();
    return await Future.wait(isarWorkouts.map((iw) => _fromIsarWorkout(iw)));
  }

  static Future<WorkoutSession?> getDraftWorkout(String userId) async {
    final isarWorkout = await _isar.isarWorkoutSessions
        .filter()
        .userIdEqualTo(userId)
        .isDraftEqualTo(true)
        .sortByUpdatedAtDesc()
        .findFirst();

    if (isarWorkout == null) return null;
    return _fromIsarWorkout(isarWorkout);
  }

  static Future<void> updateWorkout(WorkoutSession workout) async {
    await deleteWorkout(workout.id);
    await createWorkout(workout);
  }

  static Future<void> deleteWorkout(String workoutId) async {
    await _isar.writeTxn(() async {
      final isarWorkout = await _isar.isarWorkoutSessions
          .filter()
          .workoutIdEqualTo(workoutId)
          .findFirst();

      if (isarWorkout != null) {
        await isarWorkout.exercises.load();
        for (final exercise in isarWorkout.exercises) {
          await exercise.sets.load();
          for (final set in exercise.sets) {
            await set.segments.load();
            final segmentIds = set.segments.map((e) => e.id).toList();
            await _isar.isarSetSegments.deleteAll(segmentIds);
          }
          final setIds = exercise.sets.map((e) => e.id).toList();
          await _isar.isarExerciseSets.deleteAll(setIds);
        }
        final exerciseIds = isarWorkout.exercises.map((e) => e.id).toList();
        await _isar.isarSessionExercises.deleteAll(exerciseIds);

        await _isar.isarWorkoutSessions.delete(isarWorkout.id);
      }
    });
  }

  static Future<int> getWorkoutCount(String userId) async {
    return await _isar.isarWorkoutSessions
        .filter()
        .userIdEqualTo(userId)
        .isDraftEqualTo(false)
        .count();
  }

  static Future<Map<String, List<dynamic>>> getAllDataForExport() async {
    final isarWorkouts = await _isar.isarWorkoutSessions.where().findAll();
    final workouts =
        await Future.wait(isarWorkouts.map((iw) => _fromIsarWorkout(iw)));

    final isarPlans = await _isar.isarWorkoutPlans.where().findAll();
    final plans = await Future.wait(isarPlans.map((ip) => _fromIsarPlan(ip)));

    return {
      'workouts': workouts,
      'plans': plans,
    };
  }

  static Future<void> clearAllData() async {
    await _isar.writeTxn(() async {
      await _isar.clear();
    });
  }

  // ============= Preferences Operations =============

  static Future<void> savePreference(String key, String value) async {
    await _isar.writeTxn(() async {
      final pref = IsarPreference()
        ..key = key
        ..value = value
        ..updatedAt = DateTime.now();
      await _isar.isarPreferences.put(pref);
    });
  }

  static Future<String?> getPreference(String key) async {
    final pref =
        await _isar.isarPreferences.filter().keyEqualTo(key).findFirst();
    return pref?.value;
  }

  static Future<void> deletePreference(String key) async {
    await _isar.writeTxn(() async {
      await _isar.isarPreferences.filter().keyEqualTo(key).deleteAll();
    });
  }

  static Future<void> clearAllPreferences() async {
    await _isar.writeTxn(() async {
      await _isar.isarPreferences.clear();
    });
  }

  // ============= Stats & History Logic (Replacing SQL) =============

  static Future<SessionExercise?> getLastExerciseLog(
      String userId, String exerciseName) async {
    final exercises = await _isar.isarSessionExercises
        .filter()
        .nameEqualTo(exerciseName)
        .skippedEqualTo(false)
        .workout((q) => q.userIdEqualTo(userId).isDraftEqualTo(false))
        .findAll();

    if (exercises.isEmpty) return null;

    IsarSessionExercise? latestEx;
    DateTime? latestDate;

    for (final ex in exercises) {
      await ex.workout.load();
      final w = ex.workout.value;
      if (w == null) continue;

      if (latestDate == null || w.workoutDate.isAfter(latestDate)) {
        latestDate = w.workoutDate;
        latestEx = ex;
      }
    }

    if (latestEx == null) return null;

    await latestEx.sets.load();
    final sortedSets = latestEx.sets.toList()
      ..sort((a, b) => a.setNumber.compareTo(b.setNumber));

    final sets = <ExerciseSet>[];
    for (final iset in sortedSets) {
      await iset.segments.load();
      final sortedSegments = iset.segments.toList()
        ..sort((a, b) => a.segmentOrder.compareTo(b.segmentOrder));

      final segments = sortedSegments.map((iseg) {
        return SetSegment(
          id: iseg.segmentId,
          weight: iseg.weight,
          repsFrom: iseg.repsFrom,
          repsTo: iseg.repsTo,
          segmentOrder: iseg.segmentOrder,
          notes: iseg.notes!,
        );
      }).toList();

      sets.add(ExerciseSet(
        id: iset.setId,
        segments: segments,
        setNumber: iset.setNumber,
      ));
    }

    return SessionExercise(
      id: latestEx.exerciseId,
      name: latestEx.name,
      order: latestEx.order,
      skipped: latestEx.skipped,
      isTemplate: latestEx.isTemplate,
      sets: sets,
    );
  }

  static Future<List<Map<String, dynamic>>> getExerciseHistory(
      String exerciseName, String userId) async {
    final exercises = await _isar.isarSessionExercises
        .filter()
        .nameEqualTo(exerciseName)
        .workout((q) => q.userIdEqualTo(userId).isDraftEqualTo(false))
        .findAll();

    List<Map<String, dynamic>> result = [];

    for (final ex in exercises) {
      await ex.workout.load();
      await ex.sets.load();

      final workout = ex.workout.value;
      if (workout == null) continue;

      double sessionMaxWeight = 0;
      int sessionMaxWeightReps = 0;

      double sessionTotalVolume = 0;
      int sessionTotalReps = 0;
      double sessionEst1RM = 0;

      // Best Set Volume Trackers for this session
      double bestSetVolume = 0;
      double bestSetVolumeWeight = 0;
      int bestSetVolumeReps = 0;
      String bestSetVolumeBreakdown = '';

      final List<ExerciseSet> sessionSets = []; // Store domain sets

      // Helper to sort sets
      final sortedSets = ex.sets.toList()
        ..sort((a, b) => a.setNumber.compareTo(b.setNumber));

      for (final set in sortedSets) {
        await set.segments.load();

        double currentSetVolume = 0;
        List<String> breakdownParts = [];
        double firstSegmentWeight = 0;
        int firstSegmentReps = 0;
        bool isFirstSegment = true;

        final List<SetSegment> domainSegments = [];

        // Helper to sort segments
        final sortedSegments = set.segments.toList()
          ..sort((a, b) => a.segmentOrder.compareTo(b.segmentOrder));

        for (final seg in sortedSegments) {
          // CRITICAL: Use the same formula as SetSegment.totalReps
          // repsFrom and repsTo represent a range (e.g., 8-10 reps)
          // totalReps = repsTo - repsFrom + 1 (e.g., 8,9,10 = 3 reps)
          final effectiveReps = seg.repsTo - seg.repsFrom + 1;

          // 1. Max Weight Logic
          if (seg.weight > sessionMaxWeight) {
            sessionMaxWeight = seg.weight;
            sessionMaxWeightReps = effectiveReps;
          } else if (seg.weight == sessionMaxWeight) {
            // If same weight, take higher reps
            if (effectiveReps > sessionMaxWeightReps) {
              sessionMaxWeightReps = effectiveReps;
            }
          }

          // 2. Volume Logic
          final segVol = seg.weight * effectiveReps;
          currentSetVolume += segVol;
          sessionTotalVolume += segVol;
          sessionTotalReps += effectiveReps;

          // 3. 1RM Logic
          final setOneRM = seg.weight * (1 + effectiveReps / 30);
          if (setOneRM > sessionEst1RM) sessionEst1RM = setOneRM;

          // Breakdown info
          breakdownParts.add(
              '${seg.weight % 1 == 0 ? seg.weight.toInt() : seg.weight} kg x $effectiveReps');

          if (isFirstSegment) {
            firstSegmentWeight = seg.weight;
            firstSegmentReps = effectiveReps;
            isFirstSegment = false;
          }

          // Build domain segment
          domainSegments.add(SetSegment(
            id: seg.segmentId,
            weight: seg.weight,
            repsFrom: seg.repsFrom,
            repsTo: seg.repsTo,
            segmentOrder: seg.segmentOrder,
            notes: seg.notes ?? '',
          ));
        }

        // Build domain set
        sessionSets.add(ExerciseSet(
          id: set.setId,
          setNumber: set.setNumber,
          segments: domainSegments,
        ));

        // Check if this is the best volume set in this session
        if (currentSetVolume > bestSetVolume) {
          bestSetVolume = currentSetVolume;
          bestSetVolumeWeight = firstSegmentWeight;
          bestSetVolumeReps = firstSegmentReps;
          bestSetVolumeBreakdown = breakdownParts.join(' + ');
        }
      }

      result.add({
        'workoutDate': workout.workoutDate.toIso8601String(),
        // Session Totals
        'totalVolume': sessionTotalVolume,
        'totalReps': sessionTotalReps,
        'oneRM': sessionEst1RM,
        // Max Weight Records
        'maxWeight': sessionMaxWeight,
        'maxWeightReps': sessionMaxWeightReps,
        // Best Set Volume Records
        'bestSetVolume': bestSetVolume,
        'bestSetVolumeWeight': bestSetVolumeWeight,
        'bestSetVolumeReps': bestSetVolumeReps,
        'bestSetVolumeBreakdown': bestSetVolumeBreakdown,
        // Full Sets for UI
        'sets': sessionSets,
      });
    }

    result.sort((a, b) => DateTime.parse(a['workoutDate'])
        .compareTo(DateTime.parse(b['workoutDate'])));

    return result;
  }

  static Future<PersonalRecord?> getExercisePR(
      String userId, String exerciseName,
      {DateTime? startDate, DateTime? endDate}) async {
    final history = await getExerciseHistory(exerciseName, userId);
    if (history.isEmpty) return null;

    // Trackers for Global PRs
    double globalMaxWeight = 0;
    int globalMaxWeightReps = 0;

    double globalMaxSetVolume = 0;
    double globalMaxSetVolumeWeight = 0;
    int globalMaxSetVolumeReps = 0;
    String globalMaxSetVolumeBreakdown = '';

    double globalBestSessionVolume = 0;
    String? globalBestSessionDate;
    List<ExerciseSet>? globalBestSessionSets;

    for (final record in history) {
      final dateStr = record['workoutDate'] as String;
      final date = DateTime.parse(dateStr);

      if (startDate != null && date.isBefore(startDate)) continue;
      if (endDate != null && date.isAfter(endDate)) continue;

      // 1. Check Max Weight PR
      final rMaxWeight = record['maxWeight'] as double;
      if (rMaxWeight > globalMaxWeight) {
        globalMaxWeight = rMaxWeight;
        globalMaxWeightReps = record['maxWeightReps'] as int;
      }

      // 2. Check Max Set Volume PR
      final rBestSetVol = record['bestSetVolume'] as double;
      if (rBestSetVol > globalMaxSetVolume) {
        globalMaxSetVolume = rBestSetVol;
        globalMaxSetVolumeWeight = record['bestSetVolumeWeight'] as double;
        globalMaxSetVolumeReps = record['bestSetVolumeReps'] as int;
        globalMaxSetVolumeBreakdown =
            record['bestSetVolumeBreakdown'] as String;
      }

      // 3. Check Best Session Volume PR
      final rSessionVol = record['totalVolume'] as double;
      if (rSessionVol > globalBestSessionVolume) {
        globalBestSessionVolume = rSessionVol;
        globalBestSessionDate = dateStr;
        globalBestSessionSets = record['sets'] as List<ExerciseSet>;
      }
    }

    if (globalMaxWeight == 0 &&
        globalMaxSetVolume == 0 &&
        globalBestSessionVolume == 0) {
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
      bestSessionDate: globalBestSessionDate,
      bestSessionSets: globalBestSessionSets,
    );
  }

  static Future<List<String>> getExerciseNames(String userId) async {
    final allExercises = await _isar.isarSessionExercises
        .filter()
        .workout((q) => q.userIdEqualTo(userId).isDraftEqualTo(false))
        .nameProperty()
        .findAll();
    return allExercises.toSet().toList();
  }

  static Future<Map<String, PersonalRecord>> getAllPersonalRecords(
      String userId,
      {DateTime? startDate,
      DateTime? endDate}) async {
    // OPTIMIZED: Load ALL workouts at once instead of querying per exercise
    // This reduces hundreds of queries to just 1-2 queries

    final allWorkouts = await _isar.isarWorkoutSessions
        .filter()
        .userIdEqualTo(userId)
        .isDraftEqualTo(false)
        .findAll();

    // Group exercises by name and accumulate stats
    final Map<String, List<Map<String, dynamic>>> exerciseHistoryMap = {};

    for (final workout in allWorkouts) {
      // Date filtering
      if (startDate != null && workout.workoutDate.isBefore(startDate))
        continue;
      if (endDate != null && workout.workoutDate.isAfter(endDate)) continue;

      await workout.exercises.load();

      for (final ex in workout.exercises) {
        await ex.sets.load();

        double sessionMaxWeight = 0;
        int sessionMaxWeightReps = 0;
        double sessionTotalVolume = 0;
        int sessionTotalReps = 0;
        double sessionEst1RM = 0;
        double bestSetVolume = 0;
        String bestSetVolumeBreakdown = '';
        final List<ExerciseSet> sessionSets = [];

        final sortedSets = ex.sets.toList()
          ..sort((a, b) => a.setNumber.compareTo(b.setNumber));

        for (final set in sortedSets) {
          await set.segments.load();

          double currentSetVolume = 0;
          List<String> breakdownParts = [];
          final List<SetSegment> domainSegments = [];

          final sortedSegments = set.segments.toList()
            ..sort((a, b) => a.segmentOrder.compareTo(b.segmentOrder));

          for (final seg in sortedSegments) {
            final effectiveReps = seg.repsTo - seg.repsFrom + 1;

            if (seg.weight > sessionMaxWeight) {
              sessionMaxWeight = seg.weight;
              sessionMaxWeightReps = effectiveReps;
            } else if (seg.weight == sessionMaxWeight &&
                effectiveReps > sessionMaxWeightReps) {
              sessionMaxWeightReps = effectiveReps;
            }

            final segVol = seg.weight * effectiveReps;
            currentSetVolume += segVol;
            sessionTotalVolume += segVol;
            sessionTotalReps += effectiveReps;

            final setOneRM = seg.weight * (1 + effectiveReps / 30);
            if (setOneRM > sessionEst1RM) sessionEst1RM = setOneRM;

            breakdownParts.add(
                '${seg.weight % 1 == 0 ? seg.weight.toInt() : seg.weight} kg x $effectiveReps');

            domainSegments.add(SetSegment(
              id: seg.segmentId,
              weight: seg.weight,
              repsFrom: seg.repsFrom,
              repsTo: seg.repsTo,
              segmentOrder: seg.segmentOrder,
              notes: seg.notes ?? '',
            ));
          }

          sessionSets.add(ExerciseSet(
            id: set.setId,
            setNumber: set.setNumber,
            segments: domainSegments,
          ));

          if (currentSetVolume > bestSetVolume) {
            bestSetVolume = currentSetVolume;
            bestSetVolumeBreakdown = breakdownParts.join(' + ');
          }
        }

        // Add to history map
        exerciseHistoryMap.putIfAbsent(ex.name, () => []);
        exerciseHistoryMap[ex.name]!.add({
          'workoutDate': workout.workoutDate.toIso8601String(),
          'totalVolume': sessionTotalVolume,
          'totalReps': sessionTotalReps,
          'oneRM': sessionEst1RM,
          'maxWeight': sessionMaxWeight,
          'maxWeightReps': sessionMaxWeightReps,
          'bestSetVolume': bestSetVolume,
          'bestSetVolumeBreakdown': bestSetVolumeBreakdown,
          'sets': sessionSets,
        });
      }
    }

    // Now compute PRs from the accumulated history
    final Map<String, PersonalRecord> prs = {};

    for (final entry in exerciseHistoryMap.entries) {
      final exerciseName = entry.key;
      final history = entry.value;

      double globalMaxWeight = 0;
      int globalMaxWeightReps = 0;
      double globalMaxSetVolume = 0;
      String globalMaxSetVolumeBreakdown = '';
      double globalBestSessionVolume = 0;
      String? globalBestSessionDate;
      List<ExerciseSet>? globalBestSessionSets;

      for (final record in history) {
        final rMaxWeight = record['maxWeight'] as double;
        if (rMaxWeight > globalMaxWeight) {
          globalMaxWeight = rMaxWeight;
          globalMaxWeightReps = record['maxWeightReps'] as int;
        }

        final rBestSetVol = record['bestSetVolume'] as double;
        if (rBestSetVol > globalMaxSetVolume) {
          globalMaxSetVolume = rBestSetVol;
          globalMaxSetVolumeBreakdown =
              record['bestSetVolumeBreakdown'] as String;
        }

        final rSessionVol = record['totalVolume'] as double;
        if (rSessionVol > globalBestSessionVolume) {
          globalBestSessionVolume = rSessionVol;
          globalBestSessionDate = record['workoutDate'] as String;
          globalBestSessionSets = record['sets'] as List<ExerciseSet>;
        }
      }

      if (globalMaxWeight > 0 ||
          globalMaxSetVolume > 0 ||
          globalBestSessionVolume > 0) {
        prs[exerciseName] = PersonalRecord(
          maxWeight: globalMaxWeight,
          maxWeightReps: globalMaxWeightReps,
          maxVolume: globalMaxSetVolume,
          maxVolumeBreakdown: globalMaxSetVolumeBreakdown,
          bestSessionVolume: globalBestSessionVolume,
          bestSessionDate: globalBestSessionDate,
          bestSessionSets: globalBestSessionSets,
        );
      }
    }

    return prs;
  }

  // ============= Plans Operations =============

  static IsarWorkoutPlan _toIsarPlan(WorkoutPlan plan) {
    return IsarWorkoutPlan()
      ..planId = plan.id
      ..userId = plan.userId
      ..name = plan.name
      ..description = plan.description
      ..createdAt = plan.createdAt
      ..updatedAt = plan.updatedAt;
  }

  static Future<WorkoutPlan> _fromIsarPlan(IsarWorkoutPlan ip) async {
    await ip.exercises.load();
    final sortedExercises = ip.exercises.toList()
      ..sort((a, b) => a.order.compareTo(b.order));

    final exercises = sortedExercises
        .map((e) => PlanExercise(
              id: e.exerciseId,
              name: e.name,
              order: e.order,
            ))
        .toList();

    return WorkoutPlan(
      id: ip.planId,
      userId: ip.userId,
      name: ip.name,
      description: ip.description,
      exercises: exercises,
      createdAt: ip.createdAt,
      updatedAt: ip.updatedAt,
    );
  }

  static Future<void> createPlan(WorkoutPlan plan) async {
    await _isar.writeTxn(() async {
      final isarPlan = _toIsarPlan(plan);
      await _isar.isarWorkoutPlans.put(isarPlan);

      for (final exercise in plan.exercises) {
        final isarEx = IsarPlanExercise()
          ..exerciseId = exercise.id
          ..name = exercise.name
          ..order = exercise.order;
        await _isar.isarPlanExercises.put(isarEx);
        isarEx.plan.value = isarPlan;
        await isarEx.plan.save();
      }
    });
  }

  static Future<WorkoutPlan?> getPlan(String planId) async {
    final isarPlan =
        await _isar.isarWorkoutPlans.filter().planIdEqualTo(planId).findFirst();

    if (isarPlan == null) return null;
    return _fromIsarPlan(isarPlan);
  }

  static Future<List<WorkoutPlan>> getPlans(String userId) async {
    final isarPlans = await _isar.isarWorkoutPlans
        .filter()
        .userIdEqualTo(userId)
        .sortByCreatedAtDesc()
        .findAll();
    return await Future.wait(isarPlans.map((ip) => _fromIsarPlan(ip)));
  }

  static Future<void> updatePlan(WorkoutPlan plan) async {
    await deletePlan(plan.id);
    await createPlan(plan);
  }

  static Future<void> deletePlan(String planId) async {
    await _isar.writeTxn(() async {
      final isarPlan = await _isar.isarWorkoutPlans
          .filter()
          .planIdEqualTo(planId)
          .findFirst();

      if (isarPlan != null) {
        await isarPlan.exercises.load();
        final exerciseIds = isarPlan.exercises.map((e) => e.id).toList();
        await _isar.isarPlanExercises.deleteAll(exerciseIds);
        await _isar.isarWorkoutPlans.delete(isarPlan.id);
      }
    });
  }
}
