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

  String get formattedDuration {
    final dur = duration;
    if (dur == null) return '-';
    
    final hours = dur.inHours;
    final minutes = dur.inMinutes % 60;
    
    if (hours == 0) {
      return '${minutes}m';
    } else if (minutes == 0) {
      return '${hours}h';
    } else {
      return '${hours}h ${minutes}m';
    }
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

  /// Convert to Map for Hive storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'planId': planId,
      'workoutDate': workoutDate.toIso8601String(),
      'startedAt': startedAt?.toIso8601String(),
      'endedAt': endedAt?.toIso8601String(),
      'exercises': exercises.map((ex) => _sessionExerciseToMap(ex)).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Create from Map (from Hive storage or API response)
  static WorkoutSession fromMap(Map<String, dynamic> map) {
    return WorkoutSession(
      id: _parseId(map['id']),
      userId: _parseId(map['userId']),
      planId: map['planId'] != null ? _parseId(map['planId']) : null,
      workoutDate: map['workoutDate'] is String 
          ? DateTime.parse(map['workoutDate'] as String)
          : map['workoutDate'] as DateTime,
      startedAt: map['startedAt'] != null 
          ? (map['startedAt'] is String 
              ? DateTime.parse(map['startedAt'] as String)
              : map['startedAt'] as DateTime)
          : null,
      endedAt: map['endedAt'] != null 
          ? (map['endedAt'] is String 
              ? DateTime.parse(map['endedAt'] as String)
              : map['endedAt'] as DateTime)
          : null,
      exercises: (map['exercises'] as List<dynamic>?)
          ?.map((ex) => _sessionExerciseFromMap(ex as Map<String, dynamic>))
          .toList() ?? [],
      createdAt: map['createdAt'] is String 
          ? DateTime.parse(map['createdAt'] as String)
          : map['createdAt'] as DateTime,
      updatedAt: map['updatedAt'] is String 
          ? DateTime.parse(map['updatedAt'] as String)
          : map['updatedAt'] as DateTime,
    );
  }

  /// Parse ID - handles both String and int (from JSON)
  static String _parseId(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    if (value is int) return value.toString();
    return value.toString();
  }

  /// Helper: SessionExercise to Map
  static Map<String, dynamic> _sessionExerciseToMap(SessionExercise exercise) {
    return {
      'id': exercise.id,
      'name': exercise.name,
      'order': exercise.order,
      'skipped': exercise.skipped,
      'sets': exercise.sets.map((set) => _exerciseSetToMap(set)).toList(),
    };
  }

  /// Helper: SessionExercise from Map
  static SessionExercise _sessionExerciseFromMap(Map<String, dynamic> map) {
    return SessionExercise(
      id: _parseId(map['id']),
      name: map['name'] as String,
      order: map['order'] as int,
      skipped: map['skipped'] as bool? ?? false,
      sets: (map['sets'] as List<dynamic>?)
          ?.map((set) => _exerciseSetFromMap(set as Map<String, dynamic>))
          .toList() ?? [],
    );
  }

  /// Helper: ExerciseSet to Map
  static Map<String, dynamic> _exerciseSetToMap(ExerciseSet set) {
    return {
      'id': set.id,
      'setNumber': set.setNumber,
      'segments': set.segments.map((seg) => _setSegmentToMap(seg)).toList(),
    };
  }

  /// Helper: ExerciseSet from Map
  static ExerciseSet _exerciseSetFromMap(Map<String, dynamic> map) {
    return ExerciseSet(
      id: _parseId(map['id']),
      setNumber: map['setNumber'] as int,
      segments: (map['segments'] as List<dynamic>?)
          ?.map((seg) => _setSegmentFromMap(seg as Map<String, dynamic>))
          .toList() ?? [],
    );
  }

  /// Helper: SetSegment to Map
  static Map<String, dynamic> _setSegmentToMap(SetSegment segment) {
    return {
      'id': segment.id,
      'weight': segment.weight,
      'repsFrom': segment.repsFrom,
      'repsTo': segment.repsTo,
      'segmentOrder': segment.segmentOrder,
      'notes': segment.notes,
    };
  }

  /// Helper: SetSegment from Map
  static SetSegment _setSegmentFromMap(Map<String, dynamic> map) {
    return SetSegment(
      id: _parseId(map['id']),
      weight: (map['weight'] as num).toDouble(),
      repsFrom: map['repsFrom'] as int,
      repsTo: map['repsTo'] as int,
      segmentOrder: map['segmentOrder'] as int,
      notes: map['notes'] as String? ?? '',
    );
  }
}
