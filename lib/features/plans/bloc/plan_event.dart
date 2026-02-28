import 'package:equatable/equatable.dart';

abstract class PlanEvent extends Equatable {
  const PlanEvent();

  @override
  List<Object?> get props => [];
}

class PlansFetchRequested extends PlanEvent {
  final String userId;

  const PlansFetchRequested({required this.userId});

  @override
  List<Object?> get props => [userId];
}

class PlanCreated extends PlanEvent {
  final String userId;
  final String name;
  final String? description;
  final List<String> exercises;
  final List<String>? exerciseVariations;

  const PlanCreated({
    required this.userId,
    required this.name,
    this.description,
    required this.exercises,
    this.exerciseVariations,
  });

  @override
  List<Object?> get props =>
      [userId, name, description, exercises, exerciseVariations];
}

class PlanUpdated extends PlanEvent {
  final String userId;
  final String planId;
  final String name;
  final String? description;
  final List<String> exercises;
  final List<String>? exerciseVariations;

  const PlanUpdated({
    required this.userId,
    required this.planId,
    required this.name,
    this.description,
    required this.exercises,
    this.exerciseVariations,
  });

  @override
  List<Object?> get props => [
        userId,
        planId,
        name,
        description,
        exercises,
        exerciseVariations
      ];
}

class PlanDeleted extends PlanEvent {
  final String userId;
  final String planId;

  const PlanDeleted({
    required this.userId,
    required this.planId,
  });

  @override
  List<Object?> get props => [userId, planId];
}
