import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

part 'workout_session.g.dart';

@HiveType(typeId: 3)
class SetSegment extends Equatable {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final double weight;
  @HiveField(2)
  final int repsFrom;
  @HiveField(3)
  final int repsTo;
  @HiveField(4)
  final int segmentOrder;
  @HiveField(5)
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

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'weight': weight,
      'repsFrom': repsFrom,
      'repsTo': repsTo,
      'segmentOrder': segmentOrder,
      'notes': notes,
    };
  }

  factory SetSegment.fromMap(Map<String, dynamic> map) {
    return SetSegment(
      id: map['id'] as String,
      weight: (map['weight'] as num).toDouble(),
      repsFrom: map['repsFrom'] as int,
      repsTo: map['repsTo'] as int,
      segmentOrder: map['segmentOrder'] as int,
      notes: map['notes'] as String? ?? '',
    );
  }
}

@HiveType(typeId: 2)
class ExerciseSet extends Equatable {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final List<SetSegment> segments;
  @HiveField(2)
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

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'setNumber': setNumber,
      'segments': segments.map((seg) => seg.toMap()).toList(),
    };
  }

  factory ExerciseSet.fromMap(Map<String, dynamic> map) {
    return ExerciseSet(
      id: map['id'] as String,
      setNumber: map['setNumber'] as int,
      segments: (map['segments'] as List<dynamic>?)
              ?.map((seg) => SetSegment.fromMap(seg as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

@HiveType(typeId: 1)
class SessionExercise extends Equatable {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String name;
  @HiveField(2)
  final int order;
  @HiveField(3, defaultValue: false)
  final bool skipped;
  @HiveField(4, defaultValue: false)
  final bool isTemplate;
  @HiveField(5)
  final List<ExerciseSet> sets;
  @HiveField(6, defaultValue: '')
  final String notes;
  @HiveField(7, defaultValue: '')
  final String variation;

  const SessionExercise({
    required this.id,
    required this.name,
    required this.order,
    this.skipped = false,
    this.isTemplate = false,
    required this.sets,
    this.notes = '',
    this.variation = '',
  });

  @override
  List<Object?> get props =>
      [id, name, order, skipped, isTemplate, sets, notes, variation];

  /// Calculates total volume for this exercise.
  /// If name or variation contains 'single' (case-insensitive), assumes unilateral exercise
  /// and doubles the volume (left + right).
  double get totalVolume {
    double vol = 0;
    for (final set in sets) {
      for (final segment in set.segments) {
        vol += segment.volume;
      }
    }

    // Check both name and variation for unilateral indicators.
    // Variation field is more reliable (e.g., "Single Arm", "Right Leg")
    final nameLower = name.toLowerCase();
    final variationLower = variation.toLowerCase();
    
    if (nameLower.contains('single') || 
        nameLower.contains('unilateral') ||
        variationLower.contains('single') ||
        variationLower.contains('unilateral')) {
      vol *= 2;
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
    String? notes,
    String? variation,
  }) {
    return SessionExercise(
      id: id ?? this.id,
      name: name ?? this.name,
      order: order ?? this.order,
      skipped: skipped ?? this.skipped,
      isTemplate: isTemplate ?? this.isTemplate,
      sets: sets ?? this.sets,
      notes: notes ?? this.notes,
      variation: variation ?? this.variation,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'order': order,
      'skipped': skipped,
      'isTemplate': isTemplate,
      'sets': sets.map((set) => set.toMap()).toList(),
      'notes': notes,
      'variation': variation,
    };
  }

  factory SessionExercise.fromMap(Map<String, dynamic> map) {
    return SessionExercise(
      id: map['id'] as String,
      name: map['name'] as String,
      order: map['order'] as int,
      skipped: map['skipped'] as bool? ?? false,
      isTemplate: map['isTemplate'] as bool? ?? false,
      sets: (map['sets'] as List<dynamic>?)
              ?.map((set) => ExerciseSet.fromMap(set as Map<String, dynamic>))
              .toList() ??
          [],
      notes: map['notes'] as String? ?? '',
      variation: map['variation'] as String? ?? '',
    );
  }
}

@HiveType(typeId: 0)
class WorkoutSession extends Equatable {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String userId;
  @HiveField(2)
  final String? planId;
  @HiveField(3)
  final String? planName;
  @HiveField(4)
  final DateTime workoutDate;
  @HiveField(5)
  final DateTime? startedAt;
  @HiveField(6)
  final DateTime? endedAt;
  @HiveField(7)
  final List<SessionExercise> exercises;
  @HiveField(8)
  final DateTime createdAt;
  @HiveField(9)
  final DateTime updatedAt;
  @HiveField(10, defaultValue: false)
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

  /// Returns the effective date for this workout.
  /// Prioritizes startedAt (when workout actually began) over workoutDate (manual selection).
  /// This handles workouts that cross midnight correctly.
  DateTime get effectiveDate => startedAt ?? workoutDate;

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

  // Sentinel to distinguish "not provided" from "explicitly null" in copyWith.
  static const Object _absent = Object();

  WorkoutSession copyWith({
    String? id,
    String? userId,
    Object? planId = _absent,
    Object? planName = _absent,
    DateTime? workoutDate,
    Object? startedAt = _absent,
    Object? endedAt = _absent,
    List<SessionExercise>? exercises,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isDraft,
  }) {
    return WorkoutSession(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      planId: identical(planId, _absent) ? this.planId : planId as String?,
      planName: identical(planName, _absent) ? this.planName : planName as String?,
      workoutDate: workoutDate ?? this.workoutDate,
      startedAt: identical(startedAt, _absent) ? this.startedAt : startedAt as DateTime?,
      endedAt: identical(endedAt, _absent) ? this.endedAt : endedAt as DateTime?,
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
      'exercises': exercises.map((ex) => ex.toMap()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isDraft': isDraft,
    };
  }

  static WorkoutSession fromMap(Map<String, dynamic> map) {
    return WorkoutSession(
      id: map['id'] as String,
      userId: map['userId'] as String,
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
      exercises: (map['exercises'] as List<dynamic>?)
              ?.map((ex) => SessionExercise.fromMap(ex as Map<String, dynamic>))
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
}
