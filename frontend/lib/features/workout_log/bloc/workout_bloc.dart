import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:liftly/core/models/workout_session.dart';
import 'package:liftly/core/services/sqlite_service.dart';
import '../repositories/workout_repository.dart';
import 'workout_event.dart';
import 'workout_state.dart';

// Global counter for unique workout IDs
int _workoutIdCounter = 0;

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
      // Convert Map to WorkoutSession
      final workout = _mapToWorkoutSession(event.workoutData, event.userId);
      final result = await _workoutRepository.createWorkout(
        userId: event.userId,
        workout: workout,
      );

      emit(WorkoutSuccess(
        message: 'Workout logged successfully',
        data: result.toMap(),
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
      // Convert Map to WorkoutSession
      final workout = _mapToWorkoutSession(event.workoutData, event.userId);
      
      final result = await _workoutRepository.updateWorkout(
        userId: event.userId,
        workoutId: event.workoutId,
        workout: workout,
      );

      emit(WorkoutUpdatedSuccess(
        message: 'Workout updated successfully',
        data: result.toMap(),
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

  /// Convert Map data to WorkoutSession model
  WorkoutSession _mapToWorkoutSession(
    Map<String, dynamic> data,
    String userId,
  ) {
    final exercises = <SessionExercise>[];
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    // Convert exercises from map
    if (data['exercises'] is List) {
      for (int exIndex = 0; exIndex < (data['exercises'] as List<dynamic>).length; exIndex++) {
        final exData = (data['exercises'] as List<dynamic>)[exIndex];
        final exMap = exData as Map<String, dynamic>;
        final sets = <ExerciseSet>[];

        // Convert sets
        if (exMap['sets'] is List) {
          for (int setIndex = 0; setIndex < (exMap['sets'] as List<dynamic>).length; setIndex++) {
            final setData = (exMap['sets'] as List<dynamic>)[setIndex];
            final setMap = setData as Map<String, dynamic>;
            final segments = <SetSegment>[];

            // Convert segments
            if (setMap['segments'] is List) {
              for (int segIndex = 0; segIndex < (setMap['segments'] as List<dynamic>).length; segIndex++) {
                final segData = (setMap['segments'] as List<dynamic>)[segIndex];
                final segMap = segData as Map<String, dynamic>;
                segments.add(
                  SetSegment(
                    id: (segMap['id'] as String?) ??
                        '${timestamp}_ex${exIndex}_s${setIndex}_seg${segIndex}',
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
                    '${timestamp}_ex${exIndex}_s${setIndex}',
                setNumber: setMap['setNumber'] as int? ?? 0,
                segments: segments,
              ),
            );
          }
        }

        exercises.add(
          SessionExercise(
            id: (exMap['id'] as String?) ??
                '${timestamp}_ex${exIndex}',
            name: exMap['name'] as String? ?? '',
            order: exMap['order'] as int? ?? 0,
            sets: sets,
            skipped: exMap['skipped'] as bool? ?? false,
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
          return SQLiteService.parseDateTime(value);
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
          return SQLiteService.parseDateTime(value);
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
          '${workoutDate.millisecondsSinceEpoch}_${now.millisecondsSinceEpoch}_${_workoutIdCounter}',
      userId: userId,
      planId: data['planId'] as String?,
      workoutDate: workoutDate,
      startedAt: parseNullableDateTime(data['startedAt']),
      endedAt: parseNullableDateTime(data['endedAt']),
      exercises: exercises,
      createdAt: parseDateTime(data['createdAt']),
      updatedAt: parseDateTime(data['updatedAt']),
    );
  }
}
