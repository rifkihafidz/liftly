import 'package:equatable/equatable.dart';
import '../../../core/models/workout_session.dart';
import '../../stats/bloc/stats_state.dart';

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

class SessionDraftCheckSuccess extends SessionState {
  final WorkoutSession? draft;
  final int timestamp; // Force unique state

  SessionDraftCheckSuccess({this.draft})
    : timestamp = DateTime.now().millisecondsSinceEpoch;

  @override
  List<Object?> get props => [draft, timestamp];
}

class SessionInProgress extends SessionState {
  final WorkoutSession session;
  final Map<String, SessionExercise> previousSessions;
  final Map<String, PersonalRecord> exercisePRs;
  final int? focusedExerciseIndex;
  final int? focusedSetIndex;
  final int? focusedSegmentIndex;
  final int timestamp; // Force unique state for focus resets

  const SessionInProgress({
    required this.session,
    this.previousSessions = const {},
    this.exercisePRs = const {},
    this.focusedExerciseIndex,
    this.focusedSetIndex,
    this.focusedSegmentIndex,
  }) : timestamp = 0;

  const SessionInProgress.withFocus({
    required this.session,
    this.previousSessions = const {},
    this.exercisePRs = const {},
    this.focusedExerciseIndex,
    this.focusedSetIndex,
    this.focusedSegmentIndex,
    required this.timestamp,
  });

  @override
  List<Object?> get props => [
    session,
    previousSessions,
    exercisePRs,
    focusedExerciseIndex,
    focusedSetIndex,
    focusedSegmentIndex,
    timestamp,
  ];
}

class SessionSaved extends SessionState {
  final WorkoutSession session;

  const SessionSaved({required this.session});

  @override
  List<Object?> get props => [session];
}

class SessionDraftSaved extends SessionState {
  final WorkoutSession session;

  const SessionDraftSaved({required this.session});

  @override
  List<Object?> get props => [session];
}

class SessionError extends SessionState {
  final String message;

  const SessionError({required this.message});

  @override
  List<Object?> get props => [message];
}
