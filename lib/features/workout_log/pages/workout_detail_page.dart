import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/colors.dart';
import '../../../core/models/workout_session.dart';
import '../../../shared/widgets/app_dialogs.dart';

import '../../session/pages/workout_history_page.dart';
import '../bloc/workout_bloc.dart';
import '../bloc/workout_event.dart';
import '../bloc/workout_state.dart';
import 'workout_edit_page.dart';
import '../widgets/workout_share_sheet.dart';

class WorkoutDetailPage extends StatefulWidget {
  final WorkoutSession workout;
  final bool fromSession;

  const WorkoutDetailPage({
    super.key,
    required this.workout,
    this.fromSession = false,
  });

  @override
  State<WorkoutDetailPage> createState() => _WorkoutDetailPageState();
}

class _WorkoutDetailPageState extends State<WorkoutDetailPage> {
  late WorkoutSession _currentWorkout;
  bool _isDeleting = false;
  static final _thousandSeparator = RegExp(r'\B(?=(\d{3})+(?!\d))');

  @override
  void initState() {
    super.initState();
    _currentWorkout = widget.workout;
  }

  void _handleBack() {
    if (widget.fromSession) {
      // Replace detail with history (smooth transition, no Home flash)
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const WorkoutHistoryPage()),
      );
    } else if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  String formatNumber(double number) {
    String format;
    if (number % 1 == 0) {
      format = number.toInt().toString();
    } else {
      format = number.toStringAsFixed(1);
    }

    // Add thousand separator
    final parts = format.split('.');
    final intPart = parts[0];
    final decimalPart = parts.length > 1 ? parts[1] : '';

    final formattedInt = intPart.replaceAllMapped(
      _thousandSeparator,
      (match) => '.',
    );

    return decimalPart.isEmpty ? formattedInt : '$formattedInt.$decimalPart';
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    if (minutes < 60) {
      return '${minutes}m';
    }
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    if (remainingMinutes == 0) {
      return '${hours}h';
    }
    return '${hours}h ${remainingMinutes}m';
  }

  @override
  Widget build(BuildContext context) {
    final workout = _currentWorkout;
    final workoutDate = workout.workoutDate;
    final startedAt = workout.startedAt;
    final endedAt = workout.endedAt;

    Duration? duration;
    if (startedAt != null && endedAt != null) {
      duration = endedAt.difference(startedAt);
    }

    final exercises = workout.exercises;
    final nonSkippedExercises = exercises.where((ex) => !ex.skipped).length;

    double calculateTotalVolume(List<SessionExercise> exercises) {
      double totalVolume = 0;
      for (final exercise in exercises) {
        if (exercise.skipped) continue;
        totalVolume += exercise.totalVolume;
      }
      return totalVolume;
    }

    final totalVolume = calculateTotalVolume(exercises);
    final totalSets = exercises.fold<int>(
      0,
      (sum, ex) => sum + (ex.skipped ? 0 : ex.sets.length),
    );

    return PopScope(
      canPop: !widget.fromSession,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (widget.fromSession) {
          _handleBack();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.darkBg,
        body: BlocListener<WorkoutBloc, WorkoutState>(
          listener: (context, state) {
            if (state is WorkoutsLoaded) {
              if (_isDeleting && mounted) {
                _isDeleting = false;
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Close page
                AppDialogs.showSuccessDialog(
                  context: context,
                  title: 'Success',
                  message: 'Workout deleted successfully.',
                );
              } else if (!_isDeleting && mounted) {
                final workoutId = _currentWorkout.id.toString();
                try {
                  final updatedWorkout = state.workouts.firstWhere((w) {
                    return w.id == workoutId;
                  });
                  if (mounted) {
                    setState(() {
                      _currentWorkout = updatedWorkout;
                    });
                  }
                } catch (e) {
                  // Workout not found in list
                }
              }
            } else if (state is WorkoutError && mounted) {
              Navigator.pop(context); // Close dialog
              AppDialogs.showErrorDialog(
                context: context,
                title: 'Error Occurred',
                message: state.message,
              );
            }
          },
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverAppBar(
                    pinned: true,
                    centerTitle: false,
                    backgroundColor: AppColors.darkBg,
                    surfaceTintColor: AppColors.darkBg,
                    title: Text(
                      'Workout Details',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                    leading: IconButton(
                      icon: const Icon(
                        Icons.arrow_back,
                        color: AppColors.textPrimary,
                      ),
                      onPressed: _handleBack,
                    ),
                    actions: [
                      IconButton(
                        icon: const Icon(
                          Icons.share_rounded,
                          color: AppColors.textPrimary,
                        ),
                        onPressed: () => _showShareSheet(context),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.edit_rounded,
                          color: AppColors.textPrimary,
                        ),
                        onPressed: () async {
                          final updated = await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  WorkoutEditPage(workout: _currentWorkout),
                            ),
                          );
                          if (updated == true && context.mounted) {
                            context.read<WorkoutBloc>().add(
                              const WorkoutsFetched(userId: '1'),
                            );
                          }
                        },
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.delete_rounded,
                          color: AppColors.error,
                        ),
                        onPressed: () => _showDeleteConfirmation(context),
                      ),
                    ],
                  ),
                  SliverToBoxAdapter(
                    child: Container(
                      margin: const EdgeInsets.all(24),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.cardBg,
                            AppColors.cardBg.withValues(alpha: 0.8),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.05),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                '${DateFormat('EEEE, dd MMMM yyyy').format(workoutDate)} ${startedAt != null && endedAt != null ? '(${DateFormat('HH:mm').format(startedAt)} - ${DateFormat('HH:mm').format(endedAt)})' : ''}',
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          // Row 1: Duration & Exercises
                          Row(
                            children: [
                              Expanded(
                                child: _DetailStatItem(
                                  icon: Icons.timer_rounded,
                                  value: duration != null
                                      ? _formatDuration(duration)
                                      : '-',
                                  label: 'Duration',
                                  color: AppColors.accent,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _DetailStatItem(
                                  icon: Icons.fitness_center_rounded,
                                  value: '$nonSkippedExercises',
                                  label: 'Exercises',
                                  color: const Color(0xFF6366F1),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          // Row 2: Sets & Volume
                          Row(
                            children: [
                              Expanded(
                                child: _DetailStatItem(
                                  icon: Icons.format_list_numbered_rounded,
                                  value: '$totalSets',
                                  label: 'Total Sets',
                                  color: const Color(0xFFF59E0B),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _DetailStatItem(
                                  icon: Icons.scale_rounded,
                                  value: formatNumber(totalVolume),
                                  label: 'Total Volume',
                                  color: const Color(0xFF10B981),
                                  unit: 'kg',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final exercise = exercises[index];
                        return _ExerciseCard(
                          exercise: exercise,
                          index: index,
                          formatNumber: formatNumber,
                        );
                      }, childCount: exercises.length),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    AppDialogs.showConfirmationDialog(
      context: context,
      title: 'Delete Workout',
      message:
          'Are you sure you want to delete this workout? This action cannot be undone.',
      confirmText: 'Delete',
      isDangerous: true,
    ).then((confirm) {
      if (confirm == true && context.mounted) {
        _deleteWorkout(context);
      }
    });
  }

  void _deleteWorkout(BuildContext context) {
    _isDeleting = true;
    const userId = '1';
    final workoutId = _currentWorkout.id.toString();
    final bloc = context.read<WorkoutBloc>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        content: Row(
          children: [
            CircularProgressIndicator(color: AppColors.accent),
            const SizedBox(width: 16),
            const Text(
              'Deleting...',
              style: TextStyle(color: AppColors.textPrimary),
            ),
          ],
        ),
      ),
    );

    bloc.add(WorkoutDeleted(userId: userId, workoutId: workoutId));
  }

  void _showShareSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => WorkoutShareSheet(workout: _currentWorkout),
    );
  }
}

class _DetailStatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final String? unit;

  const _DetailStatItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Flexible(
              child: Text(
                value,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (unit != null)
              Padding(
                padding: const EdgeInsets.only(left: 2),
                child: Text(
                  unit!,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _ExerciseCard extends StatefulWidget {
  final SessionExercise exercise;
  final int index;
  final String Function(double) formatNumber;

  const _ExerciseCard({
    required this.exercise,
    required this.index,
    required this.formatNumber,
  });

  @override
  State<_ExerciseCard> createState() => _ExerciseCardState();
}

class _ExerciseCardState extends State<_ExerciseCard> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    final isSkipped = widget.exercise.skipped;
    final sets = widget.exercise.sets;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: AppColors.cardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isSkipped
                ? Colors.transparent
                : Colors.white.withValues(alpha: 0.05),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            GestureDetector(
              onTap: () => setState(() => _isExpanded = !_isExpanded),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  '${widget.index + 1}. ${widget.exercise.name}',
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: isSkipped
                                            ? AppColors.textSecondary
                                            : AppColors.textPrimary,
                                        decoration: isSkipped
                                            ? TextDecoration.lineThrough
                                            : null,
                                        decorationColor:
                                            AppColors.textSecondary,
                                      ),
                                ),
                              ),
                              if (isSkipped) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.textSecondary.withValues(
                                      alpha: 0.2,
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'Skipped',
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          if (!isSkipped)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                '${sets.length} sets',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (!isSkipped)
                      Icon(
                        _isExpanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: AppColors.textSecondary,
                      ),
                  ],
                ),
              ),
            ),
            if (_isExpanded && !isSkipped)
              Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.2),
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(20),
                  ),
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: sets.asMap().entries.map((entry) {
                    final setIndex = entry.key;
                    final set = entry.value;
                    final segments = set.segments;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (setIndex > 0)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Divider(
                              height: 1,
                              color: Colors.white.withValues(alpha: 0.05),
                            ),
                          ),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.accent.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'SET ${set.setNumber}',
                                style: const TextStyle(
                                  color: AppColors.accent,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            if (segments.length > 1)
                              Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFFF59E0B,
                                    ).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'DROP SET',
                                    style: TextStyle(
                                      color: Color(0xFFF59E0B),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (segments.isNotEmpty &&
                            segments.first.notes.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              'Notes: ${segments.first.notes}',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontStyle: FontStyle.italic,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ...segments.map((segment) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${segment.weight}kg × ${segment.repsFrom}-${segment.repsTo}',
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  'Vol: ${widget.formatNumber(segment.weight * (segment.repsTo - segment.repsFrom + 1))}kg',
                                  style: TextStyle(
                                    color: AppColors.textSecondary.withValues(
                                      alpha: 0.7,
                                    ),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
