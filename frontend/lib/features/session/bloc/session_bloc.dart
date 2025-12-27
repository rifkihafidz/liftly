import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/models/workout_session.dart';
import '../../../core/services/api_service.dart';
import 'session_event.dart';
import 'session_state.dart';

class SessionBloc extends Bloc<SessionEvent, SessionState> {
  SessionBloc() : super(const SessionInitial()) {
    on<SessionStarted>(_onSessionStarted);
    on<SessionRecovered>(_onSessionRecovered);
    on<SessionExerciseSkipped>(_onExerciseSkipped);
    on<SessionExerciseUnskipped>(_onExerciseUnskipped);
    on<SessionSetAdded>(_onSetAdded);
    on<SessionSetRemoved>(_onSetRemoved);
    on<SessionSegmentAdded>(_onSegmentAdded);
    on<SessionSegmentRemoved>(_onSegmentRemoved);
    on<SessionEnded>(_onSessionEnded);
    on<SessionSaveRequested>(_onSessionSaved);
  }

  Future<void> _onSessionStarted(
    SessionStarted event,
    Emitter<SessionState> emit,
  ) async {
    emit(const SessionLoading());
    try {
      final exercises = event.exerciseNames
          .asMap()
          .entries
          .map(
            (e) => SessionExercise(
              id: 'ex_${e.key}',
              name: e.value,
              order: e.key,
              sets: [],
            ),
          )
          .toList();

      final session = WorkoutSession(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: event.userId,
        planId: event.planId,
        workoutDate: DateTime.now(),
        startedAt: DateTime.now(),
        exercises: exercises,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      emit(SessionInProgress(session: session));
    } catch (e) {
      emit(SessionError(message: 'Failed to start session: $e'));
    }
  }

  Future<void> _onSessionRecovered(
    SessionRecovered event,
    Emitter<SessionState> emit,
  ) async {
    try {
      emit(SessionInProgress(session: event.session));
    } catch (e) {
      emit(SessionError(message: 'Failed to recover session: $e'));
    }
  }

  Future<void> _onExerciseSkipped(
    SessionExerciseSkipped event,
    Emitter<SessionState> emit,
  ) async {
    if (state is! SessionInProgress) return;

    final currentState = state as SessionInProgress;
    final exercises = List<SessionExercise>.from(currentState.session.exercises);
    
    if (event.exerciseIndex < exercises.length) {
      final exercise = exercises[event.exerciseIndex];
      exercises[event.exerciseIndex] = SessionExercise(
        id: exercise.id,
        name: exercise.name,
        order: exercise.order,
        skipped: true,
        sets: exercise.sets,
      );

      final updatedSession = WorkoutSession(
        id: currentState.session.id,
        userId: currentState.session.userId,
        planId: currentState.session.planId,
        workoutDate: currentState.session.workoutDate,
        startedAt: currentState.session.startedAt,
        endedAt: currentState.session.endedAt,
        exercises: exercises,
        createdAt: currentState.session.createdAt,
        updatedAt: DateTime.now(),
      );

      emit(SessionInProgress(session: updatedSession));
    }
  }

  Future<void> _onExerciseUnskipped(
    SessionExerciseUnskipped event,
    Emitter<SessionState> emit,
  ) async {
    if (state is! SessionInProgress) return;

    final currentState = state as SessionInProgress;
    final exercises = List<SessionExercise>.from(currentState.session.exercises);
    
    if (event.exerciseIndex < exercises.length) {
      final exercise = exercises[event.exerciseIndex];
      exercises[event.exerciseIndex] = SessionExercise(
        id: exercise.id,
        name: exercise.name,
        order: exercise.order,
        skipped: false,
        sets: exercise.sets,
      );

      final updatedSession = WorkoutSession(
        id: currentState.session.id,
        userId: currentState.session.userId,
        planId: currentState.session.planId,
        workoutDate: currentState.session.workoutDate,
        startedAt: currentState.session.startedAt,
        endedAt: currentState.session.endedAt,
        exercises: exercises,
        createdAt: currentState.session.createdAt,
        updatedAt: DateTime.now(),
      );

      emit(SessionInProgress(session: updatedSession));
    }
  }

  Future<void> _onSetAdded(
    SessionSetAdded event,
    Emitter<SessionState> emit,
  ) async {
    if (state is! SessionInProgress) return;

    final currentState = state as SessionInProgress;
    final exercises = List<SessionExercise>.from(currentState.session.exercises);
    
    if (event.exerciseIndex < exercises.length) {
      final exercise = exercises[event.exerciseIndex];
      final newSet = ExerciseSet(
        id: 'set_${DateTime.now().millisecondsSinceEpoch}',
        segments: [
          SetSegment(
            id: 'seg_${DateTime.now().millisecondsSinceEpoch}',
            weight: event.weight,
            repsFrom: event.repsFrom,
            repsTo: event.repsTo,
            segmentOrder: 0,
            notes: event.notes,
          ),
        ],
        setNumber: exercise.sets.length + 1,
      );

      final updatedSets = [...exercise.sets, newSet];
      exercises[event.exerciseIndex] = SessionExercise(
        id: exercise.id,
        name: exercise.name,
        order: exercise.order,
        skipped: exercise.skipped,
        sets: updatedSets,
      );

      final updatedSession = WorkoutSession(
        id: currentState.session.id,
        userId: currentState.session.userId,
        planId: currentState.session.planId,
        workoutDate: currentState.session.workoutDate,
        startedAt: currentState.session.startedAt,
        endedAt: currentState.session.endedAt,
        exercises: exercises,
        createdAt: currentState.session.createdAt,
        updatedAt: DateTime.now(),
      );

      emit(SessionInProgress(session: updatedSession));
    }
  }

  Future<void> _onSetRemoved(
    SessionSetRemoved event,
    Emitter<SessionState> emit,
  ) async {
    if (state is! SessionInProgress) return;

    final currentState = state as SessionInProgress;
    final exercises = List<SessionExercise>.from(currentState.session.exercises);
    
    if (event.exerciseIndex < exercises.length) {
      final exercise = exercises[event.exerciseIndex];
      final updatedSets = List<ExerciseSet>.from(exercise.sets);
      
      if (event.setIndex < updatedSets.length) {
        updatedSets.removeAt(event.setIndex);
        
        exercises[event.exerciseIndex] = SessionExercise(
          id: exercise.id,
          name: exercise.name,
          order: exercise.order,
          skipped: exercise.skipped,
          sets: updatedSets,
        );

        final updatedSession = WorkoutSession(
          id: currentState.session.id,
          userId: currentState.session.userId,
          planId: currentState.session.planId,
          workoutDate: currentState.session.workoutDate,
          startedAt: currentState.session.startedAt,
          endedAt: currentState.session.endedAt,
          exercises: exercises,
          createdAt: currentState.session.createdAt,
          updatedAt: DateTime.now(),
        );

      emit(SessionInProgress(session: updatedSession));
      }
    }
  }

  Future<void> _onSegmentAdded(
    SessionSegmentAdded event,
    Emitter<SessionState> emit,
  ) async {
    if (state is! SessionInProgress) return;

    final currentState = state as SessionInProgress;
    final exercises = List<SessionExercise>.from(currentState.session.exercises);
    
    if (event.exerciseIndex < exercises.length) {
      final exercise = exercises[event.exerciseIndex];
      final sets = List<ExerciseSet>.from(exercise.sets);
      
      if (event.setIndex < sets.length) {
        final set = sets[event.setIndex];
        final newSegment = SetSegment(
          id: 'seg_${DateTime.now().millisecondsSinceEpoch}',
          weight: event.weight,
          repsFrom: event.repsFrom,
          repsTo: event.repsTo,
          segmentOrder: set.segments.length,
          notes: '',
        );

        final updatedSegments = [...set.segments, newSegment];
        sets[event.setIndex] = ExerciseSet(
          id: set.id,
          segments: updatedSegments,
          setNumber: set.setNumber,
        );

        exercises[event.exerciseIndex] = SessionExercise(
          id: exercise.id,
          name: exercise.name,
          order: exercise.order,
          skipped: exercise.skipped,
          sets: sets,
        );

        final updatedSession = WorkoutSession(
          id: currentState.session.id,
          userId: currentState.session.userId,
          planId: currentState.session.planId,
          workoutDate: currentState.session.workoutDate,
          startedAt: currentState.session.startedAt,
          endedAt: currentState.session.endedAt,
          exercises: exercises,
          createdAt: currentState.session.createdAt,
          updatedAt: DateTime.now(),
        );

      emit(SessionInProgress(session: updatedSession));
      }
    }
  }

  Future<void> _onSegmentRemoved(
    SessionSegmentRemoved event,
    Emitter<SessionState> emit,
  ) async {
    if (state is! SessionInProgress) return;

    final currentState = state as SessionInProgress;
    final exercises = List<SessionExercise>.from(currentState.session.exercises);
    
    if (event.exerciseIndex < exercises.length) {
      final exercise = exercises[event.exerciseIndex];
      final sets = List<ExerciseSet>.from(exercise.sets);
      
      if (event.setIndex < sets.length) {
        final set = sets[event.setIndex];
        
        // Don't allow removing if it's the only segment
        if (set.segments.length > 1) {
          final updatedSegments = List<SetSegment>.from(set.segments);
          updatedSegments.removeAt(event.segmentIndex);
          
          sets[event.setIndex] = ExerciseSet(
            id: set.id,
            segments: updatedSegments,
            setNumber: set.setNumber,
          );

          exercises[event.exerciseIndex] = SessionExercise(
            id: exercise.id,
            name: exercise.name,
            order: exercise.order,
            skipped: exercise.skipped,
            sets: sets,
          );

          final updatedSession = WorkoutSession(
            id: currentState.session.id,
            userId: currentState.session.userId,
            planId: currentState.session.planId,
            workoutDate: currentState.session.workoutDate,
            startedAt: currentState.session.startedAt,
            endedAt: currentState.session.endedAt,
            exercises: exercises,
            createdAt: currentState.session.createdAt,
            updatedAt: DateTime.now(),
          );

      emit(SessionInProgress(session: updatedSession));
        }
      }
    }
  }

  Future<void> _onSessionEnded(
    SessionEnded event,
    Emitter<SessionState> emit,
  ) async {
    if (state is! SessionInProgress) return;

    final currentState = state as SessionInProgress;
    final updatedSession = WorkoutSession(
      id: currentState.session.id,
      userId: currentState.session.userId,
      planId: currentState.session.planId,
      workoutDate: currentState.session.workoutDate,
      startedAt: currentState.session.startedAt,
      endedAt: DateTime.now(),
      exercises: currentState.session.exercises,
      createdAt: currentState.session.createdAt,
      updatedAt: DateTime.now(),
    );

      emit(SessionInProgress(session: updatedSession));
  }

  Future<void> _onSessionSaved(
    SessionSaveRequested event,
    Emitter<SessionState> emit,
  ) async {
    if (state is! SessionInProgress) return;

    try {
      final currentState = state as SessionInProgress;
      final session = currentState.session;

      // Build workout data for API
      final workoutData = {
        'workoutDate': session.workoutDate.toIso8601String(),
        'startedAt': session.startedAt?.toIso8601String(),
        'endedAt': DateTime.now().toIso8601String(),
        'planId': session.planId != null ? int.tryParse(session.planId!) : null,
        'exercises': session.exercises.map((exercise) {
          return {
            'name': exercise.name,
            'order': exercise.order,
            'skipped': exercise.skipped,
            'sets': exercise.sets.map((set) {
              return {
                'setNumber': set.setNumber,
                'segments': set.segments.map((segment) {
                  return {
                    'weight': segment.weight,
                    'repsFrom': segment.repsFrom,
                    'repsTo': segment.repsTo,
                    'segmentOrder': segment.segmentOrder,
                    'notes': segment.notes,
                  };
                }).toList(),
              };
            }).toList(),
          };
        }).toList(),
      };

      // Call API to save workout
      final response = await ApiService.createWorkout(
        userId: session.userId,
        workoutData: workoutData,
      );

      if (response.success && response.data != null) {
        emit(SessionSaved(session: session));
      } else {
        emit(SessionError(message: response.message));
      }
    } catch (e) {
      emit(SessionError(message: 'Failed to save session: $e'));
    }
  }
}
