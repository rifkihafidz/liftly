import 'package:equatable/equatable.dart';

abstract class WorkoutEvent extends Equatable {
  const WorkoutEvent();

  @override
  List<Object?> get props => [];
}

class WorkoutSubmitted extends WorkoutEvent {
  final String userId;
  final Map<String, dynamic> workoutData;

  const WorkoutSubmitted({
    required this.userId,
    required this.workoutData,
  });

  @override
  List<Object?> get props => [userId, workoutData];
}

class WorkoutUpdated extends WorkoutEvent {
  final String userId;
  final String workoutId;
  final Map<String, dynamic> workoutData;

  const WorkoutUpdated({
    required this.userId,
    required this.workoutId,
    required this.workoutData,
  });

  @override
  List<Object?> get props => [userId, workoutId, workoutData];
}

class WorkoutDeleted extends WorkoutEvent {
  final String userId;
  final String workoutId;

  const WorkoutDeleted({
    required this.userId,
    required this.workoutId,
  });

  @override
  List<Object?> get props => [userId, workoutId];
}

class WorkoutsFetched extends WorkoutEvent {
  final String userId;

  const WorkoutsFetched({required this.userId});

  @override
  List<Object?> get props => [userId];
}
