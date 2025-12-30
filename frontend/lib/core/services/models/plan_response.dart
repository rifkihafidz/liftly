part of '../api_service.dart';

class PlanResponse {
  final String id;
  final String userId;
  final String name;
  final String? description;
  final List<PlanExerciseResponse> exercises;
  final DateTime createdAt;
  final DateTime updatedAt;

  PlanResponse({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
    required this.exercises,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PlanResponse.fromJson(Map<String, dynamic> json) {
    final exercisesData = json['exercises'] as List? ?? [];
    return PlanResponse(
      id: (json['id'] ?? '').toString(),
      userId: (json['userId'] ?? '').toString(),
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      exercises: exercisesData
          .map((e) => PlanExerciseResponse.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

class PlanExerciseResponse {
  final String id;
  final String name;
  final int order;

  PlanExerciseResponse({
    required this.id,
    required this.name,
    required this.order,
  });

  factory PlanExerciseResponse.fromJson(Map<String, dynamic> json) {
    return PlanExerciseResponse(
      id: (json['id'] ?? '').toString(),
      name: json['name'] as String? ?? '',
      order: json['order'] as int? ?? 0,
    );
  }
}
