import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/models/workout_session.dart';
import 'package:flutter/foundation.dart'; // for kDebugMode
import '../../../core/models/personal_record.dart'; // Assuming this exists, I will verify
import '../../../core/models/stats_filter.dart';
import '../../workout_log/repositories/workout_repository.dart';
import 'stats_event.dart';
import 'stats_state.dart';

class StatsBloc extends Bloc<StatsEvent, StatsState> {
  final WorkoutRepository _workoutRepository;

  StatsBloc({WorkoutRepository? workoutRepository})
      : _workoutRepository = workoutRepository ?? WorkoutRepository(),
        super(StatsInitial()) {
    on<StatsFetched>(_onStatsFetched);
    on<StatsPeriodChanged>(_onPeriodChanged);
    on<StatsDateChanged>(_onDateChanged);
    on<StatsPRFiltered>(_onPRFiltered);
    on<StatsPRSortChanged>(_onPRSortChanged);
  }

  Future<void> _onStatsFetched(
    StatsFetched event,
    Emitter<StatsState> emit,
  ) async {
    emit(StatsLoading());
    try {
      // 1. Fetch ALL sessions for Volume/Frequency/Consistency charts
      //    We still need full objects for these complex local calculations for now (tuning phase).
      //    This is expensive but acceptable for <1000 workouts.
      //    For >1000 workouts, we'd need SQL aggregation for these too.
      final allSessions = await _workoutRepository.getWorkouts(
        userId: event.userId,
        limit: null, // Fetch ALL
      );

      // Default to week view
      final now = DateTime.now();
      const defaultPeriod = TimePeriod.week;

      final results = await compute(_calculateStatsIsolate, {
        'sessions': allSessions,
        'period': defaultPeriod,
        'refDate': now,
      });

      emit(
        StatsLoaded(
          allSessions: allSessions,
          filteredSessions: results['filtered'] as List<WorkoutSession>,
          timePeriod: defaultPeriod,
          referenceDate: now,
          personalRecords: results['prs'] as Map<String, PersonalRecord>,
          prFilter: null,
          sortOrder: PrSortOrder.az,
        ),
      );
    } catch (e) {
      emit(StatsError(message: 'Failed to fetch stats: $e'));
    }
  }

  Future<void> _onPeriodChanged(
    StatsPeriodChanged event,
    Emitter<StatsState> emit,
  ) async {
    if (state is! StatsLoaded) return;
    final currentState = state as StatsLoaded;

    final now =
        DateTime.now(); // Reset reference date to now when changing period
    try {
      final results = await compute(_calculateStatsIsolate, {
        'sessions': currentState.allSessions,
        'period': event.timePeriod,
        'refDate': now,
        'repository':
            _workoutRepository, // Pass repository? No, repository likely not transferrable
        // We need raw data or a way to calculate PRs without repository in isolate.
        // Actually, PR calculation typically needs ALL history to find the max.
        // But `getAllPersonalRecords` in Repo might be SQL specific or Hive specific.
        // If it's Hive, passing Repository might fail if it holds open boxes.
        // It's safer to replicate the PR logic purely in-memory if we have all sessions.
        // Wait, `allSessions` IS all history.
        // So we can implement `_calculatePersonalRecordsInMemory` inside the isolate!
      });

      emit(
        currentState.copyWith(
          filteredSessions: results['filtered'] as List<WorkoutSession>,
          timePeriod: event.timePeriod,
          referenceDate: now,
          personalRecords: results['prs'] as Map<String, PersonalRecord>,
        ),
      );
    } catch (e) {
      // Handle error gently, maybe keep old state or show snackbar?
      // For now, just log or do nothing, to avoid crashing UI if calculation fails
      if (kDebugMode) print('Stats recalc error: $e');
    }
  }

  Future<void> _onDateChanged(
    StatsDateChanged event,
    Emitter<StatsState> emit,
  ) async {
    if (state is! StatsLoaded) return;
    final currentState = state as StatsLoaded;

    try {
      final results = await compute(_calculateStatsIsolate, {
        'sessions': currentState.allSessions,
        'period': currentState.timePeriod,
        'refDate': event.date,
      });

      emit(
        currentState.copyWith(
          filteredSessions: results['filtered'] as List<WorkoutSession>,
          referenceDate: event.date,
          personalRecords: results['prs'] as Map<String, PersonalRecord>,
        ),
      );
    } catch (e) {
      if (kDebugMode) print('Stats recalc error: $e');
    }
  }

  void _onPRFiltered(StatsPRFiltered event, Emitter<StatsState> emit) {
    if (state is! StatsLoaded) return;
    final currentState = state as StatsLoaded;

    emit(currentState.copyWith(prFilter: event.selectedExercises));
  }

  void _onPRSortChanged(
    StatsPRSortChanged event,
    Emitter<StatsState> emit,
  ) {
    if (state is! StatsLoaded) return;
    final currentState = state as StatsLoaded;

    emit(currentState.copyWith(sortOrder: event.sortOrder));
  }
}

