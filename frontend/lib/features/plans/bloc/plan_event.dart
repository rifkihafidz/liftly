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

  const PlanCreated({
    required this.userId,
    required this.name,
    this.description,
    required this.exercises,
  });

  @override
  List<Object?> get props => [userId, name, description, exercises];
}

class PlanUpdated extends PlanEvent {
  final String userId;
  final String planId;
  final String name;
  final String? description;
  final List<String> exercises;

  const PlanUpdated({
    required this.userId,
    required this.planId,
    required this.name,
    this.description,
    required this.exercises,
  });

  @override
  List<Object?> get props => [userId, planId, name, description, exercises];
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
