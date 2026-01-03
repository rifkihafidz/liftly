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
  List<Object?> get props => [
    id,
    weight,
    repsFrom,
    repsTo,
    segmentOrder,
    notes,
  ];

  SetSegment copyWith({
    String? id,
    double? weight,
    int? repsFrom,
    int? repsTo,
    int? segmentOrder,
    String? notes,
  }) {
    return SetSegment(
      id: id ?? this.id,
      weight: weight ?? this.weight,
      repsFrom: repsFrom ?? this.repsFrom,
      repsTo: repsTo ?? this.repsTo,
      segmentOrder: segmentOrder ?? this.segmentOrder,
      notes: notes ?? this.notes,
    );
  }
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

  ExerciseSet copyWith({
    String? id,
    List<SetSegment>? segments,
    int? setNumber,
  }) {
    return ExerciseSet(
      id: id ?? this.id,
      segments: segments ?? this.segments,
      setNumber: setNumber ?? this.setNumber,
    );
  }
}

class SessionExercise extends Equatable {
  final String id;
  final String name;
  final int order;
  final bool skipped;
  final bool isTemplate;
  final List<ExerciseSet> sets;

  const SessionExercise({
    required this.id,
    required this.name,
    required this.order,
    this.skipped = false,
    this.isTemplate = false,
    required this.sets,
  });

  @override
  List<Object?> get props => [id, name, order, skipped, isTemplate, sets];

  /// Calculates total volume for this exercise.
  /// If name contains 'single' (case-insensitive), assumes unilateral exercise
  /// and doubles the volume (left + right).
  double get totalVolume {
    double vol = 0;
    for (final set in sets) {
      for (final segment in set.segments) {
        vol += segment.volume;
      }
    }

    return vol;
  }

  SessionExercise copyWith({
    String? id,
    String? name,
    int? order,
    bool? skipped,
    bool? isTemplate,
    List<ExerciseSet>? sets,
  }) {
    return SessionExercise(
      id: id ?? this.id,
      name: name ?? this.name,
      order: order ?? this.order,
      skipped: skipped ?? this.skipped,
      isTemplate: isTemplate ?? this.isTemplate,
      sets: sets ?? this.sets,
    );
  }
}

class WorkoutSession extends Equatable {
  final String id;
  final String userId;
  final String? planId;
  final String? planName;
  final DateTime workoutDate;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final List<SessionExercise> exercises;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDraft;

  const WorkoutSession({
    required this.id,
    required this.userId,
    this.planId,
    this.planName,
    required this.workoutDate,
    this.startedAt,
    this.endedAt,
    required this.exercises,
    required this.createdAt,
    required this.updatedAt,
    this.isDraft = false,
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

  /// Total workout volume
  double get totalVolume {
    double vol = 0;
    for (final exercise in exercises) {
      if (!exercise.skipped) {
        vol += exercise.totalVolume;
      }
    }
    return vol;
  }

  WorkoutSession copyWith({
    String? id,
    String? userId,
    String? planId,
    String? planName,
    DateTime? workoutDate,
    DateTime? startedAt,
    DateTime? endedAt,
    List<SessionExercise>? exercises,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isDraft,
  }) {
    return WorkoutSession(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      planId: planId ?? this.planId,
      planName: planName ?? this.planName,
      workoutDate: workoutDate ?? this.workoutDate,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      exercises: exercises ?? this.exercises,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDraft: isDraft ?? this.isDraft,
    );
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    planId,
    planName,
    workoutDate,
    startedAt,
    endedAt,
    exercises,
    createdAt,
    updatedAt,
    isDraft,
  ];

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'planId': planId,
      'planName': planName,
      'workoutDate': workoutDate.toIso8601String(),
      'startedAt': startedAt?.toIso8601String(),
      'endedAt': endedAt?.toIso8601String(),
      'exercises': exercises.map((ex) => _sessionExerciseToMap(ex)).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isDraft': isDraft,
    };
  }

  static WorkoutSession fromMap(Map<String, dynamic> map) {
    return WorkoutSession(
      id: _parseId(map['id']),
      userId: _parseId(map['userId']),
      planId: map['planId'] != null ? _parseId(map['planId']) : null,
      planName: map['planName'] as String?,
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
      exercises:
          (map['exercises'] as List<dynamic>?)
              ?.map((ex) => _sessionExerciseFromMap(ex as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: map['createdAt'] is String
          ? DateTime.parse(map['createdAt'] as String)
          : map['createdAt'] as DateTime,
      updatedAt: map['updatedAt'] is String
          ? DateTime.parse(map['updatedAt'] as String)
          : map['updatedAt'] as DateTime,
      isDraft: map['isDraft'] is int
          ? (map['isDraft'] as int) == 1
          : (map['isDraft'] as bool? ?? false),
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
      'isTemplate': exercise.isTemplate,
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
      isTemplate: map['isTemplate'] as bool? ?? false,
      sets:
          (map['sets'] as List<dynamic>?)
              ?.map((set) => _exerciseSetFromMap(set as Map<String, dynamic>))
              .toList() ??
          [],
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
      segments:
          (map['segments'] as List<dynamic>?)
              ?.map((seg) => _setSegmentFromMap(seg as Map<String, dynamic>))
              .toList() ??
          [],
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
