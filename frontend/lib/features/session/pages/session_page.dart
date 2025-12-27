import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../../../core/constants/colors.dart';
import '../../../core/models/workout_session.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_state.dart';
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

  @override
  void initState() {
    super.initState();
    // Initialize with empty session to prevent LateInitializationError
    _editedSession = {
      'workoutDate': DateTime.now(),
      'startedAt': null,
      'endedAt': null,
      'planId': null,
      'exercises': [],
    };
    initializeDateFormatting('id_ID');
    // Get userId from auth
    final authState = context.read<AuthBloc>().state;
    final userId = (authState is AuthAuthenticated) ? authState.user.id.toString() : '1';
    
    // Reset bloc state first by emitting Loading, then trigger SessionStarted
    final bloc = context.read<SessionBloc>();
    bloc.add(SessionStarted(
      planId: null,
      exerciseNames: [],
      userId: userId,
    ));
    // Force create new session by triggering SessionStarted with actual exercises
    Future.delayed(const Duration(milliseconds: 100), () {
      bloc.add(
        SessionStarted(
          planId: widget.planId,
          exerciseNames: widget.exerciseNames,
          userId: userId,
        ),
      );
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  Map<String, dynamic> _deepCopySession(WorkoutSession session) {
    return {
      'workoutDate': session.workoutDate,
      'startedAt': null,
      'endedAt': null,
      'planId': session.planId,
      'exercises': session.exercises.map((ex) {
        final sets = ex.sets.isNotEmpty
            ? ex.sets.map((set) {
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
              }).toList()
            : [
                {
                  'id': 'set_${DateTime.now().millisecondsSinceEpoch}',
                  'setNumber': 1,
                  'segments': [
                    {
                      'id': 'seg_${DateTime.now().millisecondsSinceEpoch}',
                      'weight': 0.0,
                      'repsFrom': 1,
                      'repsTo': 12,
                      'notes': '',
                      'segmentOrder': 0,
                    }
                  ],
                }
              ];
        return {
          'name': ex.name,
          'id': ex.id,
          'order': ex.order,
          'skipped': ex.skipped,
          'sets': sets,
        };
      }).toList(),
    };
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
        body: BlocBuilder<SessionBloc, SessionState>(
          builder: (context, state) {
            if (state is SessionLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is SessionInProgress) {
              // Update _editedSession only if number of exercises changed
              final currentCount = (_editedSession['exercises'] as List<dynamic>? ?? []).length;
              if (currentCount != state.session.exercises.length) {
                _editedSession = _deepCopySession(state.session);
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
                                'Workout Date: ${DateFormat('d MMMM y', 'id_ID').format(_editedSession['workoutDate'] as DateTime)}',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: _TimeInput(
                                      label: 'Started At',
                                      time: _editedSession['startedAt'] != null
                                          ? TimeOfDay.fromDateTime(
                                              _editedSession['startedAt']
                                                  as DateTime,
                                            )
                                          : null,
                                      onTap: () async {
                                        final picked = await showTimePicker(
                                          context: context,
                                          initialTime: TimeOfDay.now(),
                                        );
                                        if (picked != null) {
                                          setState(() {
                                            final now =
                                                _editedSession['startedAt']
                                                    as DateTime? ??
                                                DateTime.now();
                                            _editedSession['startedAt'] =
                                                DateTime(
                                                  now.year,
                                                  now.month,
                                                  now.day,
                                                  picked.hour,
                                                  picked.minute,
                                                );
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _TimeInput(
                                      label: 'Ended At',
                                      time: _editedSession['endedAt'] != null
                                          ? TimeOfDay.fromDateTime(
                                              _editedSession['endedAt']
                                                  as DateTime,
                                            )
                                          : null,
                                      onTap: () async {
                                        final picked = await showTimePicker(
                                          context: context,
                                          initialTime: TimeOfDay.now(),
                                        );
                                        if (picked != null) {
                                          setState(() {
                                            final now =
                                                _editedSession['endedAt']
                                                    as DateTime? ??
                                                DateTime.now();
                                            _editedSession['endedAt'] =
                                                DateTime(
                                                  now.year,
                                                  now.month,
                                                  now.day,
                                                  picked.hour,
                                                  picked.minute,
                                                );
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
                                                IconButton(
                                                  onPressed: () {
                                                    setState(() {
                                                      if (sets.length == 1) {
                                                        // If only 1 set, skip the exercise
                                                        exercise['skipped'] = true;
                                                      } else {
                                                        // Remove the set
                                                        sets.removeAt(setIndex);
                                                        // Update set numbers
                                                        for (int i = 0; i < sets.length; i++) {
                                                          sets[i]['setNumber'] = i + 1;
                                                        }
                                                      }
                                                    });
                                                  },
                                                  icon: Icon(
                                                    sets.length == 1 ? Icons.not_interested : Icons.delete_outline,
                                                    size: 20,
                                                  ),
                                                  color: sets.length == 1 ? AppColors.textSecondary : AppColors.error,
                                                  tooltip: sets.length == 1 ? 'Skip Exercise' : 'Remove Set',
                                                  constraints: const BoxConstraints.tightFor(
                                                    width: 32,
                                                    height: 32,
                                                  ),
                                                  padding: EdgeInsets.zero,
                                                ),
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
                                                      child: _WeightField(
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
                                                      child: _NumberField(
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
                                                      child: _ToField(
                                                        initialValue:
                                                            segment['repsTo']
                                                                .toString(),
                                                        onChanged: (v) =>
                                                            setState(
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
                                                                              segIndex);
                                                                      // Update
                                                                      // segment
                                                                      // order
                                                                      for (int i =
                                                                              0;
                                                                          i <
                                                                              segments
                                                                                  .length;
                                                                          i++) {
                                                                        segments[i][
                                                                            'segmentOrder'] =
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
                                              _NotesField(
                                                initialValue:
                                                    segments[0]['notes']
                                                        .toString(),
                                                onChanged: (v) => setState(
                                                  () =>
                                                      segments[0]['notes'] = v,
                                                ),
                                              )
                                            else
                                              _NotesField(
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
                                                            segments
                                                                .add(newSegment);
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
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            // Convert _editedSession back to WorkoutSession and update bloc state
                            final exercises = (_editedSession['exercises'] as List<dynamic>? ?? []);
                            final sessionExercises = exercises.map((ex) {
                              final isSkipped = ex['skipped'] as bool? ?? false;
                              final sets = isSkipped ? [] : (ex['sets'] as List<dynamic>? ?? []);
                              return SessionExercise(
                                id: (ex['id'] as String?) ?? 'ex_${DateTime.now().millisecondsSinceEpoch}',
                                name: ex['name'] as String? ?? '',
                                order: ex['order'] as int? ?? 0,
                                skipped: isSkipped,
                                sets: sets.map((set) {
                                  final segments = (set['segments'] as List<dynamic>? ?? []);
                                  return ExerciseSet(
                                    id: (set['id'] as String?) ?? 'set_${DateTime.now().millisecondsSinceEpoch}',
                                    setNumber: set['setNumber'] as int? ?? 0,
                                    segments: segments.map((seg) {
                                      return SetSegment(
                                        id: (seg['id'] as String?) ?? 'seg_${DateTime.now().millisecondsSinceEpoch}',
                                        weight: seg['weight'] as double? ?? 0.0,
                                        repsFrom: seg['repsFrom'] as int? ?? 0,
                                        repsTo: seg['repsTo'] as int? ?? 0,
                                        segmentOrder: seg['segmentOrder'] as int? ?? 0,
                                        notes: seg['notes'] as String? ?? '',
                                      );
                                    }).toList(),
                                  );
                                }).toList(),
                              );
                            }).toList();

                            final updatedSession = WorkoutSession(
                              id: widget.planId ?? 'session_${DateTime.now().millisecondsSinceEpoch}',
                              userId: 'user_1',
                              planId: _editedSession['planId'] as String?,
                              workoutDate: _editedSession['workoutDate'] as DateTime? ?? DateTime.now(),
                              startedAt: (state).session.startedAt,
                              endedAt: _editedSession['endedAt'] as DateTime?,
                              exercises: sessionExercises,
                              createdAt: DateTime.now(),
                              updatedAt: DateTime.now(),
                            );

                            // First update bloc state, then save
                            context.read<SessionBloc>().add(
                              SessionRecovered(session: updatedSession),
                            );
                            
                            // Give bloc time to update state, then save
                            if (mounted) {
                              Future.delayed(const Duration(milliseconds: 100), () {
                                if (mounted && context.mounted) {
                                  context.read<SessionBloc>().add(
                                    const SessionSaveRequested(),
                                  );
                                }
                              });
                            }
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
              WidgetsBinding.instance.addPostFrameCallback((_) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Workout saved successfully!'),
                    duration: Duration(seconds: 2),
                  ),
                );
                Navigator.pop(context);
              });
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (state is SessionError) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: AppColors.error,
                    duration: const Duration(seconds: 3),
                  ),
                );
              });
              // Return to the InProgress state view
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            return const Center(child: Text('No session'));
          },
        ),
      ),
    );
  }
}

class _TimeInput extends StatelessWidget {
  final String label;
  final TimeOfDay? time;
  final VoidCallback onTap;

  const _TimeInput({
    required this.label,
    required this.time,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.borderDark),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 4),
            Text(
              time?.format(context) ?? 'Not set',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: time == null
                    ? AppColors.textSecondary
                    : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeightField extends StatefulWidget {
  final String initialValue;
  final Function(String) onChanged;

  const _WeightField({required this.initialValue, required this.onChanged});

  @override
  State<_WeightField> createState() => _WeightFieldState();
}

class _WeightFieldState extends State<_WeightField> {
  late TextEditingController controller;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Weight (kg)',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: widget.onChanged,
          decoration: InputDecoration(
            hintText: '50',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 8,
            ),
          ),
        ),
      ],
    );
  }
}

class _NumberField extends StatefulWidget {
  final String label;
  final String initialValue;
  final Function(String) onChanged;

  const _NumberField({
    required this.label,
    required this.initialValue,
    required this.onChanged,
  });

  @override
  State<_NumberField> createState() => _NumberFieldState();
}

class _NumberFieldState extends State<_NumberField> {
  late TextEditingController controller;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          onChanged: widget.onChanged,
          decoration: InputDecoration(
            hintText: widget.label == 'From' ? '6' : '8',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 8,
            ),
          ),
        ),
      ],
    );
  }
}

class _NotesField extends StatefulWidget {
  final String initialValue;
  final Function(String) onChanged;

  const _NotesField({required this.initialValue, required this.onChanged});

  @override
  State<_NotesField> createState() => _NotesFieldState();
}

class _NotesFieldState extends State<_NotesField> {
  late TextEditingController controller;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Notes (Optional)',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          maxLines: 2,
          onChanged: widget.onChanged,
          decoration: InputDecoration(
            hintText: 'Wide grip, feels good, etc.',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 8,
            ),
          ),
        ),
      ],
    );
  }
}

class _ToField extends StatefulWidget {
  final String initialValue;
  final Function(String) onChanged;
  final VoidCallback? onDeleteTap;

  const _ToField({
    required this.initialValue,
    required this.onChanged,
    this.onDeleteTap,
  });

  @override
  State<_ToField> createState() => _ToFieldState();
}

class _ToFieldState extends State<_ToField> {
  late TextEditingController controller;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'To',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            if (widget.onDeleteTap != null)
              GestureDetector(
                onTap: widget.onDeleteTap,
                child: Padding(
                  padding: const EdgeInsets.only(right: 0),
                  child: Icon(
                    Icons.close,
                    size: 14,
                    color: AppColors.error,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          onChanged: widget.onChanged,
          decoration: InputDecoration(
            hintText: '8',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 8,
            ),
          ),
        ),
      ],
    );
  }
}
