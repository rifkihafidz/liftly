import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../../../core/constants/colors.dart';
import '../../../core/models/workout_session.dart';
import '../../../shared/widgets/app_dialogs.dart';
import '../../../shared/widgets/workout_form_widgets.dart';
import '../../workout_log/pages/workout_detail_page.dart';
import '../bloc/session_bloc.dart';
import '../bloc/session_event.dart';
import '../bloc/session_state.dart';

class SessionPage extends StatefulWidget {
  final List<String> exerciseNames;
  final String? planId;

  const SessionPage({super.key, required this.exerciseNames, this.planId});

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
    
    // Start session with actual exercises
    final bloc = context.read<SessionBloc>();
    const userId = '1'; // Default local user ID
    bloc.add(
      SessionStarted(
        planId: widget.planId,
        exerciseNames: widget.exerciseNames,
        userId: userId,
      ),
    );
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
            title: const Text('Leave Workout?'),
            content: const Text('Your current workout progress will be lost.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Continue'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  Navigator.pop(context);
                },
                child: const Text('Leave'),
              ),
            ],
          ),
        );
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Log Workout'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
        body: BlocListener<SessionBloc, SessionState>(
          listenWhen: (previous, current) => current is SessionSaved,
          listener: (context, state) {
            if (state is SessionSaved) {
              AppDialogs.showSuccessDialog(
                context: context,
                title: 'Berhasil',
                message: 'Workout berhasil disimpan.',
                onConfirm: () {
                  if (mounted) {
                    // Pop the dialog first
                    Navigator.pop(context);
                    
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
                              'id': 'set_${DateTime.now().millisecondsSinceEpoch}_${ex.id}',
                              'setNumber': 1,
                              'segments': [
                                {
                                  'id': 'seg_${DateTime.now().millisecondsSinceEpoch}_${ex.id}_0',
                                  'weight': 0.0,
                                  'repsFrom': 1,
                                  'repsTo': 12,
                                  'notes': '',
                                  'segmentOrder': 0,
                                },
                              ],
                            },
                          ]
                        : ex.sets
                            .map((set) {
                              return {
                                'id': set.id,
                                'setNumber': set.setNumber,
                                'segments': set.segments
                                    .map((seg) {
                                      return {
                                        'id': seg.id,
                                        'weight': seg.weight,
                                        'repsFrom': seg.repsFrom,
                                        'repsTo': seg.repsTo,
                                        'notes': seg.notes,
                                        'segmentOrder': seg.segmentOrder,
                                      };
                                    })
                                    .toList(),
                              };
                            })
                            .toList();

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
                                      dateTime: _editedSession['startedAt']
                                          as DateTime?,
                                      onTap: () async {
                                        final result = await showDialog<
                                            Map<String, DateTime?>>(
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
                                        final result = await showDialog<
                                            Map<String, DateTime?>>(
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
                        final exercise = entry.value as Map<String, dynamic>;
                        final sets = (exercise['sets'] as List<dynamic>? ?? []);

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Card(
                            color: AppColors.cardBg,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          exercise['name'] as String,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            exercise['skipped'] =
                                                !(exercise['skipped']
                                                        as bool? ??
                                                    false);
                                          });
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: exercise['skipped'] == true
                                                ? AppColors.accent.withValues(
                                                    alpha: 0.2,
                                                  )
                                                : AppColors.inputBg,
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                            border: Border.all(
                                              color: exercise['skipped'] == true
                                                  ? AppColors.accent
                                                  : AppColors.borderLight,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                exercise['skipped'] == true
                                                    ? Icons.check_box
                                                    : Icons
                                                          .check_box_outline_blank,
                                                size: 14,
                                                color:
                                                    exercise['skipped'] == true
                                                    ? AppColors.accent
                                                    : AppColors.textSecondary,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                exercise['skipped'] == true
                                                    ? 'Skipped'
                                                    : 'Skip',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .labelSmall
                                                    ?.copyWith(
                                                      color:
                                                          exercise['skipped'] ==
                                                              true
                                                          ? AppColors.accent
                                                          : AppColors
                                                                .textSecondary,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (!(exercise['skipped'] as bool? ??
                                      false)) ...[
                                    const SizedBox(height: 16),
                                    if (sets.isNotEmpty)
                                      ...List.generate(sets.length, (setIndex) {
                                        final set =
                                            sets[setIndex]
                                                as Map<String, dynamic>;
                                        final segments =
                                            (set['segments']
                                                as List<dynamic>? ??
                                            []);

                                        return Column(
                                          key: ValueKey(set['id']),
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            if (setIndex > 0)
                                              const Divider(height: 12),
                                            Row(
                                              children: [
                                                Text(
                                                  'Set ${set['setNumber']}',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodyMedium
                                                      ?.copyWith(
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: AppColors.accent,
                                                      ),
                                                ),
                                                const SizedBox(width: 8),
                                                if (segments.length > 1)
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 6,
                                                          vertical: 2,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: AppColors.accent
                                                          .withValues(
                                                            alpha: 0.1,
                                                          ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            4,
                                                          ),
                                                    ),
                                                    child: Text(
                                                      'Drop Set',
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .labelSmall
                                                          ?.copyWith(
                                                            color: AppColors
                                                                .accent,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            fontSize: 10,
                                                          ),
                                                    ),
                                                  ),
                                                const Spacer(),
                                                if (setIndex > 0) ...[
                                                  IconButton(
                                                    onPressed: () {
                                                      setState(() {
                                                        sets.removeAt(setIndex);
                                                        for (
                                                          int i = 0;
                                                          i < sets.length;
                                                          i++
                                                        ) {
                                                          sets[i]['setNumber'] =
                                                              i + 1;
                                                        }
                                                      });
                                                    },
                                                    icon: Icon(
                                                      Icons.delete_outline,
                                                      size: 20,
                                                    ),
                                                    color: AppColors.error,
                                                    tooltip: 'Remove Set',
                                                    constraints:
                                                        const BoxConstraints.tightFor(
                                                          width: 32,
                                                          height: 32,
                                                        ),
                                                    padding: EdgeInsets.zero,
                                                  ),
                                                ],
                                              ],
                                            ),
                                            const SizedBox(height: 12),
                                            ...List.generate(segments.length, (
                                              segIndex,
                                            ) {
                                              final segment =
                                                  segments[segIndex]
                                                      as Map<String, dynamic>;
                                              return Padding(
                                                padding: const EdgeInsets.only(
                                                  bottom: 12,
                                                ),
                                                child: Row(
                                                  children: [
                                                    Expanded(
                                                      flex: 2,
                                                      child: WeightField(
                                                        initialValue:
                                                            segment['weight']
                                                                .toString(),
                                                        onChanged: (v) => setState(
                                                          () => segment['weight'] =
                                                              double.tryParse(
                                                                v,
                                                              ) ??
                                                              0,
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Expanded(
                                                      child: NumberField(
                                                        label: 'From',
                                                        initialValue:
                                                            segment['repsFrom']
                                                                .toString(),
                                                        onChanged: (v) => setState(
                                                          () =>
                                                              segment['repsFrom'] =
                                                                  int.tryParse(
                                                                    v,
                                                                  ) ??
                                                                  0,
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Expanded(
                                                      child: ToField(
                                                        initialValue:
                                                            segment['repsTo']
                                                                .toString(),
                                                        onChanged: (v) => setState(
                                                          () =>
                                                              segment['repsTo'] =
                                                                  int.tryParse(
                                                                    v,
                                                                  ) ??
                                                                  0,
                                                        ),
                                                        onDeleteTap:
                                                            segments.length >
                                                                    1 &&
                                                                segIndex > 0
                                                            ? () {
                                                                setState(() {
                                                                  segments
                                                                      .removeAt(
                                                                        segIndex,
                                                                      );
                                                                  // Update
                                                                  // segment
                                                                  // order
                                                                  for (
                                                                    int i = 0;
                                                                    i <
                                                                        segments
                                                                            .length;
                                                                    i++
                                                                  ) {
                                                                    segments[i]['segmentOrder'] =
                                                                        i;
                                                                  }
                                                                });
                                                              }
                                                            : null,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            }),
                                            const SizedBox(height: 12),
                                            if (segments.isNotEmpty)
                                              NotesField(
                                                initialValue:
                                                    segments[0]['notes']
                                                        .toString(),
                                                onChanged: (v) => setState(
                                                  () =>
                                                      segments[0]['notes'] = v,
                                                ),
                                              )
                                            else
                                              NotesField(
                                                initialValue: '',
                                                onChanged: (_) {},
                                              ),
                                            const SizedBox(height: 12),
                                            if (setIndex == sets.length - 1)
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: ElevatedButton.icon(
                                                      onPressed: () {
                                                        setState(() {
                                                          final newSet = {
                                                            'id':
                                                                'set_${DateTime.now().millisecondsSinceEpoch}',
                                                            'setNumber':
                                                                sets.length + 1,
                                                            'segments': [
                                                              {
                                                                'weight': 0.0,
                                                                'repsFrom': 1,
                                                                'repsTo': 12,
                                                                'notes': '',
                                                                'segmentOrder':
                                                                    0,
                                                              },
                                                            ],
                                                          };
                                                          sets.add(newSet);
                                                        });
                                                      },
                                                      icon: const Icon(
                                                        Icons.add,
                                                        size: 16,
                                                      ),
                                                      label: const Text(
                                                        'Add Set',
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: ElevatedButton.icon(
                                                      onPressed: () {
                                                        setState(() {
                                                          if (segments
                                                              .isNotEmpty) {
                                                            final newSegment = {
                                                              'weight': 0.0,
                                                              'repsFrom': 1,
                                                              'repsTo': 12,
                                                              'notes': '',
                                                              'segmentOrder':
                                                                  segments
                                                                      .length,
                                                            };
                                                            segments.add(
                                                              newSegment,
                                                            );
                                                          }
                                                        });
                                                      },
                                                      icon: const Icon(
                                                        Icons.add,
                                                        size: 16,
                                                      ),
                                                      label: const Text(
                                                        'Add Drop Set',
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                          ],
                                        );
                                      }),
                                  ],
                                ],
                              ),
                            ),
                          ),
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
                              final isSkipped = ex['skipped'] as bool? ?? false;
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
                                      (set['segments'] as List<dynamic>? ?? []);
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
                                        weight: seg['weight'] as double? ?? 0.0,
                                        repsFrom: seg['repsFrom'] as int? ?? 0,
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
                              startedAt: _editedSession['startedAt'] as DateTime?,
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
                  title: 'Terjadi Kesalahan',
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
}

