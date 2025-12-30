import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/colors.dart';
import '../../../core/models/workout_session.dart';
import '../../../shared/widgets/app_dialogs.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_state.dart';
import '../bloc/workout_bloc.dart';
import '../bloc/workout_event.dart';
import '../bloc/workout_state.dart';
import 'workout_edit_page.dart';

class WorkoutDetailPage extends StatefulWidget {
  final dynamic workout; // Accept both WorkoutSession and Map<String, dynamic> for now
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
  late dynamic _currentWorkout;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    // Handle both WorkoutSession and Map types
    if (widget.workout is WorkoutSession) {
      final session = widget.workout as WorkoutSession;
      _currentWorkout = _convertSessionToMap(session);
    } else {
      _currentWorkout = widget.workout;
    }
  }

  Map<String, dynamic> _convertSessionToMap(WorkoutSession session) {
    return {
      'id': session.id,
      'userId': session.userId,
      'planId': session.planId,
      'workoutDate': session.workoutDate.toIso8601String(),
      'startedAt': session.startedAt?.toIso8601String(),
      'endedAt': session.endedAt?.toIso8601String(),
      'exercises': session.exercises
          .map((ex) => {
                'id': ex.id,
                'name': ex.name,
                'order': ex.order,
                'skipped': ex.skipped,
                'sets': ex.sets
                    .map((set) => {
                          'id': set.id,
                          'setNumber': set.setNumber,
                          'segments': set.segments
                              .map((seg) => {
                                    'id': seg.id,
                                    'weight': seg.weight,
                                    'repsFrom': seg.repsFrom,
                                    'repsTo': seg.repsTo,
                                    'segmentOrder': seg.segmentOrder,
                                    'notes': seg.notes,
                                  })
                              .toList(),
                        })
                    .toList(),
              })
          .toList(),
      'createdAt': session.createdAt.toIso8601String(),
      'updatedAt': session.updatedAt.toIso8601String(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final workout = _currentWorkout;
    final workoutDate = DateTime.parse(workout['workoutDate'] as String);
    final startedAt = workout['startedAt'] != null
        ? DateTime.parse(workout['startedAt'] as String)
        : null;
    final endedAt = workout['endedAt'] != null
        ? DateTime.parse(workout['endedAt'] as String)
        : null;

    Duration? duration;
    if (startedAt != null && endedAt != null) {
      duration = endedAt.difference(startedAt);
    }

    final exercises = (workout['exercises'] as List<dynamic>?) ?? [];

    double calculateTotalVolume(List<dynamic> exercises) {
      double totalVolume = 0;
      for (final exercise in exercises) {
        if (exercise['skipped'] == true) continue;
        final sets = (exercise['sets'] as List<dynamic>?) ?? [];
        for (final set in sets) {
          final segments = (set['segments'] as List<dynamic>?) ?? [];
          for (final segment in segments) {
            final weight = (segment['weight'] as num?)?.toDouble() ?? 0;
            final repsFrom = (segment['repsFrom'] as num?)?.toInt() ?? 0;
            final repsTo = (segment['repsTo'] as num?)?.toInt() ?? 0;
            final reps = repsTo - repsFrom + 1;
            totalVolume += weight * reps;
          }
        }
      }
      return totalVolume;
    }

    final totalVolume = calculateTotalVolume(exercises);

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
        RegExp(r'\B(?=(\d{3})+(?!\d))'),
        (match) => ',',
      );
      
      return decimalPart.isEmpty ? formattedInt : '$formattedInt.$decimalPart';
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Workout Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final updated = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (_) => WorkoutEditPage(workout: _currentWorkout),
                ),
              );
              if (updated == true && context.mounted) {
                // Reload workout data from server
                final authState = context.read<AuthBloc>().state;
                if (authState is AuthAuthenticated) {
                  // Fetch latest workouts to get updated data
                  context.read<WorkoutBloc>().add(
                    WorkoutsFetched(userId: authState.user.id),
                  );
                }
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () {
              _showDeleteConfirmation(context);
            },
          ),
        ],
      ),
      body: BlocListener<WorkoutBloc, WorkoutState>(
        listener: (context, state) {
          // Handle WorkoutsLoaded for both delete and refresh after edit
          if (state is WorkoutsLoaded) {
            if (_isDeleting) {
              // Successfully deleted and fetched new list
              // Pop 2 times: first close loading dialog, then close detail page
              Navigator.popUntil(context, (route) {
                // Count pops, return true when we're done (2 pops)
                if (route.isFirst) {
                  return true; // Stop at home/history
                }
                // Pop until we reach the history page
                return false;
              });
              
              AppDialogs.showSuccessDialog(
                context: context,
                title: 'Berhasil',
                message: 'Workout berhasil dihapus.',
              );
            } else {
              // Refresh after update - find current workout in list and update
              final workoutId = _currentWorkout['id'].toString();
              try {
                final updatedWorkout = state.workouts.firstWhere(
                  (w) => w.id == workoutId,
                );
                
                if (context.mounted) {
                  setState(() {
                    // Update current workout with latest data from WorkoutSession
                    _currentWorkout = _convertSessionToMap(updatedWorkout);
                  });
                }
              } catch (e) {
                // Workout not found in list, keep current data
              }
            }
          } else if (state is WorkoutError) {
            Navigator.pop(context); // Close loading dialog if still open
            AppDialogs.showErrorDialog(
              context: context,
              title: 'Terjadi Kesalahan',
              message: state.message,
            );
          }
        },
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header section
              Container(
                color: AppColors.cardBg,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('EEEE, MMM dd, yyyy').format(workoutDate),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 18,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 8),
                        if (startedAt != null)
                          Text(
                            '${DateFormat('HH:mm').format(startedAt)} - ${endedAt != null ? DateFormat('HH:mm').format(endedAt) : '...'}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                      ],
                    ),
                    if (duration != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.timer,
                            size: 18,
                            color: AppColors.accent,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Duration: ${_formatDuration(duration)}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.accent,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.scale,
                            size: 18,
                            color: AppColors.accent,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Total Volume: ${formatNumber(totalVolume)} kg',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.accent,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              // Exercises section
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${exercises.length} Exercises',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...List.generate(exercises.length, (index) {
                      final exercise = exercises[index] as Map<String, dynamic>;
                      return _ExerciseCard(
                        exercise: exercise,
                        index: index,
                        formatNumber: formatNumber,
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
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

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Text('Delete Workout'),
          content: const Text(
            'Apakah Anda yakin ingin menghapus workout ini? Tindakan ini tidak dapat dibatalkan.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                _deleteWorkout(context);
              },
              child: const Text(
                'Hapus',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  void _deleteWorkout(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) {
      return;
    }

    _isDeleting = true; // Set flag
    final userId = authState.user.id;
    final workoutId = _currentWorkout['id'].toString();
    final bloc = context.read<WorkoutBloc>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        content: const Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Menghapus...'),
          ],
        ),
      ),
    );

    bloc.add(
      WorkoutDeleted(
        userId: userId,
        workoutId: workoutId,
      ),
    );
  }
}

