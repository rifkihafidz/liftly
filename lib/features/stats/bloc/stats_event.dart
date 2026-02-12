import 'package:equatable/equatable.dart';

import '../../../core/models/stats_filter.dart';
import 'stats_state.dart';

abstract class StatsEvent extends Equatable {
  const StatsEvent();

  @override
  List<Object?> get props => [];
}

class StatsFetched extends StatsEvent {
  final String userId;

  const StatsFetched({required this.userId});

  @override
  List<Object?> get props => [userId];
}

class StatsPeriodChanged extends StatsEvent {
  final TimePeriod timePeriod;

  const StatsPeriodChanged({required this.timePeriod});

  @override
  List<Object> get props => [timePeriod];
}

class StatsDateChanged extends StatsEvent {
  final DateTime date;

  const StatsDateChanged({required this.date});

  @override
  List<Object> get props => [date];
}

class StatsPRFiltered extends StatsEvent {
  final Set<String> selectedExercises;

  const StatsPRFiltered({required this.selectedExercises});

  @override
  List<Object> get props => [selectedExercises];
}

class StatsPRSortChanged extends StatsEvent {
  final PrSortOrder sortOrder;

  const StatsPRSortChanged({required this.sortOrder});

  @override
  List<Object> get props => [sortOrder];
}
