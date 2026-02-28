import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/models/workout_session.dart';
import 'package:flutter/foundation.dart'; // for compute()
import '../../../core/models/personal_record.dart'; // Assuming this exists, I will verify
import '../../../core/models/stats_filter.dart';
import '../../../core/services/statistics_service.dart';
import '../../workout_log/repositories/workout_repository.dart';
import '../../../core/utils/app_logger.dart';
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
    // Always show loading and reset to default period (Week).
    // This ensures no flash of stale state when returning to the page.
    emit(StatsLoading());
    try {
      final allSessions = await _workoutRepository.getWorkouts(
        userId: event.userId,
        limit: null,
      );

      final now = DateTime.now();
      const period = TimePeriod.week;
      final refDate = now;

      final results = await compute(_calculateStatsIsolate, {
        'sessions': allSessions,
        'period': period,
        'refDate': refDate,
      });

      emit(
        StatsLoaded(
          allSessions: allSessions,
          filteredSessions: results['filtered'] as List<WorkoutSession>,
          timePeriod: period,
          referenceDate: refDate,
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
      AppLogger.error('StatsBloc', 'Stats recalc error', e);
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
      AppLogger.error('StatsBloc', 'Stats recalc error', e);
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

  final exerciseStats = <String, List<Map<String, dynamic>>>{};
  final originalExerciseData = <String, (String name, String variation)>{};

  for (final workout in filtered) {
    for (final exercise in workout.exercises) {
      if (exercise.skipped) continue;

      // Use format: exercise:variation for key (consistent with HiveService)
      final exName = exercise.name.toLowerCase();
      final variation = exercise.variation.toLowerCase();
      final key = '$exName:$variation';
      
      exerciseStats.putIfAbsent(key, () => []);
      // Store original case for later display
      originalExerciseData[key] = (exercise.name, exercise.variation);

      final metrics = StatisticsService.calculateSessionMetrics(
        exercise,
        workout.effectiveDate,
        exercise.sets,
      );

      exerciseStats[key]!.add(metrics);
    }
  }

  // Convert collected stats to PersonalRecord objects
  for (final entry in exerciseStats.entries) {
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
      prs[entry.key] = pr;
    }
  }

  return {'filtered': filtered, 'prs': prs};
}
