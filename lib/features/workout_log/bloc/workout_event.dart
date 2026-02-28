import 'package:equatable/equatable.dart';
import 'package:liftly/core/constants/app_constants.dart';

abstract class WorkoutEvent extends Equatable {
  const WorkoutEvent();

  @override
  List<Object?> get props => [];
}

class WorkoutSubmitted extends WorkoutEvent {
  final String userId;
  final Map<String, dynamic> workoutData;

  const WorkoutSubmitted({required this.userId, required this.workoutData});

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

  const WorkoutDeleted({required this.userId, required this.workoutId});

  @override
  List<Object?> get props => [userId, workoutId];
}

class WorkoutsFetched extends WorkoutEvent {
  final String userId;
  final int limit;
  final int offset;

  const WorkoutsFetched({this.userId = AppConstants.defaultUserId, this.limit = 10, this.offset = 0});

  @override
  List<Object?> get props => [userId, limit, offset];
}
