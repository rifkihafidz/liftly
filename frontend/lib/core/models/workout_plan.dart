import 'package:equatable/equatable.dart';

class PlanExercise extends Equatable {
  final String id;
  final String name;
  final int order;

  const PlanExercise({
    required this.id,
    required this.name,
    required this.order,
  });

  @override
  List<Object?> get props => [id, name, order];
}

class WorkoutPlan extends Equatable {
  final String id;
  final String userId;
  final String name;
  final String? description;
  final List<PlanExercise> exercises;
  final DateTime createdAt;
  final DateTime updatedAt;

  const WorkoutPlan({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
    required this.exercises,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
    id,
    userId,
    name,
    description,
    exercises,
    createdAt,
    updatedAt,
  ];
}
