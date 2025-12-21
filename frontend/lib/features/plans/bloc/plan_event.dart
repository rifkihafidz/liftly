import 'package:equatable/equatable.dart';

abstract class PlanEvent extends Equatable {
  const PlanEvent();

  @override
  List<Object?> get props => [];
}

class PlansFetchRequested extends PlanEvent {
  const PlansFetchRequested();
}

class PlanCreated extends PlanEvent {
  final String name;
  final String? description;
  final List<String> exercises;

  const PlanCreated({
    required this.name,
    this.description,
    required this.exercises,
  });

  @override
  List<Object?> get props => [name, description, exercises];
}

class PlanUpdated extends PlanEvent {
  final String planId;
  final String name;
  final String? description;
  final List<String> exercises;

  const PlanUpdated({
    required this.planId,
    required this.name,
    this.description,
    required this.exercises,
  });

  @override
  List<Object?> get props => [planId, name, description, exercises];
}

class PlanDeleted extends PlanEvent {
  final String planId;

  const PlanDeleted({required this.planId});

  @override
  List<Object?> get props => [planId];
}
