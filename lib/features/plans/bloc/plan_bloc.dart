import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/models/workout_plan.dart';
import '../repositories/plan_repository.dart';
import 'plan_event.dart';
import 'plan_state.dart';

class PlanBloc extends Bloc<PlanEvent, PlanState> {
  final PlanRepository _planRepository;
  /// Cached plan list, independent of state, to avoid data loss
  /// when an intermediate state (PlanLoading/PlanSuccess) is emitted.
  List<WorkoutPlan> _cachedPlans = [];

  PlanBloc({required PlanRepository planRepository})
      : _planRepository = planRepository,
        super(const PlanInitial()) {
    on<PlansFetchRequested>(_onPlansFetchRequested);
    on<PlanCreated>(_onPlanCreated);
    on<PlanUpdated>(_onPlanUpdated);
    on<PlanDeleted>(_onPlanDeleted);
  }

  /// Helper to get current plans — uses cache that survives intermediate states.
  List<WorkoutPlan> get _currentPlans => _cachedPlans;

  Future<void> _onPlansFetchRequested(
    PlansFetchRequested event,
    Emitter<PlanState> emit,
  ) async {
    if (state is PlanInitial) {
      emit(const PlanLoading());
    }
    try {
      final plans = await _planRepository.getPlans(userId: event.userId);
      _cachedPlans = plans;
      emit(PlansLoaded(plans: plans));
    } catch (e) {
      emit(PlanError(message: e.toString().replaceFirst('Exception: ', '')));
    }
  }

  Future<void> _onPlanCreated(
    PlanCreated event,
    Emitter<PlanState> emit,
  ) async {
    if (state is! PlansLoaded) {
      emit(const PlanLoading());
    }
    try {
      final newPlan = await _planRepository.createPlan(
        userId: event.userId,
        name: event.name,
        description: event.description,
        exercises: event.exercises,
        exerciseVariations: event.exerciseVariations,
      );

      final updatedPlans = [..._currentPlans, newPlan];
      _cachedPlans = updatedPlans;
      emit(const PlanSuccess(message: 'Plan created successfully'));
      emit(PlansLoaded(plans: updatedPlans));
    } catch (e) {
      emit(PlanError(message: e.toString().replaceFirst('Exception: ', '')));
    }
  }

  Future<void> _onPlanUpdated(
    PlanUpdated event,
    Emitter<PlanState> emit,
  ) async {
    if (state is! PlansLoaded) {
      emit(const PlanLoading());
    }
    try {
      final updatedPlan = await _planRepository.updatePlan(
        userId: event.userId,
        planId: event.planId,
        name: event.name,
        description: event.description,
        exercises: event.exercises,
        exerciseVariations: event.exerciseVariations,
      );

      final updatedPlans = _currentPlans.map((p) {
        return p.id == event.planId ? updatedPlan : p;
      }).toList();

      _cachedPlans = updatedPlans;
      emit(const PlanSuccess(message: 'Plan updated successfully'));
      emit(PlansLoaded(plans: updatedPlans));
    } catch (e) {
      emit(PlanError(message: e.toString().replaceFirst('Exception: ', '')));
    }
  }

  Future<void> _onPlanDeleted(
    PlanDeleted event,
    Emitter<PlanState> emit,
  ) async {
    if (state is! PlansLoaded) {
      emit(const PlanLoading());
    }
    try {
      await _planRepository.deletePlan(
        userId: event.userId,
        planId: event.planId,
      );

      final updatedPlans = _currentPlans.where((p) => p.id != event.planId).toList();
      _cachedPlans = updatedPlans;
      emit(const PlanSuccess(message: 'Plan deleted successfully'));
      emit(PlansLoaded(plans: updatedPlans));
    } catch (e) {
      emit(PlanError(message: e.toString().replaceFirst('Exception: ', '')));
    }
  }
}
