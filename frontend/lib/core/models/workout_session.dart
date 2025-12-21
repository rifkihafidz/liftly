import 'package:equatable/equatable.dart';

class SetSegment extends Equatable {
  final String id;
  final double weight;
  final int repsFrom;
  final int repsTo;
  final int segmentOrder;
  final String notes;

  const SetSegment({
    required this.id,
    required this.weight,
    required this.repsFrom,
    required this.repsTo,
    required this.segmentOrder,
    this.notes = '',
  });

  int get totalReps => repsTo - repsFrom + 1;

  double get volume => weight * totalReps;

  @override
  List<Object?> get props => [id, weight, repsFrom, repsTo, segmentOrder, notes];
}

class ExerciseSet extends Equatable {
  final String id;
  final List<SetSegment> segments;
  final int setNumber;

  const ExerciseSet({
    required this.id,
    required this.segments,
    required this.setNumber,
  });

  bool get isDropset => segments.length > 1;

  @override
  List<Object?> get props => [id, segments, setNumber];
}

class SessionExercise extends Equatable {
  final String id;
  final String name;
  final int order;
  final bool skipped;
  final List<ExerciseSet> sets;

  const SessionExercise({
    required this.id,
    required this.name,
    required this.order,
    this.skipped = false,
    required this.sets,
  });

  @override
  List<Object?> get props => [id, name, order, skipped, sets];
}

class WorkoutSession extends Equatable {
  final String id;
  final String userId;
  final String? planId;
  final DateTime workoutDate;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final List<SessionExercise> exercises;
  final DateTime createdAt;
  final DateTime updatedAt;

  const WorkoutSession({
    required this.id,
    required this.userId,
    this.planId,
    required this.workoutDate,
    this.startedAt,
    this.endedAt,
    required this.exercises,
    required this.createdAt,
    required this.updatedAt,
  });

  Duration? get duration {
    if (startedAt == null || endedAt == null) return null;
    return endedAt!.difference(startedAt!);
  }

  WorkoutSession copyWith({
    String? id,
    String? userId,
    String? planId,
    DateTime? workoutDate,
    DateTime? startedAt,
    DateTime? endedAt,
    List<SessionExercise>? exercises,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WorkoutSession(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      planId: planId ?? this.planId,
      workoutDate: workoutDate ?? this.workoutDate,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      exercises: exercises ?? this.exercises,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    planId,
    workoutDate,
    startedAt,
    endedAt,
    exercises,
    createdAt,
    updatedAt,
  ];
}
