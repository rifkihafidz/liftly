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

  // PR Cache: Map<"userId:exerciseName", PersonalRecord>
  static final Map<String, PersonalRecord> _prCache = {};

  static void _invalidatePRCache({String? userId, String? exerciseName}) {
    if (userId != null && exerciseName != null) {
      // Invalidate specific exercise
      _prCache.remove('$userId:${exerciseName.toLowerCase()}');
    } else if (userId != null) {
      // Invalidate all for user
      _prCache.removeWhere((key, _) => key.startsWith('$userId:'));
    } else {
      // Invalidate all
      _prCache.clear();
    }
  }

  static Future<void> init() async {
    if (_isInitialized) return;

    final dir = kIsWeb ? '' : (await getApplicationDocumentsDirectory()).path;

    try {
      // Close any existing instance first
      if (_isInitialized && _isar.isOpen) {
        await _isar.close();
      }
    } catch (e) {
      // Ignore if no instance exists
    }

    try {
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

      // Run data correction once at startup
      await runDataCorrection();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Isar init error: $e');
      }
      rethrow;
    }
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
          ..userId = workout.userId // Denormalized
          ..directWorkoutId = workout.id // Denormalized
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
            ..userId = workout.userId // Denormalized
            ..directWorkoutId = workout.id // Denormalized
            ..directExerciseId = exercise.id // Denormalized
            ..setNumber = set.setNumber;

          await _isar.isarExerciseSets.put(isarSet);
          isarSet.exercise.value = isarExercise;
          await isarSet.exercise.save();

          for (final segment in set.segments) {
            // 4. Create Segment
            final isarSegment = IsarSetSegment()
              ..segmentId = segment.id
              ..userId = workout.userId // Denormalized
              ..directWorkoutId = workout.id // Denormalized
              ..directExerciseId = exercise.id // Denormalized
              ..directSetId = set.id // Denormalized
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

    // Invalidate PR cache for affected exercises
    for (final exercise in workout.exercises) {
      _invalidatePRCache(userId: workout.userId, exerciseName: exercise.name);
    }
  }

  /// One-time correction to populate new denormalized fields for existing data
  static Future<void> runDataCorrection() async {
    if (!_isInitialized) await init();

    // Check flag first to avoid expensive count query on startup
    final isDone = await getPreference('data_correction_v1_done');
    if (isDone == 'true') return;

    final count = await _isar.isarSetSegments.filter().userIdIsNull().count();

    if (count == 0) {
      await savePreference('data_correction_v1_done', 'true');
      return;
    }

    if (kDebugMode) {
      print('[Isar] Running data correction for $count segments...');
    }

    // Process in batches of 50 workouts to avoid memory issues
    // Using simple loop is safer than parallel for large writes
    final allWorkouts = await _isar.isarWorkoutSessions.where().findAll();

    int processed = 0;

    await _isar.writeTxn(() async {
      for (final workout in allWorkouts) {
        await workout.exercises.load();
        for (final ex in workout.exercises) {
          ex.userId = workout.userId;
          ex.directWorkoutId = workout.workoutId;
          await _isar.isarSessionExercises.put(ex);

          await ex.sets.load();
          for (final set in ex.sets) {
            set.userId = workout.userId;
            set.directWorkoutId = workout.workoutId;
            set.directExerciseId = ex.exerciseId;
            await _isar.isarExerciseSets.put(set);

            await set.segments.load();
            for (final seg in set.segments) {
              seg.userId = workout.userId;
              seg.directWorkoutId = workout.workoutId;
              seg.directExerciseId = ex.exerciseId;
              seg.directSetId = set.setId;
              await _isar.isarSetSegments.put(seg);
            }
          }
        }
        processed++;
        if (processed % 50 == 0) {
          // Yield to UI thread occasionally if needed, but in writeTxn we can't await easily.
          // Batching ideally should be separate transactions if really large.
          // For 20-100 workouts, single txn is fine.
        }
      }
      // Set flag inside txn
      final pref = IsarPreference()
        ..key = 'data_correction_v1_done'
        ..value = 'true'
        ..updatedAt = DateTime.now();
      await _isar.isarPreferences.put(pref);
    });

    if (kDebugMode) {
      print('[Isar] Data correction completed.');
    }
  }

  static Future<WorkoutSession?> getWorkoutById(String id) async {
    final isarWorkout = await _isar.isarWorkoutSessions
        .filter()
        .workoutIdEqualTo(id)
        .findFirst();

    if (isarWorkout == null) return null;
    return _fromIsarWorkout(isarWorkout);
  }

  /// Optimized batch loader that stitches data in memory
  /// Replaces _fromIsarWorkout (which causes N+1 queries)
  static Future<List<WorkoutSession>> _batchLoadWorkouts(
      List<IsarWorkoutSession> isarWorkouts) async {
    if (isarWorkouts.isEmpty) return [];

    final workoutIds = isarWorkouts.map((w) => w.workoutId).toList();

    if (kDebugMode) {
      debugPrint('[Isar] Batch loading ${workoutIds.length} workouts...');
    }

    // 1. Fetch ALL related data in just 3 parallel batch queries
    // Filter by workoutIds list
    final exercises = await _isar.isarSessionExercises
        .filter()
        .anyOf(workoutIds, (q, String id) => q.directWorkoutIdEqualTo(id))
        .findAll();

    final sets = await _isar.isarExerciseSets
        .filter()
        .anyOf(workoutIds, (q, String id) => q.directWorkoutIdEqualTo(id))
        .findAll();

    final segments = await _isar.isarSetSegments
        .filter()
        .anyOf(workoutIds, (q, String id) => q.directWorkoutIdEqualTo(id))
        .findAll();

    if (kDebugMode) {
      debugPrint(
          '[Isar] Fetched ${exercises.length} exercises, ${sets.length} sets, ${segments.length} segments.');
    }

    // 2. Index data for O(1) lookup
    // Map<WorkoutId, List<Exercise>>
    final exMap = <String, List<IsarSessionExercise>>{};
    for (final ex in exercises) {
      if (ex.directWorkoutId != null) {
        exMap.putIfAbsent(ex.directWorkoutId!, () => []).add(ex);
      }
    }

    // Map<ExerciseId, List<Set>>
    final setMap = <String, List<IsarExerciseSet>>{};
    for (final s in sets) {
      // Need directExerciseId which we added
      if (s.directExerciseId != null) {
        setMap.putIfAbsent(s.directExerciseId!, () => []).add(s);
      }
    }

    // Map<SetId, List<Segment>>
    final segMap = <String, List<IsarSetSegment>>{};
    for (final seg in segments) {
      if (seg.directSetId != null) {
        segMap.putIfAbsent(seg.directSetId!, () => []).add(seg);
      }
    }

    // 3. Stitch objects together in memory
    final result = <WorkoutSession>[];

    for (final iw in isarWorkouts) {
      final sessionExercises = <SessionExercise>[];
      final relatedExercises = exMap[iw.workoutId] ?? [];

      // Sort exercises
      relatedExercises.sort((a, b) => a.order.compareTo(b.order));

      for (final ie in relatedExercises) {
        final exerciseSets = <ExerciseSet>[];
        final relatedSets = setMap[ie.exerciseId] ?? [];

        // Sort sets
        relatedSets.sort((a, b) => a.setNumber.compareTo(b.setNumber));

        for (final iset in relatedSets) {
          final setSegments = <SetSegment>[];
          final relatedSegments = segMap[iset.setId] ?? [];

          // Sort segments
          relatedSegments
              .sort((a, b) => a.segmentOrder.compareTo(b.segmentOrder));

          for (final iseg in relatedSegments) {
            setSegments.add(SetSegment(
              id: iseg.segmentId,
              weight: iseg.weight,
              repsFrom: iseg.repsFrom,
              repsTo: iseg.repsTo,
              segmentOrder: iseg.segmentOrder,
              notes: iseg.notes ?? '',
            ));
          }

          exerciseSets.add(ExerciseSet(
            id: iset.setId,
            setNumber: iset.setNumber,
            segments: setSegments,
          ));
        }

        sessionExercises.add(SessionExercise(
          id: ie.exerciseId,
          name: ie.name,
          order: ie.order,
          skipped: ie.skipped,
          isTemplate: ie.isTemplate,
          sets: exerciseSets,
        ));
      }

      result.add(WorkoutSession(
        id: iw.workoutId,
        userId: iw.userId,
        planId: iw.planId,
        planName: iw.planName,
        workoutDate: iw.workoutDate,
        startedAt: iw.startedAt,
        endedAt: iw.endedAt,
        exercises: sessionExercises,
        createdAt: iw.createdAt,
        updatedAt: iw.updatedAt,
        isDraft: iw.isDraft,
      ));
    }

    return result;
  }

  static Future<List<WorkoutSession>> getWorkouts(String userId,
      {bool includeDrafts = false, int? limit, int? offset}) async {
    var query = _isar.isarWorkoutSessions.filter().userIdEqualTo(userId);

    if (!includeDrafts) {
      query = query.isDraftEqualTo(false);
    }

    // Performance Monitor
    if (kDebugMode && limit == null) {
      final count = await query.count();
      if (count > 100) {
        debugPrint(
            '[Isar] WARNING: Fetching $count workouts without limit. Consider using pagination.');
      }
    }

    // Build query with conditional modifiers
    // Using explicit branching to avoid QueryBuilder type reassignment issues
    final q = query.sortByWorkoutDateDesc();

    List<IsarWorkoutSession> isarWorkouts;

    if (offset != null && limit != null) {
      isarWorkouts = await q.offset(offset).limit(limit).findAll();
    } else if (limit != null) {
      isarWorkouts = await q.limit(limit).findAll();
    } else if (offset != null) {
      isarWorkouts = await q.offset(offset).findAll();
    } else {
      isarWorkouts = await q.findAll();
    }

    // Use optimized batch loader
    return await _batchLoadWorkouts(isarWorkouts);
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

  static Future<void> importWorkouts(List<WorkoutSession> workouts) async {
    if (workouts.isEmpty) return;

    await _isar.writeTxn(() async {
      // Step 1: Collect everything with link maps
      final isarWorkouts = <IsarWorkoutSession>[];
      final exerciseSetsMap = <IsarSessionExercise, List<IsarExerciseSet>>{};
      final setSegmentsMap = <IsarExerciseSet, List<IsarSetSegment>>{};

      for (final w in workouts) {
        final isarWorkout = _toIsarWorkout(w);
        isarWorkouts.add(isarWorkout);

        for (final exercise in w.exercises) {
          final isarExercise = IsarSessionExercise()
            ..exerciseId = exercise.id
            ..userId = w.userId
            ..directWorkoutId = w.id
            ..name = exercise.name
            ..order = exercise.order
            ..skipped = exercise.skipped
            ..isTemplate = exercise.isTemplate;

          isarWorkout.exercises.add(isarExercise); // Add to link
          exerciseSetsMap[isarExercise] = [];

          for (final set in exercise.sets) {
            final isarSet = IsarExerciseSet()
              ..setId = set.id
              ..userId = w.userId
              ..directWorkoutId = w.id
              ..directExerciseId = exercise.id
              ..setNumber = set.setNumber;

            isarExercise.sets.add(isarSet); // Add to link
            exerciseSetsMap[isarExercise]!.add(isarSet);
            setSegmentsMap[isarSet] = [];

            for (final segment in set.segments) {
              final isarSegment = IsarSetSegment()
                ..segmentId = segment.id
                ..userId = w.userId
                ..directWorkoutId = w.id
                ..directExerciseId = exercise.id
                ..directSetId = set.id
                ..weight = segment.weight
                ..repsFrom = segment.repsFrom
                ..repsTo = segment.repsTo
                ..segmentOrder = segment.segmentOrder
                ..notes = segment.notes;

              isarSet.segments.add(isarSegment); // Add to link
              setSegmentsMap[isarSet]!.add(isarSegment);
            }
          }
        }
      }

      // Step 2: Put all objects
      await _isar.isarWorkoutSessions.putAll(isarWorkouts);

      final allExercises = <IsarSessionExercise>[];
      for (final w in isarWorkouts) {
        allExercises.addAll(w.exercises);
      }
      await _isar.isarSessionExercises.putAll(allExercises);

      final allSets = <IsarExerciseSet>[];
      for (final ex in allExercises) {
        allSets.addAll(exerciseSetsMap[ex] ?? []);
      }
      await _isar.isarExerciseSets.putAll(allSets);

      final allSegments = <IsarSetSegment>[];
      for (final s in allSets) {
        allSegments.addAll(setSegmentsMap[s] ?? []);
      }
      await _isar.isarSetSegments.putAll(allSegments);

      // Step 3: Explicitly save all links (Required for forward links)
      for (final w in isarWorkouts) {
        await w.exercises.save();
      }
      for (final ex in allExercises) {
        await ex.sets.save();
      }
      for (final s in allSets) {
        await s.segments.save();
      }
    });
  }

  static Future<void> importPlans(List<WorkoutPlan> plans) async {
    if (plans.isEmpty) return;

    await _isar.writeTxn(() async {
      final isarPlans = <IsarWorkoutPlan>[];
      final planExercisesMap = <IsarWorkoutPlan, List<IsarPlanExercise>>{};

      for (final p in plans) {
        final isarPlan = _toIsarPlan(p);
        isarPlans.add(isarPlan);
        planExercisesMap[isarPlan] = [];

        for (final ex in p.exercises) {
          final isarEx = IsarPlanExercise()
            ..exerciseId = ex.id
            ..directPlanId = p.id
            ..name = ex.name
            ..order = ex.order;

          isarPlan.exercises.add(isarEx); // Add to link
          planExercisesMap[isarPlan]!.add(isarEx);
        }
      }

      await _isar.isarWorkoutPlans.putAll(isarPlans);

      final allPlanEx = <IsarPlanExercise>[];
      for (final p in isarPlans) {
        allPlanEx.addAll(planExercisesMap[p] ?? []);
      }
      await _isar.isarPlanExercises.putAll(allPlanEx);

      for (final p in isarPlans) {
        await p.exercises.save();
      }
    });
  }

  static Future<void> deleteWorkout(String workoutId) async {
    // Fetch workout BEFORE deletion to know which exercises to invalidate cache for
    final workout = await getWorkoutById(workoutId);

    await _isar.writeTxn(() async {
      // 1. Delete Main Workout
      await _isar.isarWorkoutSessions
          .filter()
          .workoutIdEqualTo(workoutId)
          .deleteAll();

      // 2. Cascade Delete using Denormalized Index (Fast)
      // Delete Exercises
      await _isar.isarSessionExercises
          .filter()
          .directWorkoutIdEqualTo(workoutId)
          .deleteAll();

      // Delete Sets
      await _isar.isarExerciseSets
          .filter()
          .directWorkoutIdEqualTo(workoutId)
          .deleteAll();

      // Delete Segments
      await _isar.isarSetSegments
          .filter()
          .directWorkoutIdEqualTo(workoutId)
          .deleteAll();
    });

    // Invalidate PR cache for affected exercises
    if (workout != null) {
      for (final exercise in workout.exercises) {
        _invalidatePRCache(userId: workout.userId, exerciseName: exercise.name);
      }
    }
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
    // 1. Get candidate workouts containing this exercise name
    // Optimization: Filter via SessionExercise first to get WorkoutIds
    final exercises = await _isar.isarSessionExercises
        .filter()
        .nameEqualTo(exerciseName, caseSensitive: false)
        .skippedEqualTo(false)
        .userIdEqualTo(userId) // Optimization: use indexed userId
        .findAll();

    if (exercises.isEmpty) return null;

    // Get unique workout IDs filtering out drafts (check workout draft status later or join?)
    // Faster to just fetch workouts by IDs and filter in memory
    final workoutIds =
        exercises.map((e) => e.directWorkoutId!).toSet().toList();

    // Fetch Only Valid Workouts (Not Draft)
    final validWorkouts = await _isar.isarWorkoutSessions
        .filter()
        .anyOf(workoutIds, (q, String id) => q.workoutIdEqualTo(id))
        .isDraftEqualTo(false) // Filter drafts
        .sortByWorkoutDateDesc() // Get latest
        .limit(1) // Only need the latest
        .findAll();

    if (validWorkouts.isEmpty) return null;

    final latestWorkout = validWorkouts.first;

    // Batch load just this one workout (reusing our fast loader)
    final loadedWorkouts = await _batchLoadWorkouts([latestWorkout]);
    if (loadedWorkouts.isEmpty) return null;

    final fullWorkout = loadedWorkouts.first;

    // Return correct exercise from it
    try {
      return fullWorkout.exercises.firstWhere((e) => e.name == exerciseName);
    } catch (_) {
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>> getExerciseHistory(
      String exerciseName, String userId) async {
    // 1. Get candidate workouts
    final exercises = await _isar.isarSessionExercises
        .filter()
        .nameEqualTo(exerciseName, caseSensitive: false)
        .userIdEqualTo(userId)
        .findAll();

    if (exercises.isEmpty) return [];

    final workoutIds =
        exercises.map((e) => e.directWorkoutId!).toSet().toList();

    final validWorkouts = await _isar.isarWorkoutSessions
        .filter()
        .anyOf(workoutIds, (q, String id) => q.workoutIdEqualTo(id))
        .isDraftEqualTo(false)
        .sortByWorkoutDateDesc()
        .findAll();

    // 2. Batch load all these workouts efficiently
    final fullWorkouts = await _batchLoadWorkouts(validWorkouts);

    List<Map<String, dynamic>> result = [];

    for (final workout in fullWorkouts) {
      // Find relevant exercise in this workout
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

        // ... Logic same as before ...

        for (final set in ex.sets) {
          final segments = set.segments; // Already loaded via batch

          double currentSetVolume = 0;
          List<String> breakdownParts = [];

          double firstSegmentWeight = 0;
          int totalSetReps = 0;

          for (int i = 0; i < segments.length; i++) {
            final seg = segments[i];
            final effectiveReps = seg.repsTo - seg.repsFrom + 1;

            if (i == 0) {
              firstSegmentWeight = seg.weight;
            }
            totalSetReps += effectiveReps;
            // Add to session total
            sessionTotalReps += effectiveReps;

            // 1. Max Weight Logic
            if (seg.weight > sessionMaxWeight) {
              sessionMaxWeight = seg.weight;
              sessionMaxWeightReps = effectiveReps;
            } else if (seg.weight == sessionMaxWeight) {
              if (effectiveReps > sessionMaxWeightReps) {
                sessionMaxWeightReps = effectiveReps;
              }
            }

            // 2. Volume Logic
            final segVol = seg.weight * effectiveReps;
            currentSetVolume += segVol;
            sessionTotalVolume += segVol;

            // Breakdown
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

        if (kDebugMode) {
          debugPrint(
              '[PR_DEBUG] ${workout.workoutDate} - MaxWeight: $sessionMaxWeight, BestSetVol: $bestSetVolume');
        }

        result.add({
          'workoutDate': workout.workoutDate.toIso8601String(),
          'totalVolume': sessionTotalVolume,
          'totalReps': sessionTotalReps, // Added totalReps
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

    result.sort((a, b) => DateTime.parse(a['workoutDate'])
        .compareTo(DateTime.parse(b['workoutDate'])));

    return result;
  }

  static Future<PersonalRecord?> getExercisePR(
      String userId, String exerciseName,
      {DateTime? startDate, DateTime? endDate}) async {
    // Check cache first (only for queries without date filters)
    if (startDate == null && endDate == null) {
      final cacheKey = '$userId:${exerciseName.toLowerCase()}';
      if (_prCache.containsKey(cacheKey)) {
        if (kDebugMode) debugPrint('[PR_DEBUG] Cache hit for: $exerciseName');
        return _prCache[cacheKey];
      }
    }

    if (kDebugMode) debugPrint('[PR_DEBUG] querying for: $exerciseName');
    final history = await getExerciseHistory(exerciseName, userId);

    if (history.isEmpty) {
      if (kDebugMode) debugPrint('[PR_DEBUG] History empty for $exerciseName');
      return null;
    }

    if (kDebugMode) {
      debugPrint(
          '[PR_DEBUG] Found ${history.length} history records for $exerciseName');
    }

    // Trackers for Global PRs
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
      final rSessionReps = record['totalReps'] as int? ?? 0;

      // Priority: Volume > Reps (if volume is 0)
      bool isNewBest = false;

      if (rSessionVol > globalBestSessionVolume) {
        isNewBest = true;
      } else if (globalBestSessionVolume == 0 && rSessionVol == 0) {
        // Logic for bodyweight exercises (Volume is 0, so check reps)
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
    );

    // Cache result (only for queries without date filters)
    if (startDate == null && endDate == null) {
      final cacheKey = '$userId:${exerciseName.toLowerCase()}';
      _prCache[cacheKey] = pr;
    }

    return pr;
  }

  static Future<List<String>> getExerciseNames(String userId) async {
    final distinctNames = await _isar.isarSessionExercises
        .filter()
        .userIdEqualTo(userId)
        .distinctByName()
        .nameProperty()
        .findAll();
    return distinctNames;
  }

  static Future<Map<String, PersonalRecord>> getAllPersonalRecords(
      String userId,
      {DateTime? startDate,
      DateTime? endDate}) async {
    // ULTRA-FAST QUERY: Fetch all segments flat filtered by userId
    // This avoids N+1 loading and object graph traversal overhead

    // 1. Fetch relevant workouts map (Id -> Date) to filter by date range
    final workoutQuery = _isar.isarWorkoutSessions
        .filter()
        .userIdEqualTo(userId)
        .isDraftEqualTo(false);

    final workouts = await workoutQuery.findAll();

    final workoutDateMap = <String, DateTime>{};
    for (final w in workouts) {
      if (startDate != null && w.workoutDate.isBefore(startDate)) continue;
      if (endDate != null && w.workoutDate.isAfter(endDate)) continue;
      workoutDateMap[w.workoutId] = w.workoutDate;
    }

    if (workoutDateMap.isEmpty) return {};

    // 2. Fetch ALL segments for this user (Single Flat Query)
    // This looks scary (fetch all) but local DBs are extremely fast at sequential reads.
    // Fetching 10k items takes ~20ms in Isar. Traversing 10k items via Links takes ~3s.
    final allSegments =
        await _isar.isarSetSegments.filter().userIdEqualTo(userId).findAll();

    // 3. Fetch Exercise Names Map (Single Query)
    final exercises = await _isar.isarSessionExercises
        .filter()
        .userIdEqualTo(userId)
        .findAll();

    final exNameMap = <String, String>{};
    for (final ex in exercises) {
      exNameMap[ex.exerciseId] = ex.name;
    }

    // 4. Process in Memory (Group by Exercise -> Workout -> Set)
    // Map<ExerciseName, Map<WorkoutId, Map<SetId, List<Seg>>>>
    final exMap = <String, Map<String, Map<String, List<IsarSetSegment>>>>{};

    for (final seg in allSegments) {
      final wId = seg.directWorkoutId;
      // Skip segments not belonging to filtered workouts (e.g. date range mismatch)
      if (wId == null || !workoutDateMap.containsKey(wId)) continue;

      final exId = seg.directExerciseId;
      if (exId == null) continue;

      final exName = exNameMap[exId] ?? 'Unknown';
      final sId = seg.directSetId ?? 'unknown';

      exMap.putIfAbsent(exName, () => {});
      exMap[exName]!.putIfAbsent(wId, () => {});
      exMap[exName]![wId]!.putIfAbsent(sId, () => []).add(seg);
    }

    // 5. Compute Stats per Exercise
    final Map<String, PersonalRecord> prs = {};

    for (final entry in exMap.entries) {
      final exName = entry.key;
      final workouts = entry.value;

      double globalMaxWeight = 0;
      int globalMaxWeightReps = 0;

      double globalMaxSetVolume = 0;
      String globalMaxSetVolumeBreakdown = '';

      double globalBestSessionVolume = 0;
      String? globalBestSessionDate;
      String? globalBestSessionWorkoutId;

      for (final wEntry in workouts.entries) {
        final wId = wEntry.key;
        final sets = wEntry.value;
        final wDate = workoutDateMap[wId]!;

        double sessionVolume = 0;

        for (final sEntry in sets.entries) {
          final segments = sEntry.value;
          // Sort segments by order
          segments.sort((a, b) => a.segmentOrder.compareTo(b.segmentOrder));

          double setVolume = 0;
          List<String> breakdownParts = [];

          for (final seg in segments) {
            final effectiveReps = seg.repsTo - seg.repsFrom + 1;

            // Max Weight Check
            if (seg.weight > globalMaxWeight) {
              globalMaxWeight = seg.weight;
              globalMaxWeightReps = effectiveReps;
            } else if (seg.weight == globalMaxWeight) {
              if (effectiveReps > globalMaxWeightReps) {
                globalMaxWeightReps = effectiveReps;
              }
            }

            final vol = seg.weight * effectiveReps;
            setVolume += vol;
            sessionVolume += vol;

            breakdownParts.add(
                '${seg.weight % 1 == 0 ? seg.weight.toInt() : seg.weight} kg x $effectiveReps');
          }

          // Max Set Volume Check
          if (setVolume > globalMaxSetVolume) {
            globalMaxSetVolume = setVolume;
            globalMaxSetVolumeBreakdown = breakdownParts.join(' + ');
          }
        }

        // Best Session Volume Check
        if (sessionVolume > globalBestSessionVolume) {
          globalBestSessionVolume = sessionVolume;
          globalBestSessionDate = wDate.toIso8601String();
          globalBestSessionWorkoutId = wId;
        }
      }

      if (globalMaxWeight > 0 ||
          globalMaxSetVolume > 0 ||
          globalBestSessionVolume > 0) {
        // Hydrate Best Session Sets (Simplified for Performance)
        List<ExerciseSet>? bestSessionSets;

        if (globalBestSessionWorkoutId != null) {
          final bestSessionData = workouts[globalBestSessionWorkoutId];
          if (bestSessionData != null) {
            // Reconstruct Sets for UI display
            bestSessionSets = [];
            for (final sEntry in bestSessionData.entries) {
              final sId = sEntry.key;
              final segs = sEntry.value;

              final domainSegments = segs.map((iseg) {
                return SetSegment(
                  id: iseg.segmentId,
                  weight: iseg.weight,
                  repsFrom: iseg.repsFrom,
                  repsTo: iseg.repsTo,
                  segmentOrder: iseg.segmentOrder,
                  notes: iseg.notes ?? '',
                );
              }).toList();

              bestSessionSets.add(ExerciseSet(
                  id: sId,
                  setNumber:
                      0, // Not critical for snippet view, can fetch if needed
                  segments: domainSegments));
            }
            // Try to sort sets (best effort without setNumber query)
            // The snippet view usually just iterates. If structure is important, we accept this simplification.
          }
        }

        prs[exName] = PersonalRecord(
          maxWeight: globalMaxWeight,
          maxWeightReps: globalMaxWeightReps,
          maxVolume: globalMaxSetVolume,
          maxVolumeWeight: 0,
          maxVolumeReps: 0,
          maxVolumeBreakdown: globalMaxSetVolumeBreakdown,
          bestSessionVolume: globalBestSessionVolume,
          bestSessionDate: globalBestSessionDate,
          bestSessionSets: bestSessionSets,
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

  static WorkoutPlan _fromIsarPlanWithExercises(
      IsarWorkoutPlan ip, List<IsarPlanExercise> exercises) {
    return WorkoutPlan(
      id: ip.planId,
      userId: ip.userId,
      name: ip.name,
      description: ip.description,
      exercises: exercises
          .map((e) => PlanExercise(
                id: e.exerciseId,
                name: e.name,
                order: e.order,
              ))
          .toList(),
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
          ..directPlanId = plan.id
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

    final exercises = await _isar.isarPlanExercises
        .filter()
        .directPlanIdEqualTo(planId)
        .sortByOrder()
        .findAll();

    return _fromIsarPlanWithExercises(isarPlan, exercises);
  }

  static Future<List<WorkoutPlan>> getPlans(String userId) async {
    final isarPlans = await _isar.isarWorkoutPlans
        .filter()
        .userIdEqualTo(userId)
        .sortByCreatedAtDesc()
        .findAll();

    if (isarPlans.isEmpty) return [];

    // Batch load exercises
    final planIds = isarPlans.map((p) => p.planId).toList();
    final allExercises = await _isar.isarPlanExercises
        .filter()
        .anyOf(planIds, (q, String id) => q.directPlanIdEqualTo(id))
        .findAll();

    // Group by planId
    final exMap = <String, List<IsarPlanExercise>>{};
    for (final ex in allExercises) {
      if (ex.directPlanId != null) {
        exMap.putIfAbsent(ex.directPlanId!, () => []).add(ex);
      }
    }

    return isarPlans.map((ip) {
      final relatedExercises = exMap[ip.planId] ?? [];
      relatedExercises.sort((a, b) => a.order.compareTo(b.order));
      return _fromIsarPlanWithExercises(ip, relatedExercises);
    }).toList();
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
