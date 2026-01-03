import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/models/workout_session.dart';
import '../../workout_log/repositories/workout_repository.dart';
import 'session_event.dart';
import 'session_state.dart';

// Global counter for unique workout IDs
int _workoutIdCounter = 0;

class SessionBloc extends Bloc<SessionEvent, SessionState> {
  final WorkoutRepository _workoutRepository = WorkoutRepository();
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
    on<SessionDraftResumed>(_onSessionDraftResumed);
    on<SessionSaveDraftRequested>(_onSessionSaveDraftRequested);
  }

  Future<void> _onSessionStarted(
    SessionStarted event,
    Emitter<SessionState> emit,
  ) async {
    emit(const SessionLoading());
    try {
      final now = DateTime.now();
      final workoutDate = now; // Initial workout date is today

      // Increment counter for unique ID generation
      _workoutIdCounter++;

      // Generate unique ID based on workout date, current time, and counter
      // This ensures uniqueness even if app is restarted
      final generatedId =
          '${workoutDate.millisecondsSinceEpoch}_${now.millisecondsSinceEpoch}_$_workoutIdCounter';
      final timestamp = now.millisecondsSinceEpoch;
      final exercises = event.exerciseNames
          .asMap()
          .entries
          .map(
            (e) => SessionExercise(
              id: 'ex_${timestamp}_${e.key}',
              name: e.value,
              order: e.key,
              sets: [],
            ),
          )
          .toList();

      final session = WorkoutSession(
        id: generatedId,
        userId: event.userId,
        planId: event.planId,
        workoutDate: workoutDate,
        startedAt: null,
        exercises: exercises,
        createdAt: now,
        updatedAt: now,
      );

      // Load history
      // Load history and PRs
      final previousSessions = <String, SessionExercise>{};
      final exercisePRs = <String, SetSegment>{};

      for (final name in event.exerciseNames) {
        // Load Last Log
        final lastLog = await _workoutRepository.getLastExerciseLog(
          userId: event.userId,
          exerciseName: name,
        );
        if (lastLog != null) {
          previousSessions[name] = lastLog;
        }

        // Load PR
        final pr = await _workoutRepository.getExercisePR(
          userId: event.userId,
          exerciseName: name,
        );
        if (pr != null) {
          exercisePRs[name] = pr;
        }
      }

      emit(
        SessionInProgress(
          session: session,
          previousSessions: previousSessions,
          exercisePRs: exercisePRs,
        ),
      );
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
    final exercises = List<SessionExercise>.from(
      currentState.session.exercises,
    );

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

      emit(
        SessionInProgress(
          session: updatedSession,
          previousSessions: currentState.previousSessions,
          exercisePRs: currentState.exercisePRs,
        ),
      );
    }
  }

  Future<void> _onExerciseUnskipped(
    SessionExerciseUnskipped event,
    Emitter<SessionState> emit,
  ) async {
    if (state is! SessionInProgress) return;

    final currentState = state as SessionInProgress;
    final exercises = List<SessionExercise>.from(
      currentState.session.exercises,
    );

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

      emit(
        SessionInProgress(
          session: updatedSession,
          previousSessions: currentState.previousSessions,
          exercisePRs: currentState.exercisePRs,
        ),
      );
    }
  }

  Future<void> _onSetAdded(
    SessionSetAdded event,
    Emitter<SessionState> emit,
  ) async {
    if (state is! SessionInProgress) return;

    final currentState = state as SessionInProgress;
    final exercises = List<SessionExercise>.from(
      currentState.session.exercises,
    );

    if (event.exerciseIndex < exercises.length) {
      final exercise = exercises[event.exerciseIndex];
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final setNumber = exercise.sets.length + 1;
      final newSet = ExerciseSet(
        id: 'set_${timestamp}_ex${event.exerciseIndex}_s$setNumber',
        segments: [
          SetSegment(
            id: 'seg_${timestamp}_ex${event.exerciseIndex}_s${setNumber}_0',
            weight: event.weight,
            repsFrom: event.repsFrom,
            repsTo: event.repsTo,
            segmentOrder: 0,
            notes: event.notes,
          ),
        ],
        setNumber: setNumber,
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

      emit(
        SessionInProgress(
          session: updatedSession,
          previousSessions: currentState.previousSessions,
          exercisePRs: currentState.exercisePRs,
        ),
      );
    }
  }

  Future<void> _onSetRemoved(
    SessionSetRemoved event,
    Emitter<SessionState> emit,
  ) async {
    if (state is! SessionInProgress) return;

    final currentState = state as SessionInProgress;
    final exercises = List<SessionExercise>.from(
      currentState.session.exercises,
    );

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

        emit(
          SessionInProgress(
            session: updatedSession,
            previousSessions: currentState.previousSessions,
            exercisePRs: currentState.exercisePRs,
          ),
        );
      }
    }
  }

  Future<void> _onSegmentAdded(
    SessionSegmentAdded event,
    Emitter<SessionState> emit,
  ) async {
    if (state is! SessionInProgress) return;

    final currentState = state as SessionInProgress;
    final exercises = List<SessionExercise>.from(
      currentState.session.exercises,
    );

    if (event.exerciseIndex < exercises.length) {
      final exercise = exercises[event.exerciseIndex];
      final sets = List<ExerciseSet>.from(exercise.sets);

      if (event.setIndex < sets.length) {
        final set = sets[event.setIndex];
        final segmentOrder = set.segments.length;
        final newSegment = SetSegment(
          id: 'seg_${DateTime.now().millisecondsSinceEpoch}_ex${event.exerciseIndex}_s${event.setIndex}_seg$segmentOrder',
          weight: event.weight,
          repsFrom: event.repsFrom,
          repsTo: event.repsTo,
          segmentOrder: segmentOrder,
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

        emit(
          SessionInProgress(
            session: updatedSession,
            previousSessions: currentState.previousSessions,
            exercisePRs: currentState.exercisePRs,
          ),
        );
      }
    }
  }

  Future<void> _onSegmentRemoved(
    SessionSegmentRemoved event,
    Emitter<SessionState> emit,
  ) async {
    if (state is! SessionInProgress) return;

    final currentState = state as SessionInProgress;
    final exercises = List<SessionExercise>.from(
      currentState.session.exercises,
    );

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

          emit(
            SessionInProgress(
              session: updatedSession,
              previousSessions: currentState.previousSessions,
              exercisePRs: currentState.exercisePRs,
            ),
          );
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

    emit(
      SessionInProgress(
        session: updatedSession,
        previousSessions: currentState.previousSessions,
        exercisePRs: currentState.exercisePRs,
      ),
    );
  }

  Future<void> _onSessionSaved(
    SessionSaveRequested event,
    Emitter<SessionState> emit,
  ) async {
    if (state is! SessionInProgress) return;

    try {
      final currentState = state as SessionInProgress;
      final session = currentState.session;

      // Save workout directly using WorkoutRepository
      final savedSession = await _workoutRepository.createWorkout(
        userId: session.userId,
        workout: session,
      );

      emit(SessionSaved(session: savedSession));
    } catch (e) {
      emit(SessionError(message: 'Failed to save session: $e'));
    }
  }

  Future<void> _onSessionDraftResumed(
    SessionDraftResumed event,
    Emitter<SessionState> emit,
  ) async {
    emit(const SessionLoading());
    try {
      final session = event.draftSession;

      // Load history and PRs
      final previousSessions = <String, SessionExercise>{};
      final exercisePRs = <String, SetSegment>{};
      // Extract unique exercise names from draft
      final exerciseNames = session.exercises.map((e) => e.name).toSet();

      for (final name in exerciseNames) {
        // Load Last Log
        final lastLog = await _workoutRepository.getLastExerciseLog(
          userId: session.userId,
          exerciseName: name,
        );
        if (lastLog != null) {
          previousSessions[name] = lastLog;
        }

        // Load PR
        final pr = await _workoutRepository.getExercisePR(
          userId: session.userId,
          exerciseName: name,
        );
        if (pr != null) {
          exercisePRs[name] = pr;
        }
      }

      emit(
        SessionInProgress(
          session: session,
          previousSessions: previousSessions,
          exercisePRs: exercisePRs,
        ),
      );
    } catch (e) {
      emit(SessionError(message: 'Failed to resume draft: $e'));
    }
  }

  Future<void> _onSessionSaveDraftRequested(
    SessionSaveDraftRequested event,
    Emitter<SessionState> emit,
  ) async {
    if (state is! SessionInProgress) return;

    try {
      final currentState = state as SessionInProgress;
      final session = currentState.session.copyWith(
        isDraft: true,
        updatedAt: DateTime.now(),
      );

      // Save workout directly using WorkoutRepository
      // createWorkout uses REPLACE conflict algorithm, so it handles updates too
      final savedSession = await _workoutRepository.createWorkout(
        userId: session.userId,
        workout: session,
      );

      emit(SessionDraftSaved(session: savedSession));
    } catch (e) {
      emit(SessionError(message: 'Failed to save draft: $e'));
    }
  }
}
