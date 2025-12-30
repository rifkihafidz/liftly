import 'package:equatable/equatable.dart';
import '../../../core/models/workout_session.dart';

abstract class WorkoutState extends Equatable {
  const WorkoutState();

  @override
  List<Object?> get props => [];
}

class WorkoutInitial extends WorkoutState {
  const WorkoutInitial();
}

class WorkoutLoading extends WorkoutState {
  const WorkoutLoading();
}

class WorkoutSuccess extends WorkoutState {
  final String message;
  final Map<String, dynamic>? data;

  const WorkoutSuccess({
    required this.message,
    this.data,
  });

  @override
  List<Object?> get props => [message, data];
}

class WorkoutUpdatedSuccess extends WorkoutState {
  final String message;
  final Map<String, dynamic>? data;

  const WorkoutUpdatedSuccess({
    required this.message,
    this.data,
  });

  @override
  List<Object?> get props => [message, data];
}

class WorkoutError extends WorkoutState {
  final String message;

  const WorkoutError({required this.message});

  @override
  List<Object?> get props => [message];
}

class WorkoutsLoaded extends WorkoutState {
  final List<WorkoutSession> workouts;

  const WorkoutsLoaded({required this.workouts});

  @override
  List<Object?> get props => [workouts];
}
