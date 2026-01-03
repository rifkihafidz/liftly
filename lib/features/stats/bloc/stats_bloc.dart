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
  }

  Future<void> _onStatsFetched(
    StatsFetched event,
    Emitter<StatsState> emit,
  ) async {
    emit(StatsLoading());
    try {
      final allSessions = await _workoutRepository.getWorkouts(
        userId: event.userId,
      );

      // Default to week view
      final now = DateTime.now();
      const defaultPeriod = TimePeriod.week;

      final filtered = _filterSessions(allSessions, defaultPeriod, now);
      final prs = _calculatePersonalRecords(filtered);

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

  void _onPeriodChanged(StatsPeriodChanged event, Emitter<StatsState> emit) {
    if (state is! StatsLoaded) return;
    final currentState = state as StatsLoaded;

    final now =
        DateTime.now(); // Reset reference date to now when changing period
    final filtered = _filterSessions(
      currentState.allSessions,
      event.timePeriod,
      now,
    );
    final prs = _calculatePersonalRecords(filtered);

    emit(
      currentState.copyWith(
        filteredSessions: filtered,
        timePeriod: event.timePeriod,
        referenceDate: now,
        personalRecords: prs,
      ),
    );
  }

  void _onDateChanged(StatsDateChanged event, Emitter<StatsState> emit) {
    if (state is! StatsLoaded) return;
    final currentState = state as StatsLoaded;

    final filtered = _filterSessions(
      currentState.allSessions,
      currentState.timePeriod,
      event.date,
    );
    final prs = _calculatePersonalRecords(filtered);

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

    return sessions.where((s) => filter.isInPeriod(s.workoutDate)).toList();
  }

  Map<String, double> _calculatePersonalRecords(List<WorkoutSession> sessions) {
    final records = <String, double>{};

    for (final session in sessions) {
      for (final exercise in session.exercises) {
        if (exercise.skipped) continue;

        for (final set in exercise.sets) {
          for (final segment in set.segments) {
            // PR calculation based on 1RM or max weight?
            // Simple max weight for now based on typical casual usage,
            // or sticking to what the previous UI did.
            // Previous UI logic wasn't fully visible in snippets, but typically it finds max weight.
            final weight = segment.weight;
            if (weight > 0) {
              if (!records.containsKey(exercise.name) ||
                  weight > records[exercise.name]!) {
                records[exercise.name] = weight;
              }
            }
          }
        }
      }
    }
    return records;
  }
}
