import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/colors.dart';
import '../../../shared/widgets/app_dialogs.dart';
import '../../../shared/widgets/workout_form_widgets.dart';
import '../../../core/models/workout_session.dart';
import '../repositories/workout_repository.dart';
import '../bloc/workout_bloc.dart';
import '../bloc/workout_event.dart';
import '../bloc/workout_state.dart';

class WorkoutEditPage extends StatefulWidget {
  final Map<String, dynamic> workout;

  const WorkoutEditPage({super.key, required this.workout});

  @override
  State<WorkoutEditPage> createState() => _WorkoutEditPageState();
}

class _WorkoutEditPageState extends State<WorkoutEditPage> {
  late Map<String, dynamic> _editedWorkout;
  final _workoutRepository = WorkoutRepository();
  final Map<String, SessionExercise> _previousSessions = {};
  final Map<String, SetSegment> _exercisePRs = {};

  @override
  void initState() {
    super.initState();
    _editedWorkout = _deepCopyWorkout(widget.workout);
    _loadHistoryAndPRs();
  }

  Future<void> _loadHistoryAndPRs() async {
    final exercises = (_editedWorkout['exercises'] as List<dynamic>?) ?? [];
    final userId = '1'; // Default local user ID

    for (final exercise in exercises) {
      final name = exercise['name'] as String;

      // Load Last Log
      final lastLog = await _workoutRepository.getLastExerciseLog(
        userId: userId,
        exerciseName: name,
      );
      if (lastLog != null) {
        if (mounted) {
          setState(() {
            _previousSessions[name] = lastLog;
          });
        }
      }

      // Load PR
      final pr = await _workoutRepository.getExercisePR(
        userId: userId,
        exerciseName: name,
      );
      if (pr != null) {
        if (mounted) {
          setState(() {
            _exercisePRs[name] = pr;
          });
        }
      }
    }
  }

  Map<String, dynamic> _deepCopyWorkout(Map<String, dynamic> original) {
    return {
      ...original,
      'exercises':
          (original['exercises'] as List<dynamic>?)?.map((ex) {
            return {
              ...ex,
              'sets':
                  (ex['sets'] as List<dynamic>?)?.map((set) {
                    return {
                      ...set,
                      'segments':
                          (set['segments'] as List<dynamic>?)?.map((seg) {
                            final segMap = seg as Map<dynamic, dynamic>;
                            return <String, dynamic>{
                              ...segMap.cast<String, dynamic>(),
                            };
                          }).toList() ??
                          [],
                    };
                  }).toList() ??
                  [],
            };
          }).toList() ??
          [],
    };
  }

  void _updateSegment(
    int exIndex,
    int setIndex,
    int segIndex,
    String field,
    dynamic value,
  ) {
    setState(() {
      final exercises = _editedWorkout['exercises'] as List<dynamic>;
      final sets = exercises[exIndex]['sets'] as List<dynamic>;
      final segments = sets[setIndex]['segments'] as List<dynamic>;
      segments[segIndex][field] = value;
    });
  }

  DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) {
      // Try to parse dd-MM-yyyy HH:mm:ss format first
      try {
        final parts = value.split(' ');
        if (parts.length == 2) {
          final dateParts = parts[0].split('-');
          final timeParts = parts[1].split(':');
          return DateTime(
            int.parse(dateParts[2]),
            int.parse(dateParts[1]),
            int.parse(dateParts[0]),
            int.parse(timeParts[0]),
            int.parse(timeParts[1]),
            timeParts.length > 2 ? int.parse(timeParts[2]) : 0,
          );
        }
      } catch (_) {
        // Fall back to DateTime.parse()
      }
      try {
        return DateTime.parse(value);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  String _formatDate(DateTime date) {
    // Format date without requiring locale initialization
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  void _saveChanges() {
    const userId = '1'; // Default local user ID
    final workoutId = _editedWorkout['id'].toString();

    String? formatDate(dynamic dateValue) {
      if (dateValue == null) return null;
      final dt = dateValue is DateTime ? dateValue : _parseDateTime(dateValue);
      if (dt == null) return null;
      // Format as YYYY-MM-DD
      return '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
    }

    String? formatDateTime(dynamic dateValue, String workoutDateStr) {
      if (dateValue == null) return null;

      DateTime dt;
      if (dateValue is DateTime) {
        dt = dateValue;
      } else if (dateValue is String) {
        // If it's just a time string like "15:18:00", combine with workout date
        if (dateValue.length <= 8) {
          // HH:mm:ss format
          final workoutDate = DateTime.parse(workoutDateStr);
          final timeParts = dateValue.split(':');
          dt = DateTime(
            workoutDate.year,
            workoutDate.month,
            workoutDate.day,
            int.parse(timeParts[0]),
            int.parse(timeParts[1]),
            timeParts.length > 2 ? int.parse(timeParts[2]) : 0,
          );
        } else {
          dt = DateTime.parse(dateValue);
        }
      } else {
        return null;
      }

      // Format as dd-MM-yyyy HH:mm:ss (matching SQLiteService format)
      return '${dt.day.toString().padLeft(2, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';
    }

    final workoutDateStr = formatDate(_editedWorkout['workoutDate']) ?? '';
    final workoutDataToSave = <String, dynamic>{
      'id': _editedWorkout['id'],
      'planId': _editedWorkout['planId'],
      'workoutDate': workoutDateStr,
      'startedAt': formatDateTime(_editedWorkout['startedAt'], workoutDateStr),
      'endedAt': formatDateTime(_editedWorkout['endedAt'], workoutDateStr),
    };

    final exercisesToSave = <Map<String, dynamic>>[];
    final originalExercises =
        (_editedWorkout['exercises'] as List<dynamic>?) ?? [];

    for (final exercise in originalExercises) {
      final exMap = exercise as Map<dynamic, dynamic>;

      // Always include exercise 'id' if it exists (preserve existing IDs from database)
      final exId = exMap['id'];

      final setsToSave = <Map<String, dynamic>>[];
      final originalSets = (exMap['sets'] as List<dynamic>?) ?? [];

      for (final set in originalSets) {
        final setMap = set as Map<dynamic, dynamic>;
        final setId = setMap['id'];

        final setToSave = <String, dynamic>{
          if (setId != null) 'id': setId,
          'setNumber': setMap['setNumber'] ?? 1,
        };

        final segmentsToSave = <Map<String, dynamic>>[];
        final originalSegments = (setMap['segments'] as List<dynamic>?) ?? [];

        for (final segment in originalSegments) {
          final segMap = segment as Map<dynamic, dynamic>;
          final segId = segMap['id'];

          segmentsToSave.add({
            if (segId != null) 'id': segId,
            'weight': segMap['weight'] ?? 0,
            'repsFrom': segMap['repsFrom'] ?? 0,
            'repsTo': segMap['repsTo'] ?? 0,
            'segmentOrder': segMap['segmentOrder'] ?? 0,
            'notes': segMap['notes'] ?? '',
          });
        }

        setToSave['segments'] = segmentsToSave;
        setsToSave.add(setToSave);
      }

      exercisesToSave.add({
        if (exId != null) 'id': exId,
        'name': exMap['name'] ?? '',
        'order': exMap['order'] ?? 0,
        'skipped': exMap['skipped'] ?? false,
        'sets': setsToSave,
      });
    }

    workoutDataToSave['exercises'] = exercisesToSave;

    context.read<WorkoutBloc>().add(
      WorkoutUpdated(
        userId: userId,
        workoutId: workoutId,
        workoutData: workoutDataToSave,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final workoutDate =
        _parseDateTime(_editedWorkout['workoutDate'] as String) ??
        DateTime.now();
    final exercises = (_editedWorkout['exercises'] as List<dynamic>?) ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Workout'),
        actions: [
          TextButton.icon(
            onPressed: _saveChanges,
            icon: const Icon(Icons.save),
            label: const Text('Save'),
          ),
        ],
      ),
      body: BlocListener<WorkoutBloc, WorkoutState>(
        listenWhen: (previous, current) {
          // Only listen to state changes, not rebuilds
          return (previous is! WorkoutError || current is! WorkoutError) &&
              (previous is! WorkoutUpdatedSuccess ||
                  current is! WorkoutUpdatedSuccess);
        },
        listener: (context, state) {
          if (state is WorkoutUpdatedSuccess) {
            AppDialogs.showSuccessDialog(
              context: context,
              title: 'Success',
              message: 'Workout updated successfully.',
              onConfirm: () {
                // Dialog sudah di-close oleh button di AppDialogs
                // Tinggal pop edit page kembali ke detail
                Navigator.pop(context, true);
              },
            );
          } else if (state is WorkoutError) {
            AppDialogs.showErrorDialog(
              context: context,
              title: 'Error Occurred',
              message: state.message,
            );
          }
        },
        child: BlocBuilder<WorkoutBloc, WorkoutState>(
          builder: (context, state) {
            if (state is WorkoutLoading) {
              return const Center(child: CircularProgressIndicator());
            }

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
                              'Workout Date: ${_formatDate(workoutDate)}',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: DateTimeInput(
                                    label: 'Started At',
                                    dateTime: _parseDateTime(
                                      _editedWorkout['startedAt'],
                                    ),
                                    onTap: () async {
                                      final result =
                                          await showDialog<
                                            Map<String, DateTime?>
                                          >(
                                            context: context,
                                            builder: (context) =>
                                                WorkoutDateTimeDialog(
                                                  initialWorkoutDate:
                                                      workoutDate,
                                                  initialStartedAt: _parseDateTime(
                                                    _editedWorkout['startedAt'],
                                                  ),
                                                  initialEndedAt: _parseDateTime(
                                                    _editedWorkout['endedAt'],
                                                  ),
                                                ),
                                          );
                                      if (result != null) {
                                        setState(() {
                                          _editedWorkout['startedAt'] =
                                              result['startedAt']
                                                  ?.toIso8601String()
                                                  .split('.')[0];
                                          _editedWorkout['endedAt'] =
                                              result['endedAt']
                                                  ?.toIso8601String()
                                                  .split('.')[0];
                                        });
                                      }
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: DateTimeInput(
                                    label: 'Ended At',
                                    dateTime: _parseDateTime(
                                      _editedWorkout['endedAt'],
                                    ),
                                    onTap: () async {
                                      final result =
                                          await showDialog<
                                            Map<String, DateTime?>
                                          >(
                                            context: context,
                                            builder: (context) =>
                                                WorkoutDateTimeDialog(
                                                  initialWorkoutDate:
                                                      workoutDate,
                                                  initialStartedAt: _parseDateTime(
                                                    _editedWorkout['startedAt'],
                                                  ),
                                                  initialEndedAt: _parseDateTime(
                                                    _editedWorkout['endedAt'],
                                                  ),
                                                ),
                                          );
                                      if (result != null) {
                                        setState(() {
                                          _editedWorkout['startedAt'] =
                                              result['startedAt']
                                                  ?.toIso8601String()
                                                  .split('.')[0];
                                          _editedWorkout['endedAt'] =
                                              result['endedAt']
                                                  ?.toIso8601String()
                                                  .split('.')[0];
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
                    // Exercises section
                    Text(
                      '${exercises.length} Exercises',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...List.generate(exercises.length, (exIndex) {
                      final exercise =
                          (exercises[exIndex] as Map<dynamic, dynamic>)
                              .cast<String, dynamic>();
                      final sets = (exercise['sets'] as List<dynamic>?) ?? [];

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: AppColors.cardBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.borderLight,
                            width: 1,
                          ),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        exercise['name'],
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (_previousSessions.containsKey(
                                      exercise['name'],
                                    ) ||
                                    _exercisePRs.containsKey(exercise['name']))
                                  IconButton(
                                    icon: const Icon(
                                      Icons.history,
                                      size: 20,
                                      color: AppColors.textSecondary,
                                    ),
                                    tooltip: 'View History & PR',
                                    constraints: const BoxConstraints.tightFor(
                                      width: 32,
                                      height: 32,
                                    ),
                                    padding: EdgeInsets.zero,
                                    onPressed: () {
                                      _showExerciseHistory(
                                        context,
                                        exercise['name'],
                                        _previousSessions[exercise['name']],
                                        _exercisePRs[exercise['name']],
                                      );
                                    },
                                  ),
                                const SizedBox(width: 4),
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      final currentSkipped =
                                          exercise['skipped'] == true;
                                      _editedWorkout['exercises'][exIndex]['skipped'] =
                                          !currentSkipped;

                                      // Jika uncheck skipped, reset sets ke 1 set kosong
                                      if (currentSkipped) {
                                        // Clear all existing sets
                                        sets.clear();
                                        // Add 1 default empty set
                                        sets.add({
                                          'setNumber': 1,
                                          'segments': [
                                            {
                                              'weight': 0.0,
                                              'repsFrom': 1,
                                              'repsTo': 12,
                                              'notes': '',
                                            },
                                          ],
                                        });
                                      }
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
                                      borderRadius: BorderRadius.circular(4),
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
                                              : Icons.check_box_outline_blank,
                                          size: 14,
                                          color: exercise['skipped'] == true
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
                                                    exercise['skipped'] == true
                                                    ? AppColors.accent
                                                    : AppColors.textSecondary,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if ((_editedWorkout['exercises'][exIndex]
                                    as Map<dynamic, dynamic>)['skipped'] !=
                                true) ...[
                              const SizedBox(height: 16),
                              ...List.generate(sets.length, (setIndex) {
                                final set =
                                    (sets[setIndex] as Map<dynamic, dynamic>)
                                        .cast<String, dynamic>();
                                final segments =
                                    (set['segments'] as List<dynamic>?) ?? [];

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (setIndex > 0)
                                      const Padding(
                                        padding: EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                        child: Divider(height: 1),
                                      ),
                                    Row(
                                      children: [
                                        Text(
                                          'Set ${set['setNumber']}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.accent,
                                              ),
                                        ),
                                        const SizedBox(width: 8),
                                        if (segments.length > 1)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppColors.accent
                                                  .withValues(alpha: 0.1),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              'Drop Set',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .labelSmall
                                                  ?.copyWith(
                                                    color: AppColors.accent,
                                                    fontWeight: FontWeight.w600,
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
                                                  sets[i]['setNumber'] = i + 1;
                                                }
                                              });
                                            },
                                            icon: const Icon(
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
                                          (segments[segIndex]
                                                  as Map<dynamic, dynamic>)
                                              .cast<String, dynamic>();
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 12,
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              flex: 2,
                                              child: WeightField(
                                                initialValue: segment['weight']
                                                    .toString(),
                                                onChanged: (v) =>
                                                    _updateSegment(
                                                      exIndex,
                                                      setIndex,
                                                      segIndex,
                                                      'weight',
                                                      double.tryParse(v) ?? 0,
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
                                                onChanged: (v) =>
                                                    _updateSegment(
                                                      exIndex,
                                                      setIndex,
                                                      segIndex,
                                                      'repsFrom',
                                                      int.tryParse(v) ?? 0,
                                                    ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: ToField(
                                                initialValue: segment['repsTo']
                                                    .toString(),
                                                onChanged: (v) =>
                                                    _updateSegment(
                                                      exIndex,
                                                      setIndex,
                                                      segIndex,
                                                      'repsTo',
                                                      int.tryParse(v) ?? 0,
                                                    ),
                                                onDeleteTap:
                                                    (segments.length > 1 &&
                                                        segIndex > 0)
                                                    ? () {
                                                        setState(() {
                                                          segments.removeAt(
                                                            segIndex,
                                                          );
                                                          // Update segment order
                                                          for (
                                                            int i = 0;
                                                            i < segments.length;
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
                                        initialValue: segments[0]['notes']
                                            .toString(),
                                        onChanged: (v) => _updateSegment(
                                          exIndex,
                                          setIndex,
                                          0,
                                          'notes',
                                          v,
                                        ),
                                      )
                                    else
                                      NotesField(
                                        initialValue: '',
                                        onChanged: (_) {},
                                      ),
                                    const SizedBox(height: 12),
                                    if (setIndex == sets.length - 1) ...[
                                      // Last set: show both buttons
                                      Row(
                                        children: [
                                          Expanded(
                                            child: ElevatedButton.icon(
                                              onPressed: () {
                                                setState(() {
                                                  final newSet = {
                                                    'setNumber':
                                                        sets.length + 1,
                                                    'segments': [
                                                      {
                                                        'weight': 0.0,
                                                        'repsFrom': 1,
                                                        'repsTo': 12,
                                                        'notes': '',
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
                                                style: TextStyle(fontSize: 12),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: ElevatedButton.icon(
                                              onPressed: () {
                                                setState(() {
                                                  final newSegment = {
                                                    'weight': 0.0,
                                                    'repsFrom': 1,
                                                    'repsTo': 12,
                                                    'notes': '',
                                                  };
                                                  segments.add(newSegment);
                                                });
                                              },
                                              icon: const Icon(
                                                Icons.add,
                                                size: 16,
                                              ),
                                              label: const Text(
                                                'Add Drop Set',
                                                style: TextStyle(fontSize: 12),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ] else ...[
                                      // Not last set: show only Add Drop Set button
                                      Row(
                                        children: [
                                          Expanded(
                                            child: ElevatedButton.icon(
                                              onPressed: () {
                                                setState(() {
                                                  final newSegment = {
                                                    'weight': 0.0,
                                                    'repsFrom': 1,
                                                    'repsTo': 12,
                                                    'notes': '',
                                                  };
                                                  segments.add(newSegment);
                                                });
                                              },
                                              icon: const Icon(
                                                Icons.add,
                                                size: 16,
                                              ),
                                              label: const Text(
                                                'Add Drop Set',
                                                style: TextStyle(fontSize: 12),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                );
                              }),
                            ],
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            );
          },
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

                    String reps;
                    if (pr.repsFrom != pr.repsTo && pr.repsTo > 0) {
                      reps = '${pr.repsFrom}-${pr.repsTo}';
                    } else if (pr.repsFrom <= 1 && pr.repsTo > 1) {
                      reps = '${pr.repsTo}';
                    } else {
                      reps = '${pr.repsFrom}';
                    }

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
                          '$weight kg × $reps$notesStr',
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

class _EditField extends StatefulWidget {
  final String label;
  final dynamic value;
  final Function(String) onChanged;

  const _EditField({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  State<_EditField> createState() => _EditFieldState();
}

class _EditFieldState extends State<_EditField> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value.toString());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      decoration: InputDecoration(
        labelText: widget.label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      keyboardType: TextInputType.number,
      onChanged: widget.onChanged,
    );
  }
}
