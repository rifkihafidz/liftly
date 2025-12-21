import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/colors.dart';
import '../../../core/models/workout_session.dart';
import '../bloc/session_bloc.dart';
import '../bloc/session_event.dart';
import '../bloc/session_state.dart';

String _formatNumber(double number) {
  final formatter = NumberFormat('#,##0.#', 'id_ID');
  return formatter.format(number).replaceAll(',', '.');
}

class SessionPage extends StatefulWidget {
  final List<String> exerciseNames;
  final String? planId;

  const SessionPage({
    super.key,
    required this.exerciseNames,
    this.planId,
  });

  @override
  State<SessionPage> createState() => _SessionPageState();
}

class _SessionPageState extends State<SessionPage> {
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  @override
  void initState() {
    super.initState();
    
    context.read<SessionBloc>().add(
      SessionStarted(
        planId: widget.planId,
        exerciseNames: widget.exerciseNames,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Log Workout'),
      ),
      body: BlocListener<SessionBloc, SessionState>(
        listener: (context, state) {
          if (state is SessionSaved) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Workout saved successfully!')),
            );
            Navigator.of(context).pop();
          }
          if (state is SessionError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        child: BlocBuilder<SessionBloc, SessionState>(
          builder: (context, state) {
            if (state is SessionLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is SessionInProgress) {
              return SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Time inputs
                      _TimeInputSection(
                        startTime: _startTime,
                        endTime: _endTime,
                        onStartTimeChanged: (time) {
                          setState(() => _startTime = time);
                        },
                        onEndTimeChanged: (time) {
                          setState(() => _endTime = time);
                        },
                      ),
                      const SizedBox(height: 24),
                      ...state.session.exercises.asMap().entries.map((entry) {
                        final index = entry.key;
                        final exercise = entry.value;
                        return _ExerciseCard(
                          index: index,
                          exercise: exercise,
                        );
                      }),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            context.read<SessionBloc>().add(const SessionEnded());
                            context.read<SessionBloc>().add(const SessionSaveRequested());
                          },
                          child: const Text('Finish Workout'),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              );
            }

            return const Center(child: Text('No session'));
          },
        ),
      ),
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  final int index;
  final SessionExercise exercise;

