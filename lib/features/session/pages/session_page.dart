import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../../../core/constants/colors.dart';
import '../../../core/models/workout_session.dart';
import '../../../shared/widgets/app_dialogs.dart';
import '../../../shared/widgets/workout_form_widgets.dart';
import '../../../shared/widgets/session_exercise_card.dart';
import '../../workout_log/pages/workout_detail_page.dart';
import '../bloc/session_bloc.dart';
import '../bloc/session_event.dart';
import '../bloc/session_state.dart';

class SessionPage extends StatefulWidget {
  final List<String> exerciseNames;
  final String? planId;
  final WorkoutSession? draftSession;

  const SessionPage({
    super.key,
    this.exerciseNames = const [],
    this.planId,
    this.draftSession,
  });

  @override
  State<SessionPage> createState() => _SessionPageState();
}

class _SessionPageState extends State<SessionPage> {
  late Map<String, dynamic> _editedSession;
  bool _sessionInitialized = false;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('id_ID');

    // Start session with actual exercises or resume draft
    final bloc = context.read<SessionBloc>();
    const userId = '1'; // Default local user ID

    if (widget.draftSession != null) {
      bloc.add(SessionDraftResumed(draftSession: widget.draftSession!));
    } else {
      bloc.add(
        SessionStarted(
          planId: widget.planId,
          exerciseNames: widget.exerciseNames,
          userId: userId,
        ),
      );
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        showDialog(
          context: context,
          builder: (dialogContext) => AlertDialog(
            backgroundColor: AppColors.cardBg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text('Unsaved Changes'),
            content: const Text(
              'You have unsaved progress. What would you like to do?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext); // Close dialog
                  Navigator.pop(context); // Close page (Discard)
                },
                style: TextButton.styleFrom(foregroundColor: AppColors.error),
                child: const Text('Discard'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext); // Close dialog
                  context.read<SessionBloc>().add(
                    const SessionSaveDraftRequested(),
                  );
                },
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.accent,
                  textStyle: const TextStyle(fontWeight: FontWeight.bold),
                ),
                child: const Text('Save Draft'),
              ),
            ],
          ),
        );
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.draftSession != null ? 'Resume Workout' : 'Log Workout',
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.class_outlined),
              tooltip: 'Save as Draft',
              onPressed: () async {
                final confirm = await AppDialogs.showConfirmationDialog(
                  context: context,
                  title: 'Save Draft',
                  message:
                      'Save current progress as draft? You can resume it later.',
                  confirmText: 'Save',
                );

                if (confirm == true) {
                  if (context.mounted) {
                    context.read<SessionBloc>().add(
                      const SessionSaveDraftRequested(),
                    );
                  }
                }
              },
            ),
          ],
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
        body: BlocListener<SessionBloc, SessionState>(
          listenWhen: (previous, current) =>
              current is SessionSaved || current is SessionDraftSaved,
          listener: (context, state) {
            if (state is SessionDraftSaved) {
              AppDialogs.showSuccessDialog(
                context: context,
                title: 'Draft Saved',
                message: 'Your workout draft has been saved.',
                onConfirm: () {
                  if (mounted) {
                    Navigator.pop(context); // Pop session page
                  }
                },
              );
            } else if (state is SessionSaved) {
              AppDialogs.showSuccessDialog(
                context: context,
                title: 'Success',
                message: 'Workout saved successfully.',
                onConfirm: () {
                  if (mounted) {
                    // Replace session with detail (smooth transition, no Home flash)
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => WorkoutDetailPage(
                          workout: state.session,
                          fromSession: true,
                        ),
                      ),
                    );
                  }
                },
              );
            }
          },
          child: BlocBuilder<SessionBloc, SessionState>(
            builder: (context, state) {
              if (state is SessionLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (state is SessionSaved) {
                // Don't show anything for SessionSaved - listener handles dialog
                return const SizedBox.shrink();
              }

              if (state is SessionInProgress) {
                // Initialize _editedSession only once from the bloc state
                if (!_sessionInitialized) {
                  final session = state.session;
                  _editedSession = {
                    'workoutDate': session.workoutDate,
                    'startedAt': session.startedAt,
                    'endedAt': session.endedAt,
                    'planId': session.planId,
                    'exercises': session.exercises.map((ex) {
                      // If exercise has no sets, create 1 default set
                      final sets = ex.sets.isEmpty
                          ? [
                              {
                                'id':
                                    'set_${DateTime.now().millisecondsSinceEpoch}_${ex.id}',
                                'setNumber': 1,
                                'segments': [
                                  {
                                    'id':
                                        'seg_${DateTime.now().millisecondsSinceEpoch}_${ex.id}_0',
                                    'weight': 0.0,
                                    'repsFrom': 1,
                                    'repsTo': 12,
                                    'notes': '',
                                    'segmentOrder': 0,
                                  },
                                ],
                              },
                            ]
                          : ex.sets.map((set) {
                              return {
                                'id': set.id,
                                'setNumber': set.setNumber,
                                'segments': set.segments.map((seg) {
                                  return {
                                    'id': seg.id,
                                    'weight': seg.weight,
                                    'repsFrom': seg.repsFrom,
                                    'repsTo': seg.repsTo,
                                    'notes': seg.notes,
                                    'segmentOrder': seg.segmentOrder,
                                  };
                                }).toList(),
                              };
                            }).toList();

                      return {
                        'name': ex.name,
                        'id': ex.id,
                        'order': ex.order,
                        'skipped': ex.skipped,
                        'sets': sets,
                      };
                    }).toList(),
                  };
                  _sessionInitialized = true;
                }

                final exercises =
                    (_editedSession['exercises'] as List<dynamic>? ?? []);

                return SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header with date and times
                        Card(
                          color: AppColors.cardBg,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Workout Date: ${DateFormat('EEEE, dd MMMM yyyy').format(_editedSession['workoutDate'] as DateTime)}',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: DateTimeInput(
                                        label: 'Started At',
                                        dateTime:
                                            _editedSession['startedAt']
                                                as DateTime?,
                                        onTap: () async {
                                          final result =
                                              await showDialog<
                                                Map<String, DateTime?>
                                              >(
                                                context: context,
                                                builder: (context) =>
                                                    WorkoutDateTimeDialog(
                                                      initialWorkoutDate:
                                                          _editedSession['workoutDate']
                                                              as DateTime? ??
                                                          DateTime.now(),
                                                      initialStartedAt:
                                                          _editedSession['startedAt']
                                                              as DateTime?,
                                                      initialEndedAt:
                                                          _editedSession['endedAt']
                                                              as DateTime?,
                                                    ),
                                              );
                                          if (result != null) {
                                            setState(() {
                                              _editedSession['workoutDate'] =
                                                  result['workoutDate'] ??
                                                  _editedSession['workoutDate'];
                                              _editedSession['startedAt'] =
                                                  result['startedAt'];
                                              _editedSession['endedAt'] =
                                                  result['endedAt'];
                                            });
                                          }
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: DateTimeInput(
                                        label: 'Ended At',
                                        dateTime:
                                            _editedSession['endedAt']
                                                as DateTime?,
                                        onTap: () async {
                                          final result =
                                              await showDialog<
                                                Map<String, DateTime?>
                                              >(
                                                context: context,
                                                builder: (context) =>
                                                    WorkoutDateTimeDialog(
                                                      initialWorkoutDate:
                                                          _editedSession['workoutDate']
                                                              as DateTime? ??
                                                          DateTime.now(),
                                                      initialStartedAt:
                                                          _editedSession['startedAt']
                                                              as DateTime?,
                                                      initialEndedAt:
                                                          _editedSession['endedAt']
                                                              as DateTime?,
                                                    ),
                                              );
                                          if (result != null) {
                                            setState(() {
                                              _editedSession['workoutDate'] =
                                                  result['workoutDate'] ??
                                                  _editedSession['workoutDate'];
                                              _editedSession['startedAt'] =
                                                  result['startedAt'];
                                              _editedSession['endedAt'] =
                                                  result['endedAt'];
                                            });
                                          }
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Exercises
                        Text(
                          '${exercises.length} Exercises',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 16),
                        ...exercises.asMap().entries.map((entry) {
                          final exerciseIndex = entry.key;
                          final exercise = entry.value as Map<String, dynamic>;
                          final sets =
                              (exercise['sets'] as List<dynamic>? ?? []);

                          return SessionExerciseCard(
                            exercise: exercise,
                            exerciseIndex: exerciseIndex,
                            history: state.previousSessions[exercise['name']],
                            pr: state.exercisePRs[exercise['name']],
                            onSkipToggle: () {
                              setState(() {
                                exercise['skipped'] =
                                    !(exercise['skipped'] as bool? ?? false);
                              });
                            },
                            onHistoryTap: () {
                              _showExerciseHistory(
                                context,
                                exercise['name'] as String,
                                state.previousSessions[exercise['name']],
                                state.exercisePRs[exercise['name']],
                              );
                            },
                            onAddSet: () {
                              setState(() {
                                final newSet = {
                                  'id':
                                      'set_${DateTime.now().millisecondsSinceEpoch}',
                                  'setNumber': sets.length + 1,
                                  'segments': [
                                    {
                                      'weight': 0.0,
                                      'repsFrom': 1,
                                      'repsTo': 12,
                                      'notes': '',
                                      'segmentOrder': 0,
                                    },
                                  ],
                                };
                                sets.add(newSet);
                              });
                            },
                            onRemoveSet: (setIndex) {
                              setState(() {
                                sets.removeAt(setIndex);
                                for (int i = 0; i < sets.length; i++) {
                                  sets[i]['setNumber'] = i + 1;
                                }
                              });
                            },
                            onAddDropSet: (setIndex) {
                              setState(() {
                                final segments =
                                    (sets[setIndex]['segments']
                                        as List<dynamic>);
                                segments.add({
                                  'weight': 0.0,
                                  'repsFrom': 1,
                                  'repsTo': 12,
                                  'notes': '',
                                  'segmentOrder': segments.length,
                                });
                              });
                            },
                            onRemoveDropSet: (setIndex, segmentIndex) {
                              setState(() {
                                final segments =
                                    (sets[setIndex]['segments']
                                        as List<dynamic>);
                                segments.removeAt(segmentIndex);
                                for (int i = 0; i < segments.length; i++) {
                                  segments[i]['segmentOrder'] = i;
                                }
                              });
                            },
                            onUpdateSegment:
                                (setIndex, segmentIndex, field, value) {
                                  setState(() {
                                    final segments =
                                        (sets[setIndex]['segments']
                                            as List<dynamic>);
                                    segments[segmentIndex][field] = value;
                                  });
                                },
                          );
                        }),
                        const SizedBox(height: 4),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              // Convert _editedSession back to WorkoutSession and update bloc state
                              final exercises =
                                  (_editedSession['exercises']
                                      as List<dynamic>? ??
                                  []);
                              final sessionExercises = exercises.map((ex) {
                                final isSkipped =
                                    ex['skipped'] as bool? ?? false;
                                final sets = isSkipped
                                    ? []
                                    : (ex['sets'] as List<dynamic>? ?? []);
                                return SessionExercise(
                                  id:
                                      (ex['id'] as String?) ??
                                      'ex_${DateTime.now().millisecondsSinceEpoch}',
                                  name: ex['name'] as String? ?? '',
                                  order: ex['order'] as int? ?? 0,
                                  skipped: isSkipped,
                                  sets: sets.map((set) {
                                    final segments =
                                        (set['segments'] as List<dynamic>? ??
                                        []);
                                    return ExerciseSet(
                                      id:
                                          (set['id'] as String?) ??
                                          'set_${DateTime.now().millisecondsSinceEpoch}',
                                      setNumber: set['setNumber'] as int? ?? 0,
                                      segments: segments.map((seg) {
                                        return SetSegment(
                                          id:
                                              (seg['id'] as String?) ??
                                              'seg_${DateTime.now().millisecondsSinceEpoch}',
                                          weight:
                                              seg['weight'] as double? ?? 0.0,
                                          repsFrom:
                                              seg['repsFrom'] as int? ?? 0,
                                          repsTo: seg['repsTo'] as int? ?? 0,
                                          segmentOrder:
                                              seg['segmentOrder'] as int? ?? 0,
                                          notes: seg['notes'] as String? ?? '',
                                        );
                                      }).toList(),
                                    );
                                  }).toList(),
                                );
                              }).toList();

                              final workoutDate =
                                  _editedSession['workoutDate'] as DateTime? ??
                                  DateTime.now();
                              final now = DateTime.now();
                              // Keep the original session ID - don't create a new one!
                              // The session already has a unique ID from when it was started
                              final originalSessionId = (state).session.id;
                              final updatedSession = WorkoutSession(
                                id: originalSessionId,
                                userId: (state)
                                    .session
                                    .userId, // Get from current session state
                                planId: _editedSession['planId'] as String?,
                                workoutDate: workoutDate,
                                startedAt:
                                    _editedSession['startedAt'] as DateTime?,
                                endedAt: _editedSession['endedAt'] as DateTime?,
                                exercises: sessionExercises,
                                createdAt: now,
                                updatedAt: now,
                              );

                              // Update bloc with the final session data, then save
                              context.read<SessionBloc>().add(
                                SessionRecovered(session: updatedSession),
                              );

                              // Give bloc time to update state, then save
                              Future.delayed(
                                const Duration(milliseconds: 50),
                                () {
                                  if (mounted && context.mounted) {
                                    context.read<SessionBloc>().add(
                                      const SessionSaveRequested(),
                                    );
                                  }
                                },
                              );
                            },
                            child: const Text('Finish Workout'),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              if (state is SessionSaved) {
                // Handled by BlocListener above, don't show anything here
                return const SizedBox.shrink();
              }

              if (state is SessionError) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  AppDialogs.showErrorDialog(
                    context: context,
                    title: 'Error Occurred',
                    message: state.message,
                  );
                });
                // Return to the InProgress state view
                return const Center(child: CircularProgressIndicator());
              }

              return const Center(child: Text('No session'));
            },
          ),
        ),
      ),
    );
  }

  void _showExerciseHistory(
    BuildContext context,
    String exerciseName,
    SessionExercise? history,
    SetSegment? pr,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                exerciseName,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              if (history != null) ...[
                Text(
                  'Last Session',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                ...history.sets.map((s) {
                  if (s.segments.isEmpty) return const SizedBox.shrink();
                  final seg = s.segments.first;
                  final weight = seg.weight == seg.weight.toInt()
                      ? seg.weight.toInt()
                      : seg.weight;

                  String reps;
                  if (seg.repsFrom != seg.repsTo && seg.repsTo > 0) {
                    reps = '${seg.repsFrom}-${seg.repsTo}';
                  } else if (seg.repsFrom <= 1 && seg.repsTo > 1) {
                    reps = '${seg.repsTo}';
                  } else {
                    reps = '${seg.repsFrom}';
                  }

                  String notesStr = '';
                  if (seg.notes.isNotEmpty) {
                    notesStr = ' (${seg.notes})';
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 4,
                          height: 4,
                          decoration: const BoxDecoration(
                            color: AppColors.textSecondary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '$weight kg × $reps$notesStr',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 24),
              ],
              if (pr != null) ...[
                Text(
                  'Personal Record (PR)',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.accent,
                  ),
                ),
                const SizedBox(height: 12),
                Builder(
                  builder: (context) {
                    final weight = pr.weight == pr.weight.toInt()
                        ? pr.weight.toInt()
                        : pr.weight;

                    final repsCount = (pr.repsTo > pr.repsFrom)
                        ? pr.repsTo
                        : pr.repsFrom;
                    final reps = '$repsCount';

                    String notesStr = '';
                    if (pr.notes.isNotEmpty) {
                      notesStr = ' (${pr.notes})';
                    }

                    return Row(
                      children: [
                        const Icon(
                          Icons.emoji_events_outlined,
                          size: 20,
                          color: AppColors.accent,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$weight kg - $reps reps$notesStr',
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                color: AppColors.accent,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),
              ],
            ],
          ),
        );
      },
    );
  }
}
