import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

part 'workout_plan.g.dart';

@HiveType(typeId: 5)
class PlanExercise extends Equatable {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String name;
  @HiveField(2)
  final int order;
  @HiveField(3, defaultValue: '')
  final String variation;

  const PlanExercise({
    required this.id,
    required this.name,
    required this.order,
    this.variation = '',
  });

  @override
  List<Object?> get props => [id, name, order, variation];

  factory PlanExercise.fromMap(Map<String, dynamic> map) {
    return PlanExercise(
      id: map['id'] as String,
      name: map['name'] as String,
      order: map['order'] as int,
      variation: map['variation'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'order': order,
      'variation': variation,
    };
  }

  PlanExercise copyWith({
    String? id,
    String? name,
    int? order,
    String? variation,
  }) {
    return PlanExercise(
      id: id ?? this.id,
      name: name ?? this.name,
      order: order ?? this.order,
      variation: variation ?? this.variation,
    );
  }
}

@HiveType(typeId: 4)
class WorkoutPlan extends Equatable {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String userId;
  @HiveField(2)
  final String name;
  @HiveField(3)
  final String? description;
  @HiveField(4)
  final List<PlanExercise> exercises;
  @HiveField(5)
  final DateTime createdAt;
  @HiveField(6)
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

  factory WorkoutPlan.fromMap(Map<String, dynamic> map) {
    return WorkoutPlan(
      id: map['id'] as String,
      userId: map['userId'] as String,
      name: map['name'] as String,
      description: map['description'] as String?,
      exercises: (map['exercises'] as List<dynamic>)
          .map((e) => PlanExercise.fromMap(e as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'description': description,
      'exercises': exercises.map((e) => e.toMap()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  WorkoutPlan copyWith({
    String? id,
    String? userId,
    String? name,
    String? description,
    List<PlanExercise>? exercises,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WorkoutPlan(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      description: description ?? this.description,
      exercises: exercises ?? this.exercises,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
