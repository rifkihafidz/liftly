import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../../../core/constants/colors.dart';
import '../../../core/models/workout_session.dart';
import '../../../shared/widgets/app_dialogs.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_state.dart';
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
    final userId = (authState is AuthAuthenticated)
        ? authState.user.id.toString()
        : '1';

    // Reset bloc state first by emitting Loading, then trigger SessionStarted
    final bloc = context.read<SessionBloc>();
    bloc.add(SessionStarted(planId: null, exerciseNames: [], userId: userId));
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
                    },
                  ],
                },
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
        body: BlocListener<SessionBloc, SessionState>(
          listenWhen: (previous, current) => current is SessionSaved,
          listener: (context, state) {
            if (state is SessionSaved) {
              AppDialogs.showSuccessDialog(
                context: context,
                title: 'Berhasil',
                message: 'Workout berhasil disimpan.',
                onConfirm: () {
                  // Pop to StartWorkoutPage
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  }
                  // Then navigate to WorkoutDetailPage
                  if (mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => WorkoutDetailPage(
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
              // Update _editedSession only if number of exercises changed
              final currentCount =
                  (_editedSession['exercises'] as List<dynamic>? ?? []).length;
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
                                    child: _DateTimeInput(
                                      label: 'Started At',
                                      dateTime: _editedSession['startedAt']
                                          as DateTime?,
                                      onTap: () async {
                                        final result = await showDialog<
                                            Map<String, DateTime?>>(
                                          context: context,
                                          builder: (context) =>
                                              _WorkoutDateTimeDialog(
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
                                    child: _DateTimeInput(
                                      label: 'Ended At',
                                      dateTime:
                                          _editedSession['endedAt']
                                          as DateTime?,
                                      onTap: () async {
                                        final result = await showDialog<
                                            Map<String, DateTime?>>(
                                          context: context,
                                          builder: (context) =>
                                              _WorkoutDateTimeDialog(
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

                            final updatedSession = WorkoutSession(
                              id:
                                  widget.planId ??
                                  'session_${DateTime.now().millisecondsSinceEpoch}',
                              userId: (state)
                                  .session
                                  .userId, // Get from current session state
                              planId: _editedSession['planId'] as String?,
                              workoutDate:
                                  _editedSession['workoutDate'] as DateTime? ??
                                  DateTime.now(),
                              startedAt: _editedSession['startedAt'] as DateTime?,
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
                              Future.delayed(
                                const Duration(milliseconds: 100),
                                () {
                                  if (mounted && context.mounted) {
                                    context.read<SessionBloc>().add(
                                      const SessionSaveRequested(),
                                    );
                                  }
                                },
                              );
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

class _DateTimeInput extends StatelessWidget {
  final String label;
  final DateTime? dateTime;
  final VoidCallback onTap;

  const _DateTimeInput({
    required this.label,
    required this.dateTime,
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
              dateTime != null
                  ? DateFormat('d MMM y, HH:mm', 'id_ID').format(dateTime!)
                  : 'Not set',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: dateTime == null
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
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
            if (widget.onDeleteTap != null)
              GestureDetector(
                onTap: widget.onDeleteTap,
                child: Padding(
                  padding: const EdgeInsets.only(right: 0),
                  child: Icon(Icons.close, size: 14, color: AppColors.error),
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

class _WorkoutDateTimeDialog extends StatefulWidget {
  final DateTime initialWorkoutDate;
  final DateTime? initialStartedAt;
  final DateTime? initialEndedAt;

  const _WorkoutDateTimeDialog({
    required this.initialWorkoutDate,
    required this.initialStartedAt,
    required this.initialEndedAt,
  });

  @override
  State<_WorkoutDateTimeDialog> createState() => _WorkoutDateTimeDialogState();
}

class _WorkoutDateTimeDialogState extends State<_WorkoutDateTimeDialog> {
  late DateTime selectedDate;
  late TimeOfDay startTime;
  late TimeOfDay endTime;

  @override
  void initState() {
    super.initState();
    selectedDate = widget.initialWorkoutDate;
    startTime = widget.initialStartedAt != null
        ? TimeOfDay.fromDateTime(widget.initialStartedAt!)
        : TimeOfDay.now();
    // endTime is +1 hour from startTime
    final endDateTime = DateTime.now().add(const Duration(hours: 1));
    endTime = widget.initialEndedAt != null
        ? TimeOfDay.fromDateTime(widget.initialEndedAt!)
        : TimeOfDay.fromDateTime(endDateTime);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Set Workout Time',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 20),
            // Date Picker
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.inputBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.borderDark),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Workout Date',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setState(() {
                          selectedDate = picked;
                        });
                      }
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          DateFormat('d MMMM y', 'id_ID').format(selectedDate),
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w500),
                        ),
                        Icon(Icons.calendar_today,
                            size: 20, color: AppColors.accent),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Start Time Picker
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.inputBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.borderDark),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Started At',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: startTime,
                      );
                      if (picked != null) {
                        setState(() {
                          startTime = picked;
                        });
                      }
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          startTime.format(context),
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                        Icon(Icons.access_time,
                            size: 20, color: AppColors.accent),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // End Time Picker
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.inputBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.borderDark),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ended At',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: endTime,
                      );
                      if (picked != null) {
                        setState(() {
                          endTime = picked;
                        });
                      }
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          endTime.format(context),
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                        Icon(Icons.access_time,
                            size: 20, color: AppColors.accent),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      final result = {
                        'workoutDate': selectedDate,
                        'startedAt': DateTime(
                          selectedDate.year,
                          selectedDate.month,
                          selectedDate.day,
                          startTime.hour,
                          startTime.minute,
                        ),
                        'endedAt': DateTime(
                          selectedDate.year,
                          selectedDate.month,
                          selectedDate.day,
                          endTime.hour,
                          endTime.minute,
                        ),
                      };
                      Navigator.pop(context, result);
                    },
                    child: const Text('Save'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
