import 'package:equatable/equatable.dart';
import '../../../core/models/workout_session.dart';

abstract class SessionEvent extends Equatable {
  const SessionEvent();

  @override
  List<Object?> get props => [];
}

class SessionStarted extends SessionEvent {
  final String? planId;
  final List<String> exerciseNames;
  final String userId;

  const SessionStarted({
    this.planId,
    required this.exerciseNames,
    required this.userId,
  });

  @override
  List<Object?> get props => [planId, exerciseNames, userId];
}

class SessionExerciseSkipped extends SessionEvent {
  final int exerciseIndex;

  const SessionExerciseSkipped({required this.exerciseIndex});

  @override
  List<Object?> get props => [exerciseIndex];
}

class SessionExerciseUnskipped extends SessionEvent {
  final int exerciseIndex;

  const SessionExerciseUnskipped({required this.exerciseIndex});

  @override
  List<Object?> get props => [exerciseIndex];
}

class SessionSetAdded extends SessionEvent {
  final int exerciseIndex;
  final double weight;
  final int repsFrom;
  final int repsTo;
  final String notes;

  const SessionSetAdded({
    required this.exerciseIndex,
    required this.weight,
    required this.repsFrom,
    required this.repsTo,
    this.notes = '',
  });

  @override
  List<Object?> get props => [exerciseIndex, weight, repsFrom, repsTo, notes];
}

class SessionSetRemoved extends SessionEvent {
  final int exerciseIndex;
  final int setIndex;

  const SessionSetRemoved({
    required this.exerciseIndex,
    required this.setIndex,
  });

  @override
  List<Object?> get props => [exerciseIndex, setIndex];
}

class SessionSegmentAdded extends SessionEvent {
  final int exerciseIndex;
  final int setIndex;
  final double weight;
  final int repsFrom;
  final int repsTo;

  const SessionSegmentAdded({
    required this.exerciseIndex,
    required this.setIndex,
    required this.weight,
    required this.repsFrom,
    required this.repsTo,
  });

  @override
  List<Object?> get props => [
    exerciseIndex,
    setIndex,
    weight,
    repsFrom,
    repsTo,
  ];
}

class SessionSegmentRemoved extends SessionEvent {
  final int exerciseIndex;
  final int setIndex;
  final int segmentIndex;

  const SessionSegmentRemoved({
    required this.exerciseIndex,
    required this.setIndex,
    required this.segmentIndex,
  });

  @override
  List<Object?> get props => [exerciseIndex, setIndex, segmentIndex];
}

class SessionEnded extends SessionEvent {
  const SessionEnded();
}

class SessionLoaded extends SessionEvent {
  final WorkoutSession session;

  const SessionLoaded({required this.session});

  @override
  List<Object?> get props => [session];
}

class SessionRecovered extends SessionEvent {
  final WorkoutSession session;

  const SessionRecovered({required this.session});

  @override
  List<Object?> get props => [session];
}

class SessionSaveRequested extends SessionEvent {
  const SessionSaveRequested();
}

class SessionDraftResumed extends SessionEvent {
  final WorkoutSession draftSession;

  const SessionDraftResumed({required this.draftSession});

  @override
  List<Object?> get props => [draftSession];
}

class SessionSaveDraftRequested extends SessionEvent {
  const SessionSaveDraftRequested();
}
