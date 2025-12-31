part of '../api_service.dart';

class WorkoutResponse {
  final String id;
  final String userId;
  final String? planId;
  final DateTime workoutDate;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final List<ExerciseResponse> exercises;
  final DateTime createdAt;
  final DateTime updatedAt;

  WorkoutResponse({
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

  factory WorkoutResponse.fromJson(Map<String, dynamic> json) {
    final exercisesData = json['exercises'] as List? ?? [];
    
    return WorkoutResponse(
      id: (json['id'] ?? '').toString(),
      userId: (json['userId'] ?? '').toString(),
      planId: json['planId'] != null ? (json['planId'] ?? '').toString() : null,
      workoutDate: DateTime.parse(json['workoutDate'] as String? ?? DateTime.now().toIso8601String()),
      startedAt: json['startedAt'] != null ? DateTime.parse(json['startedAt'] as String) : null,
      endedAt: json['endedAt'] != null ? DateTime.parse(json['endedAt'] as String) : null,
      exercises: exercisesData
          .map((e) => ExerciseResponse.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String? ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] as String? ?? DateTime.now().toIso8601String()),
    );
  }
}

class ExerciseResponse {
  final String id;
  final String name;
  final int order;
  final bool skipped;
  final List<SetResponse> sets;

  ExerciseResponse({
    required this.id,
    required this.name,
    required this.order,
    required this.skipped,
    required this.sets,
  });

  factory ExerciseResponse.fromJson(Map<String, dynamic> json) {
    final setsData = json['sets'] as List? ?? [];
    
    return ExerciseResponse(
      id: (json['id'] ?? '').toString(),
      name: json['name'] as String? ?? '',
      order: json['order'] as int? ?? 0,
      skipped: json['skipped'] as bool? ?? false,
      sets: setsData
          .map((e) => SetResponse.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class SetResponse {
  final String id;
  final int setNumber;
  final List<SegmentResponse> segments;

  SetResponse({
    required this.id,
    required this.setNumber,
    required this.segments,
  });

  factory SetResponse.fromJson(Map<String, dynamic> json) {
    final segmentsData = json['segments'] as List? ?? [];
    
    return SetResponse(
      id: (json['id'] ?? '').toString(),
      setNumber: json['setNumber'] as int? ?? 0,
      segments: segmentsData
          .map((e) => SegmentResponse.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class SegmentResponse {
  final String id;
  final double weight;
  final int repsFrom;
  final int repsTo;
  final int segmentOrder;
  final String notes;

  SegmentResponse({
    required this.id,
    required this.weight,
    required this.repsFrom,
    required this.repsTo,
    required this.segmentOrder,
    required this.notes,
  });

  factory SegmentResponse.fromJson(Map<String, dynamic> json) {
    return SegmentResponse(
      id: (json['id'] ?? '').toString(),
      weight: (json['weight'] as num?)?.toDouble() ?? 0.0,
      repsFrom: json['repsFrom'] as int? ?? 0,
      repsTo: json['repsTo'] as int? ?? 0,
      segmentOrder: json['segmentOrder'] as int? ?? 0,
      notes: json['notes'] as String? ?? '',
    );
  }
}

class ExerciseLogResponse {
  final String id;
  final String exerciseId;
  final String exerciseName;
  final List<SetLogResponse> setLogs;

  ExerciseLogResponse({
    required this.id,
    required this.exerciseId,
    required this.exerciseName,
    required this.setLogs,
  });

  factory ExerciseLogResponse.fromJson(Map<String, dynamic> json) {
    final setsData = json['setLogs'] as List? ?? [];
    
    return ExerciseLogResponse(
      id: (json['id'] ?? '').toString(),
      exerciseId: (json['exerciseId'] ?? '').toString(),
      exerciseName: json['exerciseName'] as String? ?? '',
      setLogs: setsData
          .map((e) => SetLogResponse.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class SetLogResponse {
  final String id;
  final int reps;
  final double weight;
  final String unit;

  SetLogResponse({
    required this.id,
    required this.reps,
    required this.weight,
    required this.unit,
  });

  factory SetLogResponse.fromJson(Map<String, dynamic> json) {
    return SetLogResponse(
      id: (json['id'] ?? '').toString(),
      reps: json['reps'] as int? ?? 0,
      weight: (json['weight'] as num?)?.toDouble() ?? 0.0,
      unit: json['unit'] as String? ?? 'kg',
    );
  }
}
