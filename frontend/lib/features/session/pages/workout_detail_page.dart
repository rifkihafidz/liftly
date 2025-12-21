import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/colors.dart';
import '../../../core/models/workout_session.dart';

class WorkoutDetailPage extends StatefulWidget {
  final WorkoutSession session;
  final Function(WorkoutSession) onSessionUpdated;
  final VoidCallback onSessionDeleted;

  const WorkoutDetailPage({
    Key? key,
    required this.session,
    required this.onSessionUpdated,
    required this.onSessionDeleted,
  }) : super(key: key);

  @override
  State<WorkoutDetailPage> createState() => _WorkoutDetailPageState();
}

class _WorkoutDetailPageState extends State<WorkoutDetailPage> {
  late WorkoutSession _currentSession;

  @override
  void initState() {
    super.initState();
    _currentSession = widget.session;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Workout Details'),
        actions: [
          PopupMenuButton(
            itemBuilder: (context) => [
              PopupMenuItem(
                child: const Row(
                  children: [
                    Icon(Icons.delete, color: AppColors.error, size: 18),
                    SizedBox(width: 12),
                    Text('Delete Workout'),
                  ],
                ),
                onTap: () {
                  _showDeleteConfirmation(context);
                },
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date & Time
              Container(
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
                    Text(
                      'Workout Date',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      DateFormat('EEEE, MMMM d, yyyy').format(_currentSession.workoutDate),
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    if (_currentSession.startedAt != null || _currentSession.endedAt != null) ...[
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
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
                                  _currentSession.startedAt != null
                                      ? DateFormat('HH:mm').format(_currentSession.startedAt!)
                                      : '-',
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                              ],
                            ),
                          ),
                          Expanded(
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
                                  _currentSession.endedAt != null
                                      ? DateFormat('HH:mm').format(_currentSession.endedAt!)
                                      : '-',
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (_currentSession.duration != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          'Duration',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDuration(_currentSession.duration!),
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColors.accent,
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Exercises
              Text(
                'Exercises',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              ..._currentSession.exercises.asMap().entries.map((entry) {
                final index = entry.key;
                final exercise = entry.value;
                return _ExerciseDetailCard(
                  exercise: exercise,
                  onDelete: () {
                    setState(() {
                      final updatedExercises = List<SessionExercise>.from(_currentSession.exercises);
                      updatedExercises.removeAt(index);
                      _currentSession = WorkoutSession(
                        id: _currentSession.id,
                        userId: _currentSession.userId,
                        planId: _currentSession.planId,
                        workoutDate: _currentSession.workoutDate,
                        startedAt: _currentSession.startedAt,
                        endedAt: _currentSession.endedAt,
                        exercises: updatedExercises,
                        createdAt: _currentSession.createdAt,
                        updatedAt: DateTime.now(),
                      );
                      widget.onSessionUpdated(_currentSession);
                    });
                  },
                );
              }).toList(),
              const SizedBox(height: 32),
              // Summary stats
              Container(
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
                    Text(
                      'Summary',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _SummaryItem(
                          label: 'Total Exercises',
                          value: _currentSession.exercises.length.toString(),
                        ),
                        _SummaryItem(
                          label: 'Total Sets',
                          value: _currentSession.exercises.fold<int>(
                            0,
                            (sum, ex) => sum + ex.sets.length,
                          ).toString(),
                        ),
                        _SummaryItem(
                          label: 'Total Volume',
                          value: '${_calculateTotalVolume().toStringAsFixed(0)} kg',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  double _calculateTotalVolume() {
    double total = 0;
    for (var exercise in _currentSession.exercises) {
      for (var set in exercise.sets) {
        for (var segment in set.segments) {
          total += segment.volume;
        }
      }
    }
    return total;
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Workout?'),
        content: const Text('This action cannot be undone.'),
        backgroundColor: AppColors.cardBg,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              widget.onSessionDeleted();
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExerciseDetailCard extends StatelessWidget {
  final SessionExercise exercise;
  final VoidCallback onDelete;

  const _ExerciseDetailCard({
    required this.exercise,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exercise.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
              PopupMenuButton(
                itemBuilder: (context) => [
                  PopupMenuItem(
                    child: const Row(
                      children: [
                        Icon(Icons.delete, color: AppColors.error, size: 18),
                        SizedBox(width: 12),
                        Text('Delete'),
                      ],
                    ),
                    onTap: onDelete,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...exercise.sets.asMap().entries.map((entry) {
            final set = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.inputBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Set #${set.setNumber}${set.isDropset ? ' (Dropset)' : ''}',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  ...set.segments.asMap().entries.map((entry) {
                    final segment = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${segment.weight}kg × ${segment.repsFrom}-${segment.repsTo}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          Text(
                            'Vol: ${segment.volume.toStringAsFixed(0)}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.accent,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryItem({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: AppColors.accent,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