  const _ExerciseCard({
    required this.index,
    required this.exercise,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: exercise.skipped ? 0.6 : 1.0,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: exercise.skipped ? AppColors.borderDark : AppColors.borderLight,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exercise.name,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: exercise.skipped ? AppColors.textSecondary : AppColors.textPrimary,
                          decoration: exercise.skipped ? TextDecoration.lineThrough : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Action buttons row
            Row(
              children: [
                if (!exercise.skipped)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        _showAddSetDialog(context, index, exercise);
                      },
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add Set'),
                    ),
                  ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    if (exercise.skipped) {
                      context.read<SessionBloc>().add(
                        SessionExerciseUnskipped(exerciseIndex: index),
                      );
                    } else {
                      context.read<SessionBloc>().add(
                        SessionExerciseSkipped(exerciseIndex: index),
                      );
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: exercise.skipped ? AppColors.success : AppColors.inputBg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: exercise.skipped ? AppColors.success : AppColors.borderDark,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          exercise.skipped ? Icons.check_circle : Icons.radio_button_unchecked,
                          color: exercise.skipped ? Colors.white : AppColors.textSecondary,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          exercise.skipped ? 'Done' : 'Skip',
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: exercise.skipped ? Colors.white : AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (!exercise.skipped) ...[
              const SizedBox(height: 16),
              ...exercise.sets.asMap().entries.map((entry) {
                final setIndex = entry.key;
                final set = entry.value;
                return _SetCard(
                  exerciseIndex: index,
                  setIndex: setIndex,
                  set: set,
                  exercise: exercise,
                );
              }),
            ] else ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    'Exercise Skipped',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showAddSetDialog(BuildContext context, int exerciseIndex, SessionExercise exercise) {
    final weightController = TextEditingController();
    final repsFromController = TextEditingController();
    final repsToController = TextEditingController();
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Add Set'),
            const SizedBox(height: 8),
            Text(
              exercise.name,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: AppColors.accent,
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.cardBg,
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: weightController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Weight (kg)',
                  hintText: '50',
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: repsFromController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Reps From',
                        hintText: '6',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: repsToController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Reps To',
                        hintText: '8',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: notesController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Notes (optional)',
                  hintText: 'e.g., Wide Grip, felt good',
                  alignLabelWithHint: true,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final weight = double.tryParse(weightController.text) ?? 0;
              final repsFrom = int.tryParse(repsFromController.text) ?? 0;
              final repsTo = int.tryParse(repsToController.text) ?? 0;

              if (weight > 0 && repsFrom > 0 && repsTo > 0) {
                context.read<SessionBloc>().add(
                  SessionSetAdded(
                    exerciseIndex: index,
                    weight: weight,
                    repsFrom: repsFrom,
                    repsTo: repsTo,
                    notes: notesController.text,
                  ),
                );
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

class _SetCard extends StatelessWidget {
  final int exerciseIndex;
  final int setIndex;
  final ExerciseSet set;
  final SessionExercise exercise;

  const _SetCard({
    required this.exerciseIndex,
    required this.setIndex,
    required this.set,
    required this.exercise,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.inputBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.borderDark,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Set #${set.setNumber}${set.segments.first.notes.isNotEmpty ? ' (${set.segments.first.notes})' : ''}${set.isDropset ? ' (Dropset)' : ''}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, size: 18),
                    onPressed: () {
                      _showEditSegmentDialog(context, exerciseIndex, setIndex, 0, set.segments[0]);
                    },
                    tooltip: 'Edit',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, size: 18),
                    onPressed: () {
                      context.read<SessionBloc>().add(
                        SessionSetRemoved(
                          exerciseIndex: exerciseIndex,
                          setIndex: setIndex,
                        ),
                      );
                    },
                    tooltip: 'Delete',
                  ),
                ],
              ),
            ],
          ),
          ...set.segments.asMap().entries.map((entry) {
            final segIndex = entry.key;
            final segment = entry.value;
            return _SegmentRow(
              exerciseIndex: exerciseIndex,
              setIndex: setIndex,
              segmentIndex: segIndex,
              segment: segment,
              canDelete: set.segments.length > 1,
            );
          }),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                _showAddDropDialog(context, exerciseIndex, setIndex, exercise);
              },
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add Drop Set'),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddDropDialog(BuildContext context, int exerciseIndex, int setIndex, SessionExercise exercise) {
    final weightController = TextEditingController();
    final repsFromController = TextEditingController();
    final repsToController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Add Drop'),
            const SizedBox(height: 8),
            Text(
              exercise.name,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: AppColors.accent,
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.cardBg,
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: weightController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Weight (kg)',
                  hintText: '40',
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: repsFromController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Reps From',
                        hintText: '8',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: repsToController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Reps To',
                        hintText: '12',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final weight = double.tryParse(weightController.text) ?? 0;
              final repsFrom = int.tryParse(repsFromController.text) ?? 0;
              final repsTo = int.tryParse(repsToController.text) ?? 0;

              if (weight > 0 && repsFrom > 0 && repsTo > 0) {
                context.read<SessionBloc>().add(
                  SessionSegmentAdded(
                    exerciseIndex: exerciseIndex,
                    setIndex: setIndex,
                    weight: weight,
                    repsFrom: repsFrom,
                    repsTo: repsTo,
                  ),
                );
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditSegmentDialog(BuildContext context, int exerciseIndex, int setIndex, int segmentIndex, SetSegment segment) {
    final weightController = TextEditingController(text: segment.weight.toString());
    final repsFromController = TextEditingController(text: segment.repsFrom.toString());
    final repsToController = TextEditingController(text: segment.repsTo.toString());
    final notesController = TextEditingController(text: segment.notes);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Set'),
        backgroundColor: AppColors.cardBg,
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: weightController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Weight (kg)',
                  hintText: '50',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: repsFromController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Reps From',
                  hintText: '10',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: repsToController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Reps To',
                  hintText: '8',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: notesController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Notes (optional)',
                  hintText: 'e.g., Wide Grip, hard',
                  alignLabelWithHint: true,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final weight = double.tryParse(weightController.text) ?? 0;
              final repsFrom = int.tryParse(repsFromController.text) ?? 0;
              final repsTo = int.tryParse(repsToController.text) ?? 0;

              if (weight > 0 && repsFrom > 0 && repsTo > 0) {
                // Update logic would go here
                // For now, we'll just close the dialog
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _SegmentRow extends StatelessWidget {
  final int exerciseIndex;
  final int setIndex;
  final int segmentIndex;
  final SetSegment segment;
  final bool canDelete;

  const _SegmentRow({
    required this.exerciseIndex,
    required this.setIndex,
    required this.segmentIndex,
    required this.segment,
    required this.canDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    '${_formatNumber(segment.weight)}kg × ${segment.repsFrom}-${segment.repsTo} reps',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
              ],
            ),
          ),
          Text(
            'Vol: ${_formatNumber(segment.volume)}kg',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.accent,
            ),
          ),
          if (canDelete)
            IconButton(
              icon: const Icon(Icons.close, size: 16),
              constraints: const BoxConstraints.tightFor(width: 32, height: 32),
              padding: EdgeInsets.zero,
              onPressed: () {
                context.read<SessionBloc>().add(
                  SessionSegmentRemoved(
                    exerciseIndex: exerciseIndex,
                    setIndex: setIndex,
                    segmentIndex: segmentIndex,
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _TimeInputSection extends StatelessWidget {
  final TimeOfDay? startTime;
  final TimeOfDay? endTime;
  final Function(TimeOfDay) onStartTimeChanged;
  final Function(TimeOfDay) onEndTimeChanged;

  const _TimeInputSection({
    required this.startTime,
    required this.endTime,
    required this.onStartTimeChanged,
    required this.onEndTimeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.borderLight,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Workout Time',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                'Optional',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: startTime ?? TimeOfDay.now(),
                    );
                    if (time != null) {
                      onStartTimeChanged(time);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.inputBg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.borderDark,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Start Time',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          startTime?.format(context) ?? 'Not set',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: startTime == null ? AppColors.textSecondary : AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: endTime ?? TimeOfDay.now(),
                    );
                    if (time != null) {
                      onEndTimeChanged(time);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.inputBg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.borderDark,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'End Time',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          endTime?.format(context) ?? 'Not set',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: endTime == null ? AppColors.textSecondary : AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