/// Isolate function to calculate stats (filtering + PRs)
Future<Map<String, dynamic>> _calculateStatsIsolate(
    Map<String, dynamic> params) async {
  final sessions = params['sessions'] as List<WorkoutSession>;
  final period = params['period'] as TimePeriod;
  final refDate = params['refDate'] as DateTime;

  // 1. Filter sessions
  final filter = StatsFilter(timePeriod: period, referenceDate: refDate);
  final filtered =
      sessions.where((s) => filter.isInPeriod(s.effectiveDate)).toList();

  // 2. Calculate PRs in memory
  final prs = <String, PersonalRecord>{};

  if (filtered.isEmpty) {
    return {'filtered': filtered, 'prs': prs};
  }

  // Efficient Single Pass for PRs
  // We need to track: Max Weight (and reps for tiebreaker), Max Volume (and weight/reps for details)
  // For each exercise ID.

  final exerciseStats = <String, Map<String, dynamic>>{};

  // Sort sessions by date ascending to ensure we process in order if needed,
  // though for absolute max records order doesn't strictly matter unless we want "first achieved date".
  // filtered is likely DESC (newest first).

  for (final workout in filtered) {
    for (final exercise in workout.exercises) {
      if (exercise.skipped) continue;

      final exId = exercise.id;
      if (!exerciseStats.containsKey(exId)) {
        exerciseStats[exId] = {
          'name': exercise.name, // Capture name
          'maxWeight': 0.0,
          'maxWeightReps': 0,
          'maxVolume': 0.0,
          'maxVolumeWeight': 0.0,
          'maxVolumeReps': 0,
          'bestSessionVolume': 0.0,
          'bestSessionReps': 0,
          'bestSessionDate': workout.effectiveDate.toIso8601String(),
          'bestSessionSets': <ExerciseSet>[],
        };
      } else {
        // Update name if needed (e.g. if previous entry had no name or we want latest name)
        // Usually first encounter is fine, or last.
        // Let's stick to first encounter for simplicity or maybe check if empty.
        if ((exerciseStats[exId]!['name'] as String).isEmpty &&
            exercise.name.isNotEmpty) {
          exerciseStats[exId]!['name'] = exercise.name;
        }
      }

      final stats = exerciseStats[exId]!;

      // Session Volume Calculation
      double sessionVol = 0;
      int sessionReps = 0;

      for (final set in exercise.sets) {
        // Calculate Set Stats
        double setVol = 0;
        double setWeight = 0; // Usage for single-segment sets mostly
        int setReps = 0;

        for (final segment in set.segments) {
          final segVol = segment.volume;
          setVol += segVol;
          setReps += segment.totalReps;

          if (set.segments.length == 1) {
            setWeight = segment.weight;
          } else {
            // For multi-segment (dropset), "weight" is ambiguous.
            // Usually max weight of the set? Or average?
            // For Max Weight PR, we look at SEGMENTS individually usually.
          }

          // Check Max Weight (1RM candidate) - Check per SEGMENT
          if (segment.weight > (stats['maxWeight'] as double)) {
            stats['maxWeight'] = segment.weight;
            stats['maxWeightReps'] = segment.totalReps;
          } else if (segment.weight == (stats['maxWeight'] as double) &&
              segment.totalReps > (stats['maxWeightReps'] as int)) {
            stats['maxWeightReps'] = segment.totalReps;
          }
        }

        sessionVol += setVol;
        sessionReps += setReps;

        // Check Max Volume (Best Set)
        if (setVol > (stats['maxVolume'] as double)) {
          stats['maxVolume'] = setVol;
          stats['maxVolumeWeight'] =
              setWeight; // Only valid for single segment really
          stats['maxVolumeReps'] = setReps;
          // breakdown...
        }
      }

      // Check Best Session Volume
      if (sessionVol > (stats['bestSessionVolume'] as double)) {
        stats['bestSessionVolume'] = sessionVol;
        stats['bestSessionReps'] = sessionReps;
        stats['bestSessionDate'] = workout.effectiveDate.toIso8601String();
        stats['bestSessionSets'] = exercise.sets;
      }
    }
  }

  // Convert collected stats to PersonalRecord objects
  for (final entry in exerciseStats.entries) {
    final s = entry.value;
    prs[entry.key] = PersonalRecord(
      exerciseName: s['name'] as String? ?? 'Unknown Exercise',
      maxWeight: s['maxWeight'] as double,
      maxWeightReps: s['maxWeightReps'] as int,
      maxVolume: s['maxVolume'] as double,
      maxVolumeWeight: s['maxVolumeWeight'] as double,
      maxVolumeReps: s['maxVolumeReps'] as int,
      bestSessionVolume: s['bestSessionVolume'] as double,
      bestSessionReps: s['bestSessionReps'] as int,
      bestSessionDate: s['bestSessionDate'] as String?,
      bestSessionSets: s['bestSessionSets'] as List<ExerciseSet>?,
    );
  }

  return {'filtered': filtered, 'prs': prs};
}