class _ExerciseCard extends StatefulWidget {
  final Map<String, dynamic> exercise;
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
    final isSkipped = widget.exercise['skipped'] == true;
    final sets = (widget.exercise['sets'] as List<dynamic>?) ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSkipped ? AppColors.borderDark : AppColors.borderLight,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              '${widget.index + 1}. ${widget.exercise['name']}',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: isSkipped
                                    ? AppColors.textSecondary
                                    : AppColors.textPrimary,
                                decoration: isSkipped
                                    ? TextDecoration.lineThrough
                                    : null,
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
                                  color: AppColors.textSecondary
                                      .withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Skipped',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${sets.length} sets',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isSkipped)
                    Icon(
                      _isExpanded
                          ? Icons.expand_less
                          : Icons.expand_more,
                      color: AppColors.textSecondary,
                    ),
                ],
              ),
            ),
          ),
          if (_isExpanded && !isSkipped)
            Container(
              decoration: BoxDecoration(
                color: AppColors.inputBg,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...List.generate(sets.length, (setIndex) {
                    final set = sets[setIndex] as Map<String, dynamic>;
                    final segments =
                        (set['segments'] as List<dynamic>?) ?? [];

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (setIndex > 0)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Divider(height: 1),
                          ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Set ${set['setNumber']}',
                                  style:
                                      Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.accent,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (((set['segments'] as List<dynamic>?)?.length ?? 0) > 1)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.accent.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'Drop Set',
                                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                        color: AppColors.accent,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            if (segments.isNotEmpty && ((segments.first['notes'] as String?) ?? '').isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  'Notes: ${segments.first['notes']}',
                                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: AppColors.textSecondary,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ...List.generate(segments.length, (segIndex) {
                          final segment =
                              segments[segIndex] as Map<String, dynamic>;
                          final weight = segment['weight'];
                          final repsFrom = segment['repsFrom'];
                          final repsTo = segment['repsTo'];
                          final isDropset = segments.length > 1;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                if (isDropset)
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: AppColors.accent
                                          .withValues(alpha: 0.2),
                                      borderRadius:
                                          BorderRadius.circular(4),
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${segIndex + 1}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelSmall
                                            ?.copyWith(
                                          color: AppColors.accent,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  )
                                else
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: AppColors.accent
                                          .withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Icon(
                                        Icons.check,
                                        size: 12,
                                        color: AppColors.accent,
                                      ),
                                    ),
                                  ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  '${weight}kg × $repsFrom-$repsTo reps',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall
                                                      ?.copyWith(
                                                    fontWeight:
                                                        FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Text(
                                            'Vol: ${widget.formatNumber(weight * (repsTo - repsFrom + 1))} kg',
                                            style: Theme.of(context)
                                                .textTheme
                                                .labelSmall
                                                ?.copyWith(
                                              color:
                                                  AppColors.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    );
                  }),
                ],
              ),
            ),
        ],
      ),
    );
  }
}