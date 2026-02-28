import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:liftly/core/models/workout_session.dart';
import '../repositories/workout_repository.dart';
import 'workout_event.dart';
import 'workout_state.dart';

class WorkoutBloc extends Bloc<WorkoutEvent, WorkoutState> {
  final WorkoutRepository _workoutRepository;
  int _workoutIdCounter = 0;

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
      // Convert Map to WorkoutSession
      final workout = _mapToWorkoutSession(event.workoutData, event.userId);
      final result = await _workoutRepository.createWorkout(
        userId: event.userId,
        workout: workout,
      );

      emit(
        WorkoutSuccess(
          message: 'Workout logged successfully',
          data: result.toMap(),
        ),
      );
    } catch (e) {
      emit(WorkoutError(message: e.toString()));
    }
  }

  Future<void> _onWorkoutUpdated(
    WorkoutUpdated event,
    Emitter<WorkoutState> emit,
  ) async {
    final currentState = state;
    // Don't emit loading if we already have workouts, to preserve UI state
    if (currentState is! WorkoutsLoaded) {
      emit(const WorkoutLoading());
    }

    try {
      final workoutToUpdate =
          _mapToWorkoutSession(event.workoutData, event.userId);

      final result = await _workoutRepository.updateWorkout(
        userId: event.userId,
        workoutId: event.workoutId,
        workout: workoutToUpdate,
      );

      // Emit success first so BlocListener in edit page can show the popup.
      // The Future.delayed(Duration.zero) yields to the event loop between the
      // two emits, guaranteeing BlocListener processes WorkoutUpdatedSuccess in
      // its own microtask before WorkoutsLoaded arrives.
      emit(
        WorkoutUpdatedSuccess(
          message: 'Workout updated successfully',
          data: result.toMap(),
        ),
      );
      await Future.delayed(Duration.zero);

      // Emit the updated list last so BlocBuilder always sees WorkoutsLoaded
      // as the final state — prevents the history page's _lastInputWorkouts
      // cache from staying stale due to Flutter frame batching.
      if (currentState is WorkoutsLoaded) {
        final updatedWorkouts = currentState.workouts.map((w) {
          return w.id == event.workoutId ? result : w;
        }).toList();

        emit(WorkoutsLoaded(
          workouts: updatedWorkouts,
          hasReachedMax: currentState.hasReachedMax,
        ));
      }
    } catch (e) {
      emit(WorkoutError(message: e.toString()));
    }
  }

  Future<void> _onWorkoutDeleted(
    WorkoutDeleted event,
    Emitter<WorkoutState> emit,
  ) async {
    final currentState = state;
    // Don't emit loading if we already have workouts
    if (currentState is! WorkoutsLoaded) {
      emit(const WorkoutLoading());
    }

    try {
      await _workoutRepository.deleteWorkout(
        userId: event.userId,
        workoutId: event.workoutId,
      );

      if (currentState is WorkoutsLoaded) {
        final updatedWorkouts = currentState.workouts
            .where((w) => w.id != event.workoutId)
            .toList();

        emit(WorkoutsLoaded(
          workouts: updatedWorkouts,
          hasReachedMax: currentState.hasReachedMax,
        ));
      } else {
        // Fallback for non-loaded state: fetch list
        final workouts = await _workoutRepository.getWorkouts(
          userId: event.userId,
        );
        emit(WorkoutsLoaded(workouts: workouts));
      }
    } catch (e) {
      emit(WorkoutError(message: e.toString()));
    }
  }

  Future<void> _onWorkoutsFetched(
    WorkoutsFetched event,
    Emitter<WorkoutState> emit,
  ) async {
    if (state is WorkoutsLoaded && (state as WorkoutsLoaded).hasReachedMax) {
      if (event.offset != 0) return;
    }

    try {
      if (state is WorkoutInitial || event.offset == 0) {
        // Silent refresh: Only show loading if we haven't loaded anything yet
        if (state is! WorkoutsLoaded) {
          emit(const WorkoutLoading());
        }

        final workouts = await _workoutRepository.getWorkouts(
          userId: event.userId,
          limit: event.limit,
          offset: event.offset,
        );
        emit(
          WorkoutsLoaded(
            workouts: workouts,
            hasReachedMax: workouts.length < event.limit,
          ),
        );
      } else if (state is WorkoutsLoaded) {
        final currentWorkouts = (state as WorkoutsLoaded).workouts;
        final newWorkouts = await _workoutRepository.getWorkouts(
          userId: event.userId,
          limit: event.limit,
          offset: currentWorkouts.length,
        );

        emit(
          newWorkouts.isEmpty
              ? (state as WorkoutsLoaded).copyWith(hasReachedMax: true)
              : WorkoutsLoaded(
                  workouts: currentWorkouts + newWorkouts,
                  hasReachedMax: newWorkouts.length < event.limit,
                ),
        );
      }
    } catch (e) {
      emit(WorkoutError(message: e.toString()));
    }
  }

  /// Convert Map data to WorkoutSession model
  WorkoutSession _mapToWorkoutSession(
    Map<String, dynamic> data,
    String userId,
  ) {
    final exercises = <SessionExercise>[];
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    // Convert exercises from map
    if (data['exercises'] is List) {
      for (int exIndex = 0;
          exIndex < (data['exercises'] as List<dynamic>).length;
          exIndex++) {
        final exData = (data['exercises'] as List<dynamic>)[exIndex];
        final exMap = exData as Map<String, dynamic>;
        final sets = <ExerciseSet>[];


        // Convert sets
        if (exMap['sets'] is List) {
          for (int setIndex = 0;
              setIndex < (exMap['sets'] as List<dynamic>).length;
              setIndex++) {
            final setData = (exMap['sets'] as List<dynamic>)[setIndex];
            final setMap = setData as Map<String, dynamic>;
            final segments = <SetSegment>[];


            // Convert segments
            if (setMap['segments'] is List) {
              for (int segIndex = 0;
                  segIndex < (setMap['segments'] as List<dynamic>).length;
                  segIndex++) {
                final segData = (setMap['segments'] as List<dynamic>)[segIndex];
                final segMap = segData as Map<String, dynamic>;

                segments.add(
                  SetSegment(
                    id: (segMap['id'] as String?) ??
                        '${timestamp}_ex${exIndex}_s${setIndex}_seg$segIndex',
                    weight: (segMap['weight'] as num?)?.toDouble() ?? 0.0,
                    repsFrom: segMap['repsFrom'] as int? ?? 0,
                    repsTo: segMap['repsTo'] as int? ?? 0,
                    segmentOrder: segMap['segmentOrder'] as int? ?? 0,
                    notes: segMap['notes'] as String? ?? '',
                  ),
                );
              }
            }

            sets.add(
              ExerciseSet(
                id: (setMap['id'] as String?) ??
                    '${timestamp}_ex${exIndex}_s$setIndex',
                setNumber: setMap['setNumber'] as int? ?? 0,
                segments: segments,
              ),
            );
          }
        }

        exercises.add(
          SessionExercise(
            id: (exMap['id'] as String?) ?? '${timestamp}_ex$exIndex',
            name: exMap['name'] as String? ?? '',
            order: exMap['order'] as int? ?? 0,
            sets: sets,
            skipped: exMap['skipped'] as bool? ?? false,
            isTemplate: exMap['isTemplate'] as bool? ?? false,
            notes: exMap['notes'] as String? ?? '',
            variation: exMap['variation'] as String? ?? '',
          ),
        );
      }
    }

    final now = DateTime.now();

    // Helper to safely parse DateTime
    DateTime parseDateTime(dynamic value) {
      if (value is DateTime) return value;
      if (value is String) {
        try {
          return DateTime.parse(value);
        } catch (_) {
          return now;
        }
      }
      return now;
    }

    // Helper to safely parse nullable DateTime
    DateTime? parseNullableDateTime(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      if (value is String) {
        try {
          return DateTime.parse(value);
        } catch (_) {
          return null;
        }
      }
      return null;
    }

    final workoutDate = parseDateTime(data['workoutDate']);

    // Generate unique ID with counter to guarantee uniqueness
    _workoutIdCounter++;

    return WorkoutSession(
      id: (data['id'] as String?) ??
          '${workoutDate.millisecondsSinceEpoch}_${now.millisecondsSinceEpoch}_$_workoutIdCounter',
      userId: userId,
      planId: data['planId'] as String?,
      planName: data['planName'] as String?,
      workoutDate: workoutDate,
      startedAt: parseNullableDateTime(data['startedAt']),
      endedAt: parseNullableDateTime(data['endedAt']),
      exercises: exercises,
      createdAt: parseDateTime(data['createdAt']),
      updatedAt: parseDateTime(data['updatedAt']),
      isDraft: data['isDraft'] is int
          ? (data['isDraft'] as int) == 1
          : (data['isDraft'] as bool? ?? false),
    );
  }
}
