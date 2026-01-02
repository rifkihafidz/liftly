import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/models/workout_plan.dart';
import '../repositories/plan_repository.dart';
import 'plan_event.dart';
import 'plan_state.dart';

class PlanBloc extends Bloc<PlanEvent, PlanState> {
  final PlanRepository _planRepository;
  final List<WorkoutPlan> _plans = [];
  static const String defaultUserId = '1';

  PlanBloc({required PlanRepository planRepository})
      : _planRepository = planRepository,
        super(const PlanInitial()) {
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
      final plans = await _planRepository.getPlans(userId: event.userId);
      _plans.clear();
      _plans.addAll(plans);
      emit(PlansLoaded(plans: _plans));
    } catch (e) {
      emit(PlanError(message: _parseErrorMessage(e.toString())));
    }
  }

  Future<void> _onPlanCreated(
    PlanCreated event,
    Emitter<PlanState> emit,
  ) async {
    emit(const PlanLoading());
    try {
      final newPlan = await _planRepository.createPlan(
        userId: event.userId,
        name: event.name,
        description: event.description,
        exercises: event.exercises,
      );

      _plans.add(newPlan);
      emit(const PlanSuccess(message: 'Plan created successfully'));
      emit(PlansLoaded(plans: _plans));
    } catch (e) {
      emit(PlanError(message: _parseErrorMessage(e.toString())));
    }
  }

  Future<void> _onPlanUpdated(
    PlanUpdated event,
    Emitter<PlanState> emit,
  ) async {
    emit(const PlanLoading());
    try {
      final updatedPlan = await _planRepository.updatePlan(
        userId: event.userId,
        planId: event.planId,
        name: event.name,
        description: event.description,
        exercises: event.exercises,
      );

      final index = _plans.indexWhere((p) => p.id == event.planId);
      if (index != -1) {
        _plans[index] = updatedPlan;
      }

      emit(const PlanSuccess(message: 'Plan updated successfully'));
      emit(PlansLoaded(plans: _plans));
    } catch (e) {
      emit(PlanError(message: _parseErrorMessage(e.toString())));
    }
  }

  Future<void> _onPlanDeleted(
    PlanDeleted event,
    Emitter<PlanState> emit,
  ) async {
    emit(const PlanLoading());
    try {
      await _planRepository.deletePlan(
        userId: event.userId,
        planId: event.planId,
      );

      _plans.removeWhere((p) => p.id == event.planId);
      emit(const PlanSuccess(message: 'Plan deleted successfully'));
      emit(PlansLoaded(plans: _plans));
    } catch (e) {
      emit(PlanError(message: _parseErrorMessage(e.toString())));
    }
  }

  String _parseErrorMessage(String error) {
    if (error.contains('Exception: ')) {
      return error.replaceAll('Exception: ', '');
    }
    return error;
  }
}
