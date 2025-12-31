import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/colors.dart';
import '../../../core/models/workout_session.dart';
import '../../home/pages/home_page.dart';
import '../bloc/workout_bloc.dart';
import '../bloc/workout_event.dart';
import '../bloc/workout_state.dart';
import 'workout_detail_page.dart';

class WorkoutHistoryPage extends StatefulWidget {
  final String userId;
  final bool fromSession;
  final bool fromDelete;

  const WorkoutHistoryPage({
    super.key,
    required this.userId,
    this.fromSession = false,
    this.fromDelete = false,
  });

  @override
  State<WorkoutHistoryPage> createState() => _WorkoutHistoryPageState();
}

class _WorkoutHistoryPageState extends State<WorkoutHistoryPage> {
  @override
  void initState() {
    super.initState();
    context.read<WorkoutBloc>().add(
      WorkoutsFetched(userId: widget.userId),
    );
  }

  void _handleBack() {
    if (widget.fromSession || widget.fromDelete) {
      // Navigate to home page when coming from session flow or after delete
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
        (route) => route.isFirst,
      );
    } else if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !widget.fromSession && !widget.fromDelete,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        // Handle back button when fromSession or fromDelete is true
        if (widget.fromSession || widget.fromDelete) {
          _handleBack();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Workout History'),
          leading: (widget.fromSession || widget.fromDelete)
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: _handleBack,
                )
              : null,
        ),
        body: BlocBuilder<WorkoutBloc, WorkoutState>(
          builder: (context, state) {
            if (state is WorkoutLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is WorkoutsLoaded) {
              if (state.workouts.isEmpty) {
                return Center(
                  child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.fitness_center,
                      size: 64,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No workouts yet',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Start logging workouts to see them here',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                context.read<WorkoutBloc>().add(
                  WorkoutsFetched(userId: widget.userId),
                );
              },
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: state.workouts.length,
                itemBuilder: (context, index) {
                  final workout = state.workouts[index];
                  return _WorkoutCard(
                    workout: workout,
                    index: index,
                  );
                },
              ),
            );
          }

          if (state is WorkoutError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: AppColors.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading workouts',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.message,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      context.read<WorkoutBloc>().add(
                        WorkoutsFetched(userId: widget.userId),
                      );
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return const SizedBox.shrink();
        },
        ),
      ),
    );
  }
}

class _WorkoutCard extends StatelessWidget {
  final WorkoutSession workout;
  final int index;

  const _WorkoutCard({
    required this.workout,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final workoutDate = workout.workoutDate;
    final startedAt = workout.startedAt;
    final endedAt = workout.endedAt;

    Duration? duration;
    if (startedAt != null && endedAt != null) {
      duration = endedAt.difference(startedAt);
    }

    final exercises = workout.exercises;
    final skippedCount = exercises.where((ex) => ex.skipped == true).length;
    final completedCount = exercises.length - skippedCount;
    final totalVolume = _calculateTotalVolume(exercises);

    return GestureDetector(
      onTap: () async {
        final refreshNeeded = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (_) => WorkoutDetailPage(
              workout: workout,
              fromSession: false,
            ),
          ),
        );
        // Refresh list if coming back from detail page
        if (refreshNeeded == true && context.mounted) {
          final historyState = context.findAncestorStateOfType<_WorkoutHistoryPageState>();
          if (historyState != null) {
            context.read<WorkoutBloc>().add(
              WorkoutsFetched(userId: historyState.widget.userId),
            );
          }
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
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
            // Date and time
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('MMM dd, yyyy').format(workoutDate),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (duration != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _formatDuration(duration),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.accent,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            // Time range
            if (startedAt != null && endedAt != null)
              Text(
                '${DateFormat('HH:mm').format(startedAt)} - ${DateFormat('HH:mm').format(endedAt)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              )
            else
              Text(
                'Workout time not set yet',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            const SizedBox(height: 12),
            // Exercises summary
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${exercises.length} exercises',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 14,
                            color: AppColors.accent,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$completedCount completed',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.accent,
                            ),
                          ),
                          if (skippedCount > 0) ...[
                            const SizedBox(width: 12),
                            Icon(
                              Icons.cancel,
                              size: 14,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$skippedCount skipped',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Total Volume: ${_formatNumber(totalVolume)} kg',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: AppColors.accent,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
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

  double _calculateTotalVolume(List<SessionExercise> exercises) {
    double totalVolume = 0;
    for (final exercise in exercises) {
      if (exercise.skipped == true) continue;
      for (final set in exercise.sets) {
        for (final segment in set.segments) {
          final weight = segment.weight;
          final repsFrom = segment.repsFrom;
          final repsTo = segment.repsTo;
          final reps = repsTo - repsFrom + 1;
          totalVolume += weight * reps;
        }
      }
    }
    return totalVolume;
  }

  String _formatNumber(double number) {
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
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => ',',
    );
    
    return decimalPart.isEmpty ? formattedInt : '$formattedInt.$decimalPart';
  }
}