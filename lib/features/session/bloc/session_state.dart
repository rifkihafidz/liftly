import 'package:equatable/equatable.dart';
import '../../../core/models/workout_session.dart';

abstract class SessionState extends Equatable {
  const SessionState();

  @override
  List<Object?> get props => [];
}

class SessionInitial extends SessionState {
  const SessionInitial();
}

class SessionLoading extends SessionState {
  const SessionLoading();
}

class SessionInProgress extends SessionState {
  final WorkoutSession session;

  const SessionInProgress({required this.session});

  @override
  List<Object?> get props => [session];
}

class SessionSaved extends SessionState {
  final WorkoutSession session;

  const SessionSaved({required this.session});

  @override
  List<Object?> get props => [session];
}

class SessionError extends SessionState {
  final String message;

  const SessionError({required this.message});

  @override
  List<Object?> get props => [message];
}
