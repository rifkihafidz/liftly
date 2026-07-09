import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:liftly/core/utils/app_formatters.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:liftly/core/constants/colors.dart';
import 'package:liftly/core/constants/app_constants.dart';
import 'package:liftly/domain/models/workout_session.dart';
import 'package:liftly/ui/core/shared/widgets/app_dialogs.dart';

import 'package:liftly/ui/features/home/views/main_navigation_wrapper.dart';
import 'package:liftly/ui/features/workout_log/bloc/workout_bloc.dart';
import 'package:liftly/ui/features/workout_log/bloc/workout_event.dart';
import 'package:liftly/ui/features/workout_log/bloc/workout_state.dart';
import 'package:liftly/ui/features/workout_log/views/workout_edit_page.dart';
import 'package:liftly/ui/features/workout_log/views/workout_share_sheet.dart';
import 'package:liftly/core/utils/page_transitions.dart';
import 'package:liftly/ui/core/shared/widgets/animations/fade_in_slide.dart';
import 'package:liftly/ui/core/shared/widgets/cards/exercise_detail_card.dart';
import 'package:liftly/ui/core/shared/widgets/text/notes_display.dart';
import 'package:liftly/ui/core/shared/widgets/text/detail_stat_item.dart';
import 'package:liftly/core/utils/muscle_detector.dart';
import 'package:liftly/ui/core/shared/widgets/visuals/muscle_heatmap.dart';

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

  @override
  void initState() {
    super.initState();
    _currentWorkout = widget.workout;
  }

  void _handleBack() {
    if (widget.fromSession) {
      // Navigate back to navigation wrapper with History tab selected
      // Replacing everything to ensure a clean navigation stack
      Navigator.pushAndRemoveUntil(
        context,
        SmoothPageRoute(
          page: const MainNavigationWrapper(initialIndex: 1),
        ),
        (route) => false,
      );
    } else if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  String formatNumber(double number) {
    final formatter = AppFormatters.weightFormatter;
    return formatter.format(number);
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

  Widget _buildMusclesWorked(List<SessionExercise> exercises) {
    final workedMuscles = <MuscleGroup, int>{};
    for (var ex in exercises) {
      if (!ex.skipped) {
        final muscle =
            MuscleDetector.detectPrimaryMuscle(ex.name, ex.variation);
        workedMuscles[muscle] = (workedMuscles[muscle] ?? 0) + ex.sets.length;
      }
    }

    if (workedMuscles.isEmpty) return const SizedBox.shrink();

    // Move unknown to the end if present, and optionally remove it if we only want known muscles.
    // We'll keep it for transparency, but put it at the end.
    final sortedMuscles = workedMuscles.keys.toList()
      ..sort((a, b) {
        if (a == MuscleGroup.unknown) return 1;
        if (b == MuscleGroup.unknown) return -1;
        return a.index.compareTo(b.index);
      });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        const Text(
          'Muscle Heatmap',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        MuscleHeatmap(workedMuscles: workedMuscles),

        // Show unknown muscles as tags below if there are any
        if (sortedMuscles.contains(MuscleGroup.unknown)) ...[
          const SizedBox(height: 12),
          // Compute both values once here — avoids re-scanning exercises
          // on every iteration of a .map() (there is always exactly 1 unknown entry).
          Builder(builder: (context) {
            final setsCount = workedMuscles[MuscleGroup.unknown] ?? 0;
            final unknownExerciseCount = exercises.where((ex) {
              if (ex.skipped) return false;
              return MuscleDetector.detectPrimaryMuscle(
                      ex.name, ex.variation) ==
                  MuscleGroup.unknown;
            }).length;

            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.textSecondary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.textSecondary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Text(
                    'Other / Uncategorized ($unknownExerciseCount Exercises - $setsCount Sets)',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            );
          }),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final workout = _currentWorkout;
    final workoutDate = workout.effectiveDate;
    final startedAt = workout.startedAt;
    final endedAt = workout.endedAt;

    Duration? duration;
    if (startedAt != null && endedAt != null) {
      duration = endedAt.difference(startedAt);
    }

    final exercises = workout.exercises;
    final nonSkippedExercises = exercises.where((ex) => !ex.skipped).length;

    final totalVolume = workout.totalVolume;
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
            if (state is WorkoutsLoaded || state is WorkoutUpdatedSuccess) {
              if (_isDeleting && mounted) {
                _isDeleting = false;
                Navigator.pop(context); // Close "Deleting..." dialog
                Navigator.pop(context); // Close detail page
                AppDialogs.showSuccessDialog(
                  context: context,
                  title: 'Success',
                  message: 'Workout deleted successfully.',
                );
              } else if (mounted) {
                final workoutId = _currentWorkout.id.toString();

                // If it's a success state, we can use the data directly if IDs match
                if (state is WorkoutUpdatedSuccess && state.data != null) {
                  final successData = WorkoutSession.fromMap(state.data!);
                  if (successData.id == workoutId) {
                    setState(() {
                      _currentWorkout = successData;
                    });
                    return;
                  }
                }

                // Otherwise, look in the updated list
                if (state is WorkoutsLoaded) {
                  try {
                    final updatedWorkout = state.workouts.firstWhere((w) {
                      return w.id == workoutId;
                    });
                    setState(() {
                      _currentWorkout = updatedWorkout;
                    });
                  } catch (e) {
                    // Workout not found in list.
                    // Do nothing here instead of popping, because it might just be missing
                    // from the paginated cache, or deleted on another screen which handles its own pop.
                  }
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
                    title: const Text('Workout Details'),
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
                          Icons.copy_rounded,
                          color: AppColors.textPrimary,
                        ),
                        onPressed: _copyWorkoutSummary,
                        tooltip: 'Copy Summary',
                      ),
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
                          final navigator = Navigator.of(context);
                          final result = await Navigator.push<bool>(
                            context,
                            SmoothPageRoute(
                              page: WorkoutEditPage(workout: _currentWorkout),
                            ),
                          );
                          // Check mounted immediately after async gap
                          if (!mounted) return;
                          // If workout was deleted (result == true), navigate back to history
                          if (result == true) {
                            navigator.pop(true);
                          }
                        },
                      ),
                      IconButton(
                        icon: const Icon(
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
                              Expanded(
                                child: Text(
                                  '${AppFormatters.dateFull.format(workoutDate)} ${startedAt != null && endedAt != null ? '(${AppFormatters.timeShort.format(startedAt)} - ${AppFormatters.timeShort.format(endedAt)})' : ''}',
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (workout.planName != null &&
                              workout.planName!.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  Icons.bookmark_rounded,
                                  size: 14,
                                  color:
                                      AppColors.accent.withValues(alpha: 0.7),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  workout.planName!,
                                  style: TextStyle(
                                    color:
                                        AppColors.accent.withValues(alpha: 0.7),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          NotesDisplay(
                            notes: workout.notes,
                            margin: const EdgeInsets.only(top: 8),
                            maxLength: 45,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 24),
                          // Row 1: Duration & Exercises
                          Row(
                            children: [
                              Expanded(
                                child: DetailStatItem(
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
                                child: DetailStatItem(
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
                                child: DetailStatItem(
                                  icon: Icons.format_list_numbered_rounded,
                                  value: '$totalSets',
                                  label: 'Total Sets',
                                  color: const Color(0xFFF59E0B),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: DetailStatItem(
                                  icon: Icons.scale_rounded,
                                  value: formatNumber(totalVolume),
                                  label: 'Total Volume',
                                  color: const Color(0xFF10B981),
                                  unit: 'kg',
                                ),
                              ),
                            ],
                          ),
                          _buildMusclesWorked(exercises),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final exercise = exercises[index];
                        return FadeInSlide(
                          index: index,
                          child: ExerciseDetailCard(
                            exercise: exercise,
                            index: index,
                            formatNumber: formatNumber,
                          ),
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
      isDangerous: true,
    ).then((confirm) {
      if (confirm == true && context.mounted) {
        _deleteWorkout(context);
      }
    });
  }

  void _deleteWorkout(BuildContext context) {
    _isDeleting = true;
    const userId = AppConstants.defaultUserId;
    final workoutId = _currentWorkout.id.toString();

    // Extract everything from context upfront, before any async gaps
    final bloc = context.read<WorkoutBloc>();
    final scaffoldContext = context;

    showDialog(
      context: scaffoldContext,
      barrierDismissible: false,
      builder: (ctx) => const AlertDialog(
        backgroundColor: AppColors.cardBg,
        content: Row(
          children: [
            CircularProgressIndicator(color: AppColors.accent),
            SizedBox(width: 16),
            Text(
              'Deleting...',
              style: TextStyle(color: AppColors.textPrimary),
            ),
          ],
        ),
      ),
    );

    bloc.add(WorkoutDeleted(userId: userId, workoutId: workoutId));
  }

  Future<void> _copyWorkoutSummary() async {
    final workout = _currentWorkout;
    final buffer = StringBuffer();

    final timeStr = (workout.startedAt != null && workout.endedAt != null)
        ? ' (${AppFormatters.timeShort.format(workout.startedAt!)} - ${AppFormatters.timeShort.format(workout.endedAt!)})'
        : '';
    final dateStr =
        '${AppFormatters.dateFull.format(workout.effectiveDate)}$timeStr';
    final planNameStr =
        (workout.planName != null && workout.planName!.isNotEmpty)
            ? '(${workout.planName}) '
            : '';
    buffer.writeln('$dateStr $planNameStr'.trimRight());
    if (workout.notes.isNotEmpty) {
      buffer.writeln('Session Note: ${workout.notes}');
    }

    Duration? duration;
    if (workout.startedAt != null && workout.endedAt != null) {
      duration = workout.endedAt!.difference(workout.startedAt!);
    }
    final totalSets = workout.exercises.fold<int>(
      0,
      (sum, ex) => sum + (ex.skipped ? 0 : ex.sets.length),
    );
    final totalVolume = workout.totalVolume;

    final statsParts = <String>[];
    if (duration != null) {
      statsParts.add('Duration: ${_formatDuration(duration)}');
    }
    statsParts.add('Total Sets: $totalSets');
    statsParts.add(
        'Total Volume: ${AppFormatters.weightFormatter.format(totalVolume)} kg');

    buffer.writeln(statsParts.join(' | '));

    final allExercisesStr = workout.exercises.map((e) => e.name).join(', ');
    buffer.writeln('Exercises: $allExercisesStr');
    buffer.writeln();

    for (int i = 0; i < workout.exercises.length; i++) {
      final ex = workout.exercises[i];
      if (ex.skipped) continue;

      buffer.writeln(
          '${i + 1}. ${ex.name}${ex.variation.isNotEmpty ? " - ${ex.variation}" : ""}');
      if (ex.notes.isNotEmpty) {
        buffer.writeln('  Exercise Note: ${ex.notes}');
      }

      for (int setIdx = 0; setIdx < ex.sets.length; setIdx++) {
        final set = ex.sets[setIdx];
        if (set.segments.isEmpty) continue;

        final displaySetNumber = set.setNumber > 0 ? set.setNumber : setIdx + 1;
        String setLine = '  Set $displaySetNumber ';

        for (int segIdx = 0; segIdx < set.segments.length; segIdx++) {
          final seg = set.segments[segIdx];
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

          if (segIdx == 0) {
            setLine += '${weight}kg x $reps';
          } else {
            setLine += ' -> drop $weight $reps';
          }

          if (seg.notes.isNotEmpty) {
            setLine += ' (${seg.notes})';
          }
        }
        buffer.writeln(setLine);
      }
      buffer.writeln();
    }

    await Clipboard.setData(ClipboardData(text: buffer.toString().trim()));

    if (mounted) {
      final overlay = Overlay.of(context);
      late OverlayEntry entry;
      entry = OverlayEntry(
        builder: (context) => Positioned(
          bottom: MediaQuery.of(context).viewInsets.bottom + 32,
          left: 24,
          right: 24,
          child: Material(
            color: Colors.transparent,
            child: TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 200),
              tween: Tween(begin: 0.0, end: 1.0),
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, (1 - value) * 10),
                    child: child,
                  ),
                );
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Text(
                  'Copied to clipboard',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      overlay.insert(entry);
      Future.delayed(const Duration(milliseconds: 2000), () {
        if (entry.mounted) {
          entry.remove();
        }
      });
    }
  }

  void _showShareSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final workedMuscles = <MuscleGroup, int>{};
        for (var ex in _currentWorkout.exercises) {
          if (!ex.skipped) {
            final muscle =
                MuscleDetector.detectPrimaryMuscle(ex.name, ex.variation);
            workedMuscles[muscle] =
                (workedMuscles[muscle] ?? 0) + ex.sets.length;
          }
        }

        return WorkoutShareSheet(
          workout: _currentWorkout,
          workedMuscles: workedMuscles,
        );
      },
    );
  }
}
