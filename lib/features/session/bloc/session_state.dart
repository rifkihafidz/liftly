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
  final Map<String, SessionExercise> previousSessions;
  final Map<String, SetSegment> exercisePRs;

  const SessionInProgress({
    required this.session,
    this.previousSessions = const {},
    this.exercisePRs = const {},
  });

  @override
  List<Object?> get props => [session, previousSessions, exercisePRs];
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
