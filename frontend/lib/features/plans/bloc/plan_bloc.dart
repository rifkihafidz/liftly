import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/models/workout_plan.dart';
import 'plan_event.dart';
import 'plan_state.dart';

class PlanBloc extends Bloc<PlanEvent, PlanState> {
  final List<WorkoutPlan> _plans = [];

  PlanBloc() : super(const PlanInitial()) {
    on<PlansFetchRequested>(_onPlansFetchRequested);
    on<PlanCreated>(_onPlanCreated);
    on<PlanUpdated>(_onPlanUpdated);
    on<PlanDeleted>(_onPlanDeleted);
  }

  Future<void> _onPlansFetchRequested(
    PlansFetchRequested event,
    Emitter<PlanState> emit,
  ) async {
    emit(const PlanLoading());
    try {
      // TODO: Call API to fetch plans
      await Future.delayed(const Duration(milliseconds: 500));
      emit(PlansLoaded(plans: _plans));
    } catch (e) {
      emit(PlanError(message: 'Failed to load plans: $e'));
    }
  }

  Future<void> _onPlanCreated(
    PlanCreated event,
    Emitter<PlanState> emit,
  ) async {
    try {
      // TODO: Call API to create plan
      final exercises = event.exercises
          .asMap()
          .entries
          .map(
            (e) => PlanExercise(
              id: 'ex_${DateTime.now().millisecondsSinceEpoch}_${e.key}',
              name: e.value,
              order: e.key,
            ),
          )
          .toList();

      final newPlan = WorkoutPlan(
        id: 'plan_${DateTime.now().millisecondsSinceEpoch}',
        userId: 'user_1', // TODO: Get from auth
        name: event.name,
        description: event.description,
        exercises: exercises,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      _plans.add(newPlan);
      emit(const PlanSuccess(message: 'Plan created successfully'));
      emit(PlansLoaded(plans: _plans));
    } catch (e) {
      emit(PlanError(message: 'Failed to create plan: $e'));
    }
  }

  Future<void> _onPlanUpdated(
    PlanUpdated event,
    Emitter<PlanState> emit,
  ) async {
    try {
      // TODO: Call API to update plan
      final index = _plans.indexWhere((p) => p.id == event.planId);
      if (index != -1) {
        final exercises = event.exercises
            .asMap()
            .entries
            .map(
              (e) => PlanExercise(
                id: 'ex_${event.planId}_${e.key}',
                name: e.value,
                order: e.key,
              ),
            )
            .toList();

        final updatedPlan = WorkoutPlan(
          id: event.planId,
          userId: _plans[index].userId,
          name: event.name,
          description: event.description,
          exercises: exercises,
          createdAt: _plans[index].createdAt,
          updatedAt: DateTime.now(),
        );

        _plans[index] = updatedPlan;
        emit(const PlanSuccess(message: 'Plan updated successfully'));
        emit(PlansLoaded(plans: _plans));
      }
    } catch (e) {
      emit(PlanError(message: 'Failed to update plan: $e'));
    }
  }

  Future<void> _onPlanDeleted(
    PlanDeleted event,
    Emitter<PlanState> emit,
  ) async {
    try {
      // TODO: Call API to delete plan
      _plans.removeWhere((p) => p.id == event.planId);
      emit(const PlanSuccess(message: 'Plan deleted successfully'));
      emit(PlansLoaded(plans: _plans));
    } catch (e) {
      emit(PlanError(message: 'Failed to delete plan: $e'));
    }
  }
}
