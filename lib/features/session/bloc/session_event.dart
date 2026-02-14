import 'package:equatable/equatable.dart';
import '../../../core/models/workout_session.dart';

abstract class SessionEvent extends Equatable {
  const SessionEvent();

  @override
  List<Object?> get props => [];
}

class SessionStarted extends SessionEvent {
  final String? planId;
  final String? planName;
  final List<String> exerciseNames;
  final String userId;

  const SessionStarted({
    this.planId,
    this.planName,
    required this.exerciseNames,
    required this.userId,
  });

  @override
  List<Object?> get props => [planId, planName, exerciseNames, userId];
}

class SessionCheckDraftRequested extends SessionEvent {
  final String userId;
  const SessionCheckDraftRequested({required this.userId});

  @override
  List<Object?> get props => [userId];
}

class SessionExerciseAdded extends SessionEvent {
  final String exerciseName;

  const SessionExerciseAdded({required this.exerciseName});

  @override
  List<Object?> get props => [exerciseName];
}

class SessionExerciseSkipToggled extends SessionEvent {
  final int exerciseIndex;

  const SessionExerciseSkipToggled({required this.exerciseIndex});

  @override
  List<Object?> get props => [exerciseIndex];
}

class SessionSetAdded extends SessionEvent {
  final int exerciseIndex;

  // Optional initial values
  final double? weight;
  final int? repsFrom;
  final int? repsTo;
  final String? notes;

  const SessionSetAdded({
    required this.exerciseIndex,
    this.weight,
    this.repsFrom,
    this.repsTo,
    this.notes,
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

  const SessionSegmentAdded({
    required this.exerciseIndex,
    required this.setIndex,
  });

  @override
  List<Object?> get props => [exerciseIndex, setIndex];
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

class SessionSegmentUpdated extends SessionEvent {
  final int exerciseIndex;
  final int setIndex;
  final int segmentIndex;
  final String field; // 'weight', 'repsFrom', 'repsTo', 'notes'
  final dynamic value;

  const SessionSegmentUpdated({
    required this.exerciseIndex,
    required this.setIndex,
    required this.segmentIndex,
    required this.field,
    required this.value,
  });

  @override
  List<Object?> get props => [
        exerciseIndex,
        setIndex,
        segmentIndex,
        field,
        value,
      ];
}

class SessionDateTimesUpdated extends SessionEvent {
  final DateTime? workoutDate;
  final DateTime? startedAt;
  final DateTime? endedAt;

  const SessionDateTimesUpdated({
    this.workoutDate,
    this.startedAt,
    this.endedAt,
  });

  @override
  List<Object?> get props => [workoutDate, startedAt, endedAt];
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

class SessionExerciseRemoved extends SessionEvent {
  final int exerciseIndex;

  const SessionExerciseRemoved({required this.exerciseIndex});

  @override
  List<Object?> get props => [exerciseIndex];
}

class SessionExerciseNameUpdated extends SessionEvent {
  final int exerciseIndex;
  final String newName;

  const SessionExerciseNameUpdated({
    required this.exerciseIndex,
    required this.newName,
  });

  @override
  List<Object?> get props => [exerciseIndex, newName];
}

class SessionDiscarded extends SessionEvent {
  const SessionDiscarded();
}

class SessionExercisesReordered extends SessionEvent {
  final int oldIndex;
  final int newIndex;

  const SessionExercisesReordered({
    required this.oldIndex,
    required this.newIndex,
  });

  @override
  List<Object?> get props => [oldIndex, newIndex];
}

class SessionFocusCleared extends SessionEvent {
  const SessionFocusCleared();
}
