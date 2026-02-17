import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:intl/date_symbol_data_local.dart';
import '../../../core/constants/colors.dart';
import '../../../core/models/workout_session.dart';
import '../../../core/models/personal_record.dart';
import '../../../shared/widgets/app_dialogs.dart';
import '../../../shared/widgets/workout_form_widgets.dart';
import '../../../shared/widgets/session_exercise_card.dart';
import '../../workout_log/pages/workout_detail_page.dart';
import '../bloc/session_bloc.dart';
import '../bloc/session_event.dart';
import '../bloc/session_state.dart';

import '../widgets/session_exercise_history_sheet.dart';
import '../../../shared/widgets/shimmer_widgets.dart';
import '../../../core/utils/page_transitions.dart';

import '../../workout_log/repositories/workout_repository.dart';
import '../../plans/bloc/plan_bloc.dart';
import '../../plans/bloc/plan_event.dart';
import '../../plans/bloc/plan_state.dart';

class SessionPage extends StatefulWidget {
  final List<SessionExercise> exercises; // Updated from exerciseNames
  final String? planId;
  final String? planName;
  final WorkoutSession? draftSession;

  const SessionPage({
    super.key,
    this.exercises = const [],
    this.planId,
    this.planName,
    this.draftSession,
  });

  @override
  State<SessionPage> createState() => _SessionPageState();
}

class _SessionPageState extends State<SessionPage> {
  late SessionBloc _sessionBloc;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('pt_BR');

    // Start session with actual exercises or resume draft
    _sessionBloc = context.read<SessionBloc>();
    const userId = '1'; // Default local user ID

