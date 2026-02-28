import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/models/workout_session.dart';
import '../../../core/services/backup_service.dart';
import '../../../core/utils/app_logger.dart';

import '../../workout_log/repositories/workout_repository.dart';
import '../../../core/models/personal_record.dart';
import 'session_event.dart';
import 'session_state.dart';

const String _tag = 'SessionBloc';

class SessionBloc extends Bloc<SessionEvent, SessionState> {
  final WorkoutRepository _workoutRepository;
  int _workoutIdCounter = 0;

  SessionBloc({WorkoutRepository? workoutRepository})
      : _workoutRepository = workoutRepository ?? WorkoutRepository(),
        super(const SessionInitial()) {
    on<SessionStarted>(_onSessionStarted);
    on<SessionRecovered>(_onSessionRecovered);
    on<SessionExerciseSkipToggled>(_onExerciseSkipToggled);
    on<SessionSetAdded>(_onSetAdded);
    on<SessionSetRemoved>(_onSetRemoved);
    on<SessionSegmentAdded>(_onSegmentAdded);
    on<SessionSegmentRemoved>(_onSegmentRemoved);
    on<SessionSegmentUpdated>(_onSegmentUpdated);
    on<SessionDateTimesUpdated>(_onDateTimesUpdated);
    on<SessionEnded>(_onSessionEnded);
    on<SessionSaveRequested>(_onSessionSaved);
    on<SessionDraftResumed>(_onSessionDraftResumed);
    on<SessionSaveDraftRequested>(_onSessionSaveDraftRequested);
    on<SessionCheckDraftRequested>(_onCheckDraftRequested);
    on<SessionExerciseAdded>(_onExerciseAdded);
    on<SessionExerciseRemoved>(_onExerciseRemoved);
    on<SessionExerciseNameUpdated>(_onExerciseNameUpdated);
    on<SessionExerciseVariationUpdated>(_onExerciseVariationUpdated);
    on<SessionExerciseNotesUpdated>(_onExerciseNotesUpdated);
    on<SessionDiscarded>(_onSessionDiscarded);
    on<SessionExercisesReordered>(_onExercisesReordered);

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
      final exercises = event.exerciseNames.asMap().entries.map(
        (e) {
          final variation = (event.exerciseVariations != null &&
                  e.key < event.exerciseVariations!.length)
              ? event.exerciseVariations![e.key]
              : '';
          return SessionExercise(
            id: 'ex_${timestamp}_${e.key}',
            name: e.value,
            variation: variation,
            order: e.key,
            isTemplate: event.planId != null,
            sets: [
              ExerciseSet(
                id: 'set_${timestamp}_ex${e.key}_s1',
                setNumber: 1,
                segments: [
                  SetSegment(
                    id: 'seg_${timestamp}_ex${e.key}_s1_0',
                    weight: 0.0,
                    repsFrom: 1,
                    repsTo: 12,
                    segmentOrder: 0,
                    notes: '',
                  ),
                ],
              ),
            ],
          );
        },
      ).toList();

      final session = WorkoutSession(
        id: generatedId,
        userId: event.userId,
        planId: event.planId,
        planName: event.planName,
        workoutDate: workoutDate,
        startedAt: now,
        exercises: exercises,
        createdAt: now,
        updatedAt: now,
      );

      AppLogger.debug(_tag,
          'SessionStarted: planName=${event.planName}, session.planName=${session.planName}');

      // Load history and PRs in parallel for better performance
      final historyFutures = <Future<void>>[];

      final previousSessions = <String, WorkoutSession>{};
      final exercisePRs = <String, PersonalRecord>{};

      for (int i = 0; i < event.exerciseNames.length; i++) {
        final name = event.exerciseNames[i];
        final variation = (event.exerciseVariations != null &&
                i < event.exerciseVariations!.length)
            ? event.exerciseVariations![i]
            : '';
        final statsKey = '$name:$variation'.toLowerCase();

        historyFutures.add(
          _workoutRepository
              .getLastExerciseLog(
                  userId: event.userId,
                  exerciseName: name,
                  exerciseVariation: variation)
              .then((lastLog) {
            if (lastLog != null) previousSessions[statsKey] = lastLog;
          }),
        );

        historyFutures.add(
          _workoutRepository
              .getExercisePR(
                  userId: event.userId,
                  exerciseName: name,
                  exerciseVariation: variation)
              .then((pr) {
            if (pr != null) exercisePRs[statsKey] = pr;
          }),
        );
      }

      await Future.wait(historyFutures);

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

  void _updateSessionState(
    Emitter<SessionState> emit,
    List<SessionExercise> Function(List<SessionExercise>) updateFn, {
    int? focusedExerciseIndex,
    int? focusedSetIndex,
    int? focusedSegmentIndex,
  }) {
    if (state is! SessionInProgress) return;
    final currentState = state as SessionInProgress;

    final updatedExercises = updateFn(
      List<SessionExercise>.from(currentState.session.exercises),
    );

    final updatedSession = currentState.session.copyWith(
      exercises: updatedExercises,
      updatedAt: DateTime.now(),
    );

    if (focusedExerciseIndex != null) {
      emit(
        SessionInProgress.withFocus(
          session: updatedSession,
          previousSessions: currentState.previousSessions,
          exercisePRs: currentState.exercisePRs,
          focusedExerciseIndex: focusedExerciseIndex,
          focusedSetIndex: focusedSetIndex,
          focusedSegmentIndex: focusedSegmentIndex,
          timestamp: DateTime.now().millisecondsSinceEpoch,
        ),
      );
    } else {
      emit(
        SessionInProgress(
          session: updatedSession,
          previousSessions: currentState.previousSessions,
          exercisePRs: currentState.exercisePRs,
        ),
      );
    }
  }

  Future<void> _onExerciseAdded(
    SessionExerciseAdded event,
    Emitter<SessionState> emit,
  ) async {
    if (state is! SessionInProgress) return;
    // final currentState = state as SessionInProgress; // Unused

    // 1. Add exercise to session state
    _updateSessionState(emit, (exercises) {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final newExerciseIndex = exercises.length;

      final newExercise = SessionExercise(
        id: 'ex_${timestamp}_$newExerciseIndex',
        name: event.exerciseName,
        variation: event.exerciseVariation,
        order: newExerciseIndex,
        isTemplate: false,
        sets: [
          ExerciseSet(
            id: 'set_${timestamp}_ex${newExerciseIndex}_s1',
            setNumber: 1,
            segments: [
              SetSegment(
                id: 'seg_${timestamp}_ex${newExerciseIndex}_s1_0',
                weight: 0.0,
                repsFrom: 1,
                repsTo: 12,
                segmentOrder: 0,
                notes: '',
              ),
            ],
          ),
        ],
      );

      return [...exercises, newExercise];
    });

    // 2. Load history and PR for the new exercise
    if (state is! SessionInProgress) return;
    final session = (state as SessionInProgress).session;
    await _loadStatsAndEmit(
      name: event.exerciseName,
      variation: event.exerciseVariation,
      userId: session.userId,
      emit: emit,
    );
  }

  Future<void> _onExerciseRemoved(
    SessionExerciseRemoved event,
    Emitter<SessionState> emit,
  ) async {
    _updateSessionState(emit, (exercises) {
      if (event.exerciseIndex < exercises.length) {
        final updatedExercises = List<SessionExercise>.from(exercises);
        updatedExercises.removeAt(event.exerciseIndex);

        // Re-number remaining exercises order property
        for (int i = 0; i < updatedExercises.length; i++) {
          updatedExercises[i] = updatedExercises[i].copyWith(order: i);
        }

        return updatedExercises;
      }
      return exercises;
    });
  }

  Future<void> _onExerciseNameUpdated(
    SessionExerciseNameUpdated event,
    Emitter<SessionState> emit,
  ) async {
    // 1. Update name and variation locally
    _updateSessionState(emit, (exercises) {
      if (event.exerciseIndex < exercises.length) {
        final exercise = exercises[event.exerciseIndex];
        exercises[event.exerciseIndex] = exercise.copyWith(
          name: event.newName,
          variation: event.newVariation ?? exercise.variation,
        );
      }
      return exercises;
    });

    // 2. Load history and PR for the updated exercise
    if (state is! SessionInProgress) return;
    final session = (state as SessionInProgress).session;
    if (event.exerciseIndex >= session.exercises.length) return;
    final updatedExercise = session.exercises[event.exerciseIndex];
    await _loadStatsAndEmit(
      name: updatedExercise.name,
      variation: updatedExercise.variation,
      userId: session.userId,
      emit: emit,
    );
  }

  Future<void> _onExerciseVariationUpdated(
    SessionExerciseVariationUpdated event,
    Emitter<SessionState> emit,
  ) async {
    // 1. Update variation locally
    _updateSessionState(emit, (exercises) {
      if (event.exerciseIndex < exercises.length) {
        final exercise = exercises[event.exerciseIndex];
        exercises[event.exerciseIndex] =
            exercise.copyWith(variation: event.newVariation);
      }
      return exercises;
    });

    // 2. Load history and PR for the updated variation
    if (state is! SessionInProgress) return;
    final session = (state as SessionInProgress).session;
    if (event.exerciseIndex >= session.exercises.length) return;
    final updatedExercise = session.exercises[event.exerciseIndex];
    await _loadStatsAndEmit(
      name: updatedExercise.name,
      variation: updatedExercise.variation,
      userId: session.userId,
      emit: emit,
    );
  }

  Future<void> _onExerciseNotesUpdated(
    SessionExerciseNotesUpdated event,
    Emitter<SessionState> emit,
  ) async {
    _updateSessionState(emit, (exercises) {
      if (event.exerciseIndex < exercises.length) {
        final exercise = exercises[event.exerciseIndex];
        exercises[event.exerciseIndex] =
            exercise.copyWith(notes: event.newNotes);
      }
      return exercises;
    });
  }

  /// Loads the last exercise log + PR in parallel and emits an updated
  /// [SessionInProgress] state. Shared by [_onExerciseAdded],
  /// [_onExerciseNameUpdated], and [_onExerciseVariationUpdated].
  Future<void> _loadStatsAndEmit({
    required String name,
    required String variation,
    required String userId,
    required Emitter<SessionState> emit,
  }) async {
    final statsKey = '$name:$variation'.toLowerCase();
    final results = await Future.wait([
      _workoutRepository.getLastExerciseLog(
        userId: userId,
        exerciseName: name,
        exerciseVariation: variation,
      ),
      _workoutRepository.getExercisePR(
        userId: userId,
        exerciseName: name,
        exerciseVariation: variation,
      ),
    ]);

    if (state is! SessionInProgress) return;
    final currentState = state as SessionInProgress;
    final updatedPreviousSessions =
        Map<String, WorkoutSession>.from(currentState.previousSessions);
    final updatedExercisePRs =
        Map<String, PersonalRecord>.from(currentState.exercisePRs);

    if (results[0] != null) {
      updatedPreviousSessions[statsKey] = results[0] as WorkoutSession;
    }
    if (results[1] != null) {
      updatedExercisePRs[statsKey] = results[1] as PersonalRecord;
    }
    emit(currentState.copyWith(
      previousSessions: updatedPreviousSessions,
      exercisePRs: updatedExercisePRs,
    ));
  }

  Future<void> _onExerciseSkipToggled(
    SessionExerciseSkipToggled event,
    Emitter<SessionState> emit,
  ) async {
    _updateSessionState(emit, (exercises) {
      if (event.exerciseIndex < exercises.length) {
        final exercise = exercises[event.exerciseIndex];
        exercises[event.exerciseIndex] = exercise.copyWith(
          skipped: !exercise.skipped,
        );
      }
      return exercises;
    });
  }

  Future<void> _onSetAdded(
    SessionSetAdded event,
    Emitter<SessionState> emit,
  ) async {
    if (state is! SessionInProgress) return;
    final currentState = state as SessionInProgress;

    // Calculate focus indices BEFORE calling _updateSessionState
    final exercises = currentState.session.exercises;
    if (event.exerciseIndex >= exercises.length) return;

    final exercise = exercises[event.exerciseIndex];
    final focusedSetIndex =
        exercise.sets.length; // This will be the index of the new set
    const focusedSegmentIndex = 0;

    _updateSessionState(
      emit,
      (exercises) {
        final exercise = exercises[event.exerciseIndex];
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final setNumber = exercise.sets.length + 1;
        // Auto-fill notes from previous set
        String initialNotes = '';
        if (exercise.sets.isNotEmpty) {
          final previousSet = exercise.sets.last;
          if (previousSet.segments.isNotEmpty) {
            initialNotes = previousSet.segments.first.notes;
          }
        }

        final newSet = ExerciseSet(
          id: 'set_${timestamp}_ex${event.exerciseIndex}_s$setNumber',
          segments: [
            SetSegment(
              id: 'seg_${timestamp}_ex${event.exerciseIndex}_s${setNumber}_0',
              weight: 0.0,
              repsFrom: 1,
              repsTo: 12,
              notes: initialNotes,
              segmentOrder: 0,
            ),
          ],
          setNumber: setNumber,
        );

        final updatedSets = [...exercise.sets, newSet];
        exercises[event.exerciseIndex] = exercise.copyWith(sets: updatedSets);
        return exercises;
      },
      focusedExerciseIndex: event.exerciseIndex,
      focusedSetIndex: focusedSetIndex,
      focusedSegmentIndex: focusedSegmentIndex,
    );
  }

  Future<void> _onSetRemoved(
    SessionSetRemoved event,
    Emitter<SessionState> emit,
  ) async {
    _updateSessionState(emit, (exercises) {
      if (event.exerciseIndex < exercises.length) {
        final exercise = exercises[event.exerciseIndex];
        final updatedSets = List<ExerciseSet>.from(exercise.sets);

        if (event.setIndex < updatedSets.length) {
          updatedSets.removeAt(event.setIndex);
          // Reorder set numbers
          for (int i = 0; i < updatedSets.length; i++) {
            updatedSets[i] = updatedSets[i].copyWith(setNumber: i + 1);
          }
          exercises[event.exerciseIndex] = exercise.copyWith(sets: updatedSets);
        }
      }
      return exercises;
    });
  }

  Future<void> _onSegmentAdded(
    SessionSegmentAdded event,
    Emitter<SessionState> emit,
  ) async {
    if (state is! SessionInProgress) return;
    final currentState = state as SessionInProgress;

    // Calculate focus indices BEFORE calling _updateSessionState
    final exercises = currentState.session.exercises;
    if (event.exerciseIndex >= exercises.length) return;

    final exercise = exercises[event.exerciseIndex];
    if (event.setIndex >= exercise.sets.length) return;

    final set = exercise.sets[event.setIndex];
    final focusedSegmentIndex =
        set.segments.length; // This will be the index of the new segment

    _updateSessionState(
      emit,
      (exercises) {
        final exercise = exercises[event.exerciseIndex];
        final sets = List<ExerciseSet>.from(exercise.sets);
        final set = sets[event.setIndex];
        final segmentOrder = set.segments.length;

        // Auto-fill logic: From = Previous To + 1
        int initialRepsFrom = 1;
        int initialRepsTo = 12; // Default fallback

        if (set.segments.isNotEmpty) {
          final previousSegment = set.segments.last;
          initialRepsFrom = previousSegment.repsTo + 1;
          // Ensure To is at least equal to From to pass validation
          if (initialRepsTo < initialRepsFrom) {
            initialRepsTo = initialRepsFrom;
          }
        }

        final newSegment = SetSegment(
          id: 'seg_${DateTime.now().millisecondsSinceEpoch}_ex${event.exerciseIndex}_s${event.setIndex}_seg$segmentOrder',
          weight: 0.0,
          repsFrom: initialRepsFrom,
          repsTo: initialRepsTo,
          segmentOrder: segmentOrder,
          notes: '',
        );

        final updatedSegments = [...set.segments, newSegment];
        sets[event.setIndex] = set.copyWith(segments: updatedSegments);
        exercises[event.exerciseIndex] = exercise.copyWith(sets: sets);
        return exercises;
      },
      focusedExerciseIndex: event.exerciseIndex,
      focusedSetIndex: event.setIndex,
      focusedSegmentIndex: focusedSegmentIndex,
    );
  }

  Future<void> _onSegmentRemoved(
    SessionSegmentRemoved event,
    Emitter<SessionState> emit,
  ) async {
    _updateSessionState(emit, (exercises) {
      if (event.exerciseIndex < exercises.length) {
        final exercise = exercises[event.exerciseIndex];
        final sets = List<ExerciseSet>.from(exercise.sets);

        if (event.setIndex < sets.length) {
          final set = sets[event.setIndex];

          if (event.segmentIndex < set.segments.length) {
            final updatedSegments = List<SetSegment>.from(set.segments);
            updatedSegments.removeAt(event.segmentIndex);

            // Reorder segment orders
            for (int i = 0; i < updatedSegments.length; i++) {
              updatedSegments[i] = updatedSegments[i].copyWith(segmentOrder: i);
            }

            sets[event.setIndex] = set.copyWith(segments: updatedSegments);
            exercises[event.exerciseIndex] = exercise.copyWith(sets: sets);
          }
        }
      }
      return exercises;
    });
  }

  Future<void> _onSegmentUpdated(
    SessionSegmentUpdated event,
    Emitter<SessionState> emit,
  ) async {
    _updateSessionState(emit, (exercises) {
      if (event.exerciseIndex < exercises.length) {
        final exercise = exercises[event.exerciseIndex];
        final sets = List<ExerciseSet>.from(exercise.sets);

        if (event.setIndex < sets.length) {
          final set = sets[event.setIndex];
          final segments = List<SetSegment>.from(set.segments);

          if (event.segmentIndex < segments.length) {
            final targetSegment = segments[event.segmentIndex];
            SetSegment updatedSegment;

            // Handle type casting carefully based on field
            if (event.field == 'weight') {
              updatedSegment = targetSegment.copyWith(
                weight: (event.value as num).toDouble(),
              );
            } else if (event.field == 'repsFrom') {
              updatedSegment = targetSegment.copyWith(
                repsFrom: event.value as int,
              );
            } else if (event.field == 'repsTo') {
              updatedSegment = targetSegment.copyWith(
                repsTo: event.value as int,
              );
            } else if (event.field == 'notes') {
              updatedSegment = targetSegment.copyWith(
                notes: event.value as String,
              );
            } else {
              updatedSegment = targetSegment;
            }

            segments[event.segmentIndex] = updatedSegment;
            sets[event.setIndex] = set.copyWith(segments: segments);

            // Sync exercise-level variation notes with first set's segment notes
            if (event.field == 'notes' && event.setIndex == 0) {
              exercises[event.exerciseIndex] = exercise.copyWith(
                sets: sets,
                notes: event.value as String,
              );
            } else {
              exercises[event.exerciseIndex] = exercise.copyWith(sets: sets);
            }
          }
        }
      }
      return exercises;
    });

    // Variation is set separately via SessionExerciseVariationUpdated event.
    // Segment-level notes are for technique cues only and do not affect stats.
  }

  Future<void> _onDateTimesUpdated(
    SessionDateTimesUpdated event,
    Emitter<SessionState> emit,
  ) async {
    if (state is! SessionInProgress) return;
    final currentState = state as SessionInProgress;

    final updatedSession = currentState.session.copyWith(
      workoutDate: event.workoutDate ?? currentState.session.workoutDate,
      startedAt: event.startedAt,
      endedAt: event.endedAt,
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

  Future<void> _onSessionEnded(
    SessionEnded event,
    Emitter<SessionState> emit,
  ) async {
    if (state is! SessionInProgress) return;

    final currentState = state as SessionInProgress;
    final updatedSession = currentState.session.copyWith(
      endedAt: currentState.session.endedAt ?? DateTime.now(),
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
      // Ensure isDraft is set to false when finishing the workout
      final session = currentState.session.copyWith(isDraft: false);

      // Save workout directly using WorkoutRepository
      final savedSession = await _workoutRepository.createWorkout(
        userId: session.userId,
        workout: session,
      );

      emit(SessionSaved(session: savedSession));

      // Trigger auto-backup (Cloud) in background
      // Fire and forget - don't block the UI
      BackupService().backupIfEnabled();

      // Discard any drafts for this user now that we've finished a session
      _workoutRepository.discardDrafts(userId: session.userId).ignore();
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
      AppLogger.debug(_tag, 'SessionDraftResumed: draftSession.planName=${session.planName}');

      // Load history and PRs in parallel
      final historyFutures = <Future<void>>[];

      final previousSessions = <String, WorkoutSession>{};
      final exercisePRs = <String, PersonalRecord>{};

      for (final ex in session.exercises) {
        final name = ex.name;
        final variation = ex.variation;
        final statsKey = '$name:$variation'.toLowerCase();

        historyFutures.add(
          _workoutRepository
              .getLastExerciseLog(
                  userId: session.userId,
                  exerciseName: name,
                  exerciseVariation: variation)
              .then((lastLog) {
            if (lastLog != null) previousSessions[statsKey] = lastLog;
          }),
        );

        historyFutures.add(
          _workoutRepository
              .getExercisePR(
                  userId: session.userId,
                  exerciseName: name,
                  exerciseVariation: variation)
              .then((pr) {
            if (pr != null) exercisePRs[statsKey] = pr;
          }),
        );
      }

      await Future.wait(historyFutures);

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
      AppLogger.debug(_tag, 'SessionSaveDraftRequested: session.planName=${session.planName}');

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

  Future<void> _onCheckDraftRequested(
    SessionCheckDraftRequested event,
    Emitter<SessionState> emit,
  ) async {
    // Only check if we are not already in a session
    if (state is SessionInProgress) return;

    try {
      final draft = await _workoutRepository.getDraftWorkout(
        userId: event.userId,
      );
      emit(SessionDraftCheckSuccess(draft: draft));
    } catch (e) {
      // If error, just assume no draft or let UI handle it
      emit(SessionError(message: 'Failed to check draft: $e'));
    }
  }

  void _onSessionDiscarded(SessionDiscarded event, Emitter<SessionState> emit) {
    emit(const SessionInitial());
  }

  void _onExercisesReordered(
    SessionExercisesReordered event,
    Emitter<SessionState> emit,
  ) {
    _updateSessionState(emit, (exercises) {
      final updatedExercises = List<SessionExercise>.from(exercises);
      var newIndex = event.newIndex;
      if (event.oldIndex < newIndex) {
        newIndex -= 1;
      }
      final exercise = updatedExercises.removeAt(event.oldIndex);
      updatedExercises.insert(newIndex, exercise);

      // Re-number remaining exercises order property
      for (int i = 0; i < updatedExercises.length; i++) {
        updatedExercises[i] = updatedExercises[i].copyWith(order: i);
      }

      return updatedExercises;
    });
  }
}
