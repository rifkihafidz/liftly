import 'package:flutter_bloc/flutter_bloc.dart';
import '../repositories/workout_repository.dart';
import 'workout_event.dart';
import 'workout_state.dart';

class WorkoutBloc extends Bloc<WorkoutEvent, WorkoutState> {
  final WorkoutRepository _workoutRepository;

  WorkoutBloc({required WorkoutRepository workoutRepository})
      : _workoutRepository = workoutRepository,
        super(const WorkoutInitial()) {
    on<WorkoutSubmitted>(_onWorkoutSubmitted);
    on<WorkoutUpdated>(_onWorkoutUpdated);
    on<WorkoutDeleted>(_onWorkoutDeleted);
    on<WorkoutsFetched>(_onWorkoutsFetched);
  }

  Future<void> _onWorkoutSubmitted(
    WorkoutSubmitted event,
    Emitter<WorkoutState> emit,
  ) async {
    emit(const WorkoutLoading());
    try {
      final result = await _workoutRepository.createWorkout(
        userId: event.userId,
        workoutData: event.workoutData,
      );

      emit(WorkoutSuccess(
        message: 'Workout logged successfully',
        data: result,
      ));
    } catch (e) {
      emit(WorkoutError(message: e.toString()));
    }
  }

  Future<void> _onWorkoutUpdated(
    WorkoutUpdated event,
    Emitter<WorkoutState> emit,
  ) async {
    emit(const WorkoutLoading());
    try {
      final result = await _workoutRepository.updateWorkout(
        userId: event.userId,
        workoutId: event.workoutId,
        workoutData: event.workoutData,
      );

      emit(WorkoutUpdatedSuccess(
        message: 'Workout updated successfully',
        data: result,
      ));
    } catch (e) {
      emit(WorkoutError(message: e.toString()));
    }
  }

  Future<void> _onWorkoutDeleted(
    WorkoutDeleted event,
    Emitter<WorkoutState> emit,
  ) async {
    emit(const WorkoutLoading());
    try {
      await _workoutRepository.deleteWorkout(
        userId: event.userId,
        workoutId: event.workoutId,
      );

      // Fetch updated list after delete
      final workouts = await _workoutRepository.getWorkouts(
        userId: event.userId,
      );

      emit(WorkoutsLoaded(workouts: workouts));
    } catch (e) {
      emit(WorkoutError(message: e.toString()));
    }
  }

  Future<void> _onWorkoutsFetched(
    WorkoutsFetched event,
    Emitter<WorkoutState> emit,
  ) async {
    emit(const WorkoutLoading());
    try {
      final workouts = await _workoutRepository.getWorkouts(
        userId: event.userId,
      );

      emit(WorkoutsLoaded(workouts: workouts));
    } catch (e) {
      emit(WorkoutError(message: e.toString()));
    }
  }
}
