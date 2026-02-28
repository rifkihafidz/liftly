import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/models/workout_session.dart';
import '../../../shared/widgets/app_dialogs.dart';

import '../../home/pages/main_navigation_wrapper.dart';
import '../bloc/workout_bloc.dart';
import '../bloc/workout_event.dart';
import '../bloc/workout_state.dart';
import 'workout_edit_page.dart';
import '../widgets/workout_share_sheet.dart';
import '../../../core/utils/page_transitions.dart';
import '../../../shared/widgets/animations/fade_in_slide.dart';
import '../../../shared/widgets/cards/exercise_detail_card.dart';
import '../../../shared/widgets/text/detail_stat_item.dart';

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
    final formatter = NumberFormat('#,##0.##', 'pt_BR');
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
                    // Workout not found in list -> it was deleted!
                    if (mounted) {
                      Navigator.pop(context);
                    }
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
                              Expanded(
                                child: Text(
                                  '${DateFormat('EEEE, dd MMMM yyyy').format(workoutDate)} ${startedAt != null && endedAt != null ? '(${DateFormat('HH:mm').format(startedAt)} - ${DateFormat('HH:mm').format(endedAt)})' : ''}',
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
                              workout.planName!.isNotEmpty) ...
                            [
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    Icons.bookmark_rounded,
                                    size: 14,
                                    color: AppColors.accent.withValues(
                                        alpha: 0.7),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    workout.planName!,
                                    style: TextStyle(
                                      color: AppColors.accent
                                          .withValues(alpha: 0.7),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
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
    const userId = AppConstants.defaultUserId;
    final workoutId = _currentWorkout.id.toString();
    
    // Extract everything from context upfront, before any async gaps
    final bloc = context.read<WorkoutBloc>();
    final scaffoldContext = context;

    showDialog(
      context: scaffoldContext,
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
