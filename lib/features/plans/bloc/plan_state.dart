import 'package:equatable/equatable.dart';
import '../../../core/models/workout_plan.dart';

abstract class PlanState extends Equatable {
  const PlanState();

  @override
  List<Object?> get props => [];
}

class PlanInitial extends PlanState {
  const PlanInitial();
}

class PlanLoading extends PlanState {
  const PlanLoading();
}

class PlansLoaded extends PlanState {
  final List<WorkoutPlan> plans;

  const PlansLoaded({required this.plans});

  @override
  List<Object?> get props => [plans];
}

class PlanSuccess extends PlanState {
  final String message;

  const PlanSuccess({required this.message});

  @override
  List<Object?> get props => [message];
}

class PlanError extends PlanState {
  final String message;

  const PlanError({required this.message});

  @override
  List<Object?> get props => [message];
}
