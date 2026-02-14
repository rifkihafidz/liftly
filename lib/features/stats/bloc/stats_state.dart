import 'package:equatable/equatable.dart';
import '../../../core/models/workout_session.dart';
import '../../../core/models/stats_filter.dart';
import '../../../core/models/personal_record.dart';

abstract class StatsState extends Equatable {
  const StatsState();

  @override
  List<Object?> get props => [];
}

class StatsInitial extends StatsState {}

class StatsLoading extends StatsState {}

enum PrSortOrder {
  az,
  za,
}

class StatsLoaded extends StatsState {
  final List<WorkoutSession> allSessions; // Cache for everything
  final List<WorkoutSession> filteredSessions; // For current view
  final TimePeriod timePeriod;
  final DateTime referenceDate;
  final Map<String, PersonalRecord> personalRecords;
  final Set<String>? prFilter; // Null means all
  final PrSortOrder sortOrder;

  const StatsLoaded({
    required this.allSessions,
    required this.filteredSessions,
    required this.timePeriod,
    required this.referenceDate,
    required this.personalRecords,
    this.prFilter,
    this.sortOrder = PrSortOrder.az,
  });

  StatsLoaded copyWith({
    List<WorkoutSession>? allSessions,
    List<WorkoutSession>? filteredSessions,
    TimePeriod? timePeriod,
    DateTime? referenceDate,
    Map<String, PersonalRecord>? personalRecords,
    Set<String>? prFilter,
    PrSortOrder? sortOrder,
  }) {
    return StatsLoaded(
      allSessions: allSessions ?? this.allSessions,
      filteredSessions: filteredSessions ?? this.filteredSessions,
      timePeriod: timePeriod ?? this.timePeriod,
      referenceDate: referenceDate ?? this.referenceDate,
      personalRecords: personalRecords ?? this.personalRecords,
      prFilter: prFilter ?? this.prFilter,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  List<Object?> get props => [
        allSessions,
        filteredSessions,
        timePeriod,
        referenceDate,
        personalRecords,
        prFilter,
        sortOrder,
      ];
}

class StatsError extends StatsState {
  final String message;

  const StatsError({required this.message});

  @override
  List<Object> get props => [message];
}
