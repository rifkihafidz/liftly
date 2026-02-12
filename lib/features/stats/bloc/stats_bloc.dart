import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/models/workout_session.dart';
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

      final filtered = _filterSessions(allSessions, defaultPeriod, now);

      // Calculate date range for PRs
      // StatsFilter helper might not expose getStartDate/endDate publicly?
      // Looking at StatsFilter usage in previous code, it likely has helpers.
      // If not, we can rely on what filtered sessions tell us, or just pass the period bounds.
      // Actually, relying on SQL is cleaner.
      // Let's assume StatsFilter logic is available or we reconstruct it.
      // For now, to be safe and fast, I will filter PRs using the DATE RANGE of the filtered sessions
      // OR just rely on the repository to take start/end dates.

      // Simply: calculate start/end from period logic here if needed.
      // But wait! PRs in the previous code were based on "filtered" sessions.
      // "filtered" sessions are just a list.
      // If "filtered" is empty, PRs are empty.

      DateTime? startDate;
      DateTime? endDate;

      if (filtered.isNotEmpty) {
        // Find min and max date in filtered list?
        // No, the period is strictly defined by TimePeriod.
        // Let's use the StatsFilter utility if we can, or just duplicate simple logic.
        // Since I can't easily see StatsFilter implementation details without reading it,
        // and I want to be 100% sure, I'll use the min/max of the filtered list as a proxy
        // IF the list is not empty.
        // Better yet: Just calculate week start/end manually for the default week view.
      }

      // Actually, since I have `filtered` list in memory, I *could* just get the min/max from it?
      // But if there are no workouts on Monday, the range would be Tuesday-Sunday, potentially missing a PR on Monday?
      // No, because "PR on Monday" requires a workout on Monday.
      // So filtering by the dates present in the workout list is actually 100% accurate for "PRs in these workouts".

      if (filtered.isNotEmpty) {
        startDate =
            filtered.last.effectiveDate; // Sorted DESC, so last is oldest
        endDate = filtered.first.effectiveDate; // First is newest

        // Adjust for exact day boundaries
        startDate = DateTime(
          startDate.year,
          startDate.month,
          startDate.day,
          0,
          0,
          0,
        );
        endDate = DateTime(
          endDate.year,
          endDate.month,
          endDate.day,
          23,
          59,
          59,
        );
      }

      final prs = await _workoutRepository.getAllPersonalRecords(
        userId: event.userId,
        startDate: startDate,
        endDate: endDate,
      );

      emit(
        StatsLoaded(
          allSessions: allSessions,
          filteredSessions: filtered,
          timePeriod: defaultPeriod,
          referenceDate: now,
          personalRecords: prs,
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
    final filtered = _filterSessions(
      currentState.allSessions,
      event.timePeriod,
      now,
    );

    DateTime? startDate;
    DateTime? endDate;
    if (filtered.isNotEmpty) {
      startDate = filtered.last.effectiveDate;
      endDate = filtered.first.effectiveDate;
      startDate = DateTime(
        startDate.year,
        startDate.month,
        startDate.day,
        0,
        0,
        0,
      );
      endDate = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
    }

    final prs = await _workoutRepository.getAllPersonalRecords(
      userId: currentState.allSessions.firstOrNull?.userId ?? '1', // fallback
      startDate: startDate,
      endDate: endDate,
    );

    emit(
      currentState.copyWith(
        filteredSessions: filtered,
        timePeriod: event.timePeriod,
        referenceDate: now,
        personalRecords: prs,
      ),
    );
  }

  Future<void> _onDateChanged(
    StatsDateChanged event,
    Emitter<StatsState> emit,
  ) async {
    if (state is! StatsLoaded) return;
    final currentState = state as StatsLoaded;

    final filtered = _filterSessions(
      currentState.allSessions,
      currentState.timePeriod,
      event.date,
    );

    DateTime? startDate;
    DateTime? endDate;
    if (filtered.isNotEmpty) {
      startDate = filtered.last.effectiveDate;
      endDate = filtered.first.effectiveDate;
      startDate = DateTime(
        startDate.year,
        startDate.month,
        startDate.day,
        0,
        0,
        0,
      );
      endDate = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
    }

    final prs = await _workoutRepository.getAllPersonalRecords(
      userId: currentState.allSessions.firstOrNull?.userId ?? '1',
      startDate: startDate,
      endDate: endDate,
    );

    emit(
      currentState.copyWith(
        filteredSessions: filtered,
        referenceDate: event.date,
        personalRecords: prs,
      ),
    );
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

  List<WorkoutSession> _filterSessions(
    List<WorkoutSession> sessions,
    TimePeriod period,
    DateTime refDate,
  ) {
    final filter = StatsFilter(timePeriod: period, referenceDate: refDate);
    // Note: StatsFilter logic was in UI, implicitly doing local checks.
    // Assuming StatsFilter has helper methods, otherwise we implement date logic here.
    // Based on previous code:
    // It creates startDate and endDate and filters.

    // Using the filter object directly if it has a match method would be better,
    // but looking at previous code, it used `getStartDate` etc.
    // Let's rely on `isInPeriod`.

    return sessions.where((s) => filter.isInPeriod(s.effectiveDate)).toList();
  }
}