    if (widget.draftSession != null) {
      _sessionBloc.add(SessionDraftResumed(draftSession: widget.draftSession!));
    } else {
      _sessionBloc.add(
        SessionStarted(
          planId: widget.planId,
          planName: widget.planName,
          exerciseNames: widget.exercises.map((e) => e.name).toList(),
          userId: userId,
        ),
      );
    }
  }

  @override
  void dispose() {
    // Safety net: If page is closed but session is still in progress (not saved/drafted), discard it.
    if (_sessionBloc.state is SessionInProgress) {
      _sessionBloc.add(const SessionDiscarded());
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _showUnsavedChangesDialog(context);
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: AppColors.darkBg,
        body: BlocListener<SessionBloc, SessionState>(
          listenWhen: (previous, current) =>
              current is SessionSaved || current is SessionDraftSaved,
          listener: (context, state) {
            if (state is SessionDraftSaved) {
              AppDialogs.showSuccessDialog(
                context: context,
                title: 'Draft Saved',
                message: 'Your workout draft has been saved.',
                onConfirm: () {
                  if (mounted) {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  }
                },
              );
            } else if (state is SessionSaved) {
              AppDialogs.showSuccessDialog(
                context: context,
                title: 'Success',
                message: 'Workout saved successfully.',
                onConfirm: () {
                  if (mounted) {
                    // Replace session with detail (smooth transition, no Home flash)
                    Navigator.pushReplacement(
                      context,
                      SmoothPageRoute(
                        page: WorkoutDetailPage(
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
                return const SessionPageShimmer();
              }

              if (state is SessionSaved) {
                return const SizedBox.shrink();
              }

              if (state is SessionInProgress) {
                final session = state.session;
                final exercises = session.exercises;

                return Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: CustomScrollView(
                      physics: const BouncingScrollPhysics(),
                      slivers: [
                        SliverAppBar(
                          expandedHeight: 0,
                          pinned: true,
                          floating: true,
                          centerTitle: false,
                          backgroundColor: AppColors.darkBg,
                          elevation: 0,
                          surfaceTintColor: AppColors.darkBg,
                          leading: IconButton(
                            icon: const Icon(
                              Icons.arrow_back,
                              color: AppColors.textPrimary,
                            ),
                            onPressed: () => Navigator.maybePop(context),
                          ),
                          title: Text(
                            widget.draftSession != null
                                ? 'Resume Workout'
                                : 'Log Workout',
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          actions: [
                            IconButton(
                              icon: const Icon(
                                Icons.save_as_outlined,
                                color: AppColors.textPrimary,
                              ),
                              tooltip: 'Save as Draft',
                              onPressed: () async {
                                final confirm =
                                    await AppDialogs.showConfirmationDialog(
                                  context: context,
                                  title: 'Save Draft',
                                  message:
                                      'Save current progress as draft? You can resume it later.',
                                  confirmText: 'Save',
                                );

                                if (confirm == true && context.mounted) {
                                  context.read<SessionBloc>().add(
                                        const SessionSaveDraftRequested(),
                                      );
                                }
                              },
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.reorder_rounded,
                                color: AppColors.textPrimary,
                              ),
                              tooltip: 'Reorder Exercises',
                              onPressed: _showReorderExercisesSheet,
                            ),
                          ],
                        ),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 24,
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: AppColors.cardBg,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.05),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  WorkoutDateTimeCard(
                                    workoutDate: session.workoutDate,
                                    startedAt: session.startedAt,
                                    endedAt: session.endedAt,
                                    onTap: () async {
                                      final result = await showDialog<
                                          Map<String, DateTime?>>(
                                        context: context,
                                        barrierDismissible: false,
                                        builder: (context) =>
                                            WorkoutDateTimeDialog(
                                          initialWorkoutDate:
                                              session.workoutDate,
                                          initialStartedAt: session.startedAt,
                                          initialEndedAt: session.endedAt,
                                        ),
                                      );
                                      if (result != null && context.mounted) {
                                        context.read<SessionBloc>().add(
                                              SessionDateTimesUpdated(
                                                workoutDate:
                                                    result['workoutDate'],
                                                startedAt: result['startedAt'],
                                                endedAt: result['endedAt'],
                                              ),
                                            );
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        if (exercises.isEmpty)
                          SliverPadding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            sliver: SliverToBoxAdapter(
                              child: Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(32),
                                  child: Text(
                                    'No exercises added yet.',
                                    style: TextStyle(
                                      color: AppColors.textSecondary.withValues(
                                        alpha: 0.5,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          )
                        else
                          SliverPadding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate((
                                context,
                                index,
                              ) {
                                final exIndex =
                                    index; // Direct mapping now since header is separate
                                final exercise = exercises[exIndex];

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: Column(
                                    children: [
                                      if (exIndex == 0)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 16,
                                          ),
                                          child: Row(
                                            children: [
                                              Text(
                                                'EXERCISES (${exercises.length})',
                                                style: TextStyle(
                                                  color: AppColors.accent,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                  letterSpacing: 1.5,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      RepaintBoundary(
                                        child: SessionExerciseCard(
                                          key: ValueKey(exercise.id),
                                          exercise: exercise,
                                          exerciseIndex: exIndex,
                                          history: state
                                              .previousSessions[exercise.name],
                                          pr: state.exercisePRs[exercise.name],
                                          focusedSetIndex:
                                              state.focusedExerciseIndex ==
                                                      exIndex
                                                  ? state.focusedSetIndex
                                                  : null,
                                          focusedSegmentIndex:
                                              state.focusedExerciseIndex ==
                                                      exIndex
                                                  ? state.focusedSegmentIndex
                                                  : null,
                                          onSkipToggle: () {
                                            context.read<SessionBloc>().add(
                                                  SessionExerciseSkipToggled(
                                                    exerciseIndex: exIndex,
                                                  ),
                                                );
                                          },
                                          onHistoryTap: () {
                                            _showExerciseHistory(
                                              context,
                                              exercise.name,
                                              state.previousSessions[
                                                  exercise.name],
                                              state.exercisePRs[exercise.name],
                                            );
                                          },
                                          onAddSet: () {
                                            context.read<SessionBloc>().add(
                                                  SessionSetAdded(
                                                    exerciseIndex: exIndex,
                                                  ),
                                                );
                                          },
                                          onRemoveSet: (setIndex) {
                                            context.read<SessionBloc>().add(
                                                  SessionSetRemoved(
                                                    exerciseIndex: exIndex,
                                                    setIndex: setIndex,
                                                  ),
                                                );
                                          },
                                          onAddDropSet: (setIndex) {
                                            context.read<SessionBloc>().add(
                                                  SessionSegmentAdded(
                                                    exerciseIndex: exIndex,
                                                    setIndex: setIndex,
                                                  ),
                                                );
                                          },
                                          onRemoveDropSet:
                                              (setIndex, segmentIndex) {
                                            context.read<SessionBloc>().add(
                                                  SessionSegmentRemoved(
                                                    exerciseIndex: exIndex,
                                                    setIndex: setIndex,
                                                    segmentIndex: segmentIndex,
                                                  ),
                                                );
                                          },
                                          onUpdateSegment: (
                                            setIndex,
                                            segmentIndex,
                                            field,
                                            value,
                                          ) {
                                            context.read<SessionBloc>().add(
                                                  SessionSegmentUpdated(
                                                    exerciseIndex: exIndex,
                                                    setIndex: setIndex,
                                                    segmentIndex: segmentIndex,
                                                    field: field,
                                                    value: value,
                                                  ),
                                                );
                                          },
                                          onEditName: exercise.isTemplate
                                              ? null
                                              : () => _showEditNameDialog(
                                                    context,
                                                    exIndex,
                                                    exercise.name,
                                                  ),
                                          onDelete: exercise.isTemplate
                                              ? null
                                              : () => _confirmDeleteExercise(
                                                    context,
                                                    exIndex,
                                                    exercise.name,
                                                  ),
                                          isLastExercise:
                                              exIndex == exercises.length - 1,
                                        ),
                                      ),
                                      // Clear focus flags after rendering
                                      if (state.focusedExerciseIndex != null &&
                                          state.focusedExerciseIndex == exIndex)
                                        Builder(
                                          builder: (context) {
                                            return const SizedBox.shrink();
                                          },
                                        ),
                                    ],
                                  ),
                                );
                              }, childCount: exercises.length),
                            ),
                          ),
                        // Footer Actions
                        SliverPadding(
                          padding: EdgeInsets.fromLTRB(
                            16,
                            8,
                            16,
                            MediaQuery.of(context).viewInsets.bottom > 0
                                ? 200
                                : 80,
                          ),
                          sliver: SliverToBoxAdapter(
                            child: Column(
                              children: [
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: () =>
                                        _showAddExerciseDialog(context),
                                    icon: const Icon(Icons.add_rounded),
                                    label: const Text('Add Exercise'),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  width: double.infinity,
                                  child: FilledButton(
                                    onPressed: () => _onFinishWorkout(context),
                                    child: const Text(
                                      'Finish Workout',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              if (state is SessionError) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  AppDialogs.showErrorDialog(
                    context: context,
                    title: 'Error Occurred',
                    message: state.message,
                  );
                });
                return const SessionPageShimmer();
              }

              return const Center(child: Text('No session'));
            },
          ),
        ),
      ),
    );
  }

  void _showExerciseHistory(
    BuildContext context,
    String exerciseName,
    WorkoutSession? lastSession,
    PersonalRecord? pr,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SessionExerciseHistorySheet(
        exerciseName: exerciseName,
        history: lastSession,
        pr: pr,
      ),
    );
  }

  void _showUnsavedChangesDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => PopScope(
        canPop: false,
        child: AlertDialog(
          backgroundColor: AppColors.cardBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Unsaved Changes',
            style: TextStyle(color: AppColors.textPrimary),
          ),
          content: const Text(
            'You have unsaved progress. What would you like to do?',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext); // Close dialog
                context.read<SessionBloc>().add(const SessionDiscarded());
                Navigator.pop(context); // Close page (Discard)
              },
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
              child: const Text('Discard'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext); // Close dialog
                context.read<SessionBloc>().add(
                      const SessionSaveDraftRequested(),
                    );
              },
              style: TextButton.styleFrom(
                foregroundColor: AppColors.accent,
                textStyle: const TextStyle(fontWeight: FontWeight.bold),
              ),
              child: const Text('Save Draft'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditNameDialog(
    BuildContext context,
    int index,
    String currentName,
  ) async {
    final WorkoutRepository workoutRepository = WorkoutRepository();
    List<String> availableExercises = [];

    // Load suggestions
    try {
      // 1. Load from history
      const userId = '1';
      final historyNames = await workoutRepository.getExerciseNames(
        userId: userId,
      );
      final uniqueNames = historyNames.toSet();

      if (!context.mounted) return;

      // 2. Load from plans
      final currentPlanState = context.read<PlanBloc>().state;
      if (currentPlanState is PlansLoaded) {
        final planNames = currentPlanState.plans
            .expand((p) => p.exercises)
            .map((e) => e.name);
        uniqueNames.addAll(planNames);
      }

      availableExercises = uniqueNames.toList()..sort();
    } catch (e, stackTrace) {
      log(
        'Error loading suggestions',
        name: 'SessionPage',
        error: e,
        stackTrace: stackTrace,
      );
    }

    if (!context.mounted) return;

    AppDialogs.showExerciseEntryDialog(
      context: context,
      title: 'Rename Exercise',
      initialValue: currentName,
      suggestions: availableExercises,
      onConfirm: (newName) {
        context.read<SessionBloc>().add(
              SessionExerciseNameUpdated(
                  exerciseIndex: index, newName: newName),
            );
      },
    );
  }

  void _confirmDeleteExercise(BuildContext context, int index, String name) {
    AppDialogs.showConfirmationDialog(
      context: context,
      title: 'Remove Exercise',
      message: 'Are you sure you want to remove "$name"?',
      confirmText: 'Remove',
      isDangerous: true,
    ).then((confirm) {
      if (confirm == true && context.mounted) {
        context.read<SessionBloc>().add(
              SessionExerciseRemoved(exerciseIndex: index),
            );
      }
    });
  }

  Future<void> _showAddExerciseDialog(BuildContext context) async {
    final WorkoutRepository workoutRepository = WorkoutRepository();
    List<String> availableExercises = [];
    // Load suggestions
    try {
      // 1. Load from history
      const userId = '1';
      final historyNames = await workoutRepository.getExerciseNames(
        userId: userId,
      );
      final uniqueNames = historyNames.toSet();

      if (!context.mounted) return;

      // 2. Load from plans
      final currentPlanState = context.read<PlanBloc>().state;
      if (currentPlanState is PlansLoaded) {
        final planNames = currentPlanState.plans
            .expand((p) => p.exercises)
            .map((e) => e.name);
        uniqueNames.addAll(planNames);
      } else {
        context.read<PlanBloc>().add(const PlansFetchRequested(userId: userId));
      }

      availableExercises = uniqueNames.toList()..sort();
    } catch (e, stackTrace) {
      log(
        'Error loading suggestions',
        name: 'SessionPage',
        error: e,
        stackTrace: stackTrace,
      );
    }

    if (!context.mounted) return;

    AppDialogs.showExerciseEntryDialog(
      context: context,
      title: 'Add Exercise',
      hintText: 'Exercise Name (e.g. Bench Press)',
      suggestions: availableExercises,
      onConfirm: (exerciseName) {
        context.read<SessionBloc>().add(
              SessionExerciseAdded(exerciseName: exerciseName),
            );
      },
    );
  }

  void _onFinishWorkout(BuildContext context) {
    final state = context.read<SessionBloc>().state;
    if (state is SessionInProgress) {
      final allSkipped = state.session.exercises.every((e) => e.skipped);
      if (allSkipped) {
        AppDialogs.showErrorDialog(
          context: context,
          title: 'Cannot Finish Workout',
          message:
              'All exercises are skipped. You must perform at least one exercise to finish the workout.',
        );
        return;
      }
    }

    AppDialogs.showConfirmationDialog(
      context: context,
      title: 'Finish Workout',
      message: 'Are you sure you want to finish this workout?',
      confirmText: 'Finish',
    ).then((confirm) {
      if (confirm == true && context.mounted) {
        context.read<SessionBloc>().add(const SessionEnded());
        Future.delayed(const Duration(milliseconds: 50), () {
          if (context.mounted) {
            context.read<SessionBloc>().add(const SessionSaveRequested());
          }
        });
      }
    });
  }

  void _showReorderExercisesSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return BlocBuilder<SessionBloc, SessionState>(
          builder: (context, state) {
            if (state is! SessionInProgress) return const SizedBox.shrink();
            final exercises = state.session.exercises;

            return DraggableScrollableSheet(
              initialChildSize: 0.6,
              minChildSize: 0.4,
              maxChildSize: 0.9,
              expand: false,
              builder: (context, scrollController) {
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Reorder Exercises',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Done'),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: ReorderableListView.builder(
                        scrollController: scrollController,
                        itemCount: exercises.length,
                        onReorder: (oldIndex, newIndex) {
                          _sessionBloc.add(
                            SessionExercisesReordered(
                              oldIndex: oldIndex,
                              newIndex: newIndex,
                            ),
                          );
                        },
                        itemBuilder: (context, index) {
                          final ex = exercises[index];
                          return ListTile(
                            key: ValueKey(ex.id),
                            leading: Container(
                              width: 32,
                              height: 32,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: AppColors.accent.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(
                                  color: AppColors.accent,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              ex.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            trailing: const Icon(
                              Icons.drag_handle_rounded,
                              color: AppColors.textSecondary,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
}
