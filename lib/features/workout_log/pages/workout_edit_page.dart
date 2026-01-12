import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/colors.dart';
import 'package:intl/intl.dart';
import '../../../shared/widgets/app_dialogs.dart';
import '../../../shared/widgets/workout_form_widgets.dart';
import '../../../core/models/workout_session.dart';
import '../repositories/workout_repository.dart';
import '../../../shared/widgets/session_exercise_card.dart';
import '../../../../shared/widgets/cards/exercise_list_summary_card.dart';
import '../bloc/workout_bloc.dart';
import '../bloc/workout_event.dart';
import '../bloc/workout_state.dart';
import '../../plans/bloc/plan_bloc.dart';
import '../../plans/bloc/plan_event.dart';
import '../../plans/bloc/plan_state.dart';
import '../../session/widgets/session_exercise_history_sheet.dart';
import '../widgets/exercise_view_widgets.dart';

class WorkoutEditPage extends StatefulWidget {
  final WorkoutSession workout;

  const WorkoutEditPage({super.key, required this.workout});

  @override
  State<WorkoutEditPage> createState() => _WorkoutEditPageState();
}

class _WorkoutEditPageState extends State<WorkoutEditPage> {
  late WorkoutSession _editedWorkout;
  final _workoutRepository = WorkoutRepository();
  final Map<String, SessionExercise> _previousSessions = {};
  final Map<String, SetSegment> _exercisePRs = {};

  @override
  void initState() {
    super.initState();
    _editedWorkout = widget.workout;
    _loadHistoryAndPRs();
  }

  Future<void> _loadHistoryAndPRs() async {
    final exercises = _editedWorkout.exercises;

    for (final exercise in exercises) {
      final name = exercise.name;
      _loadHistoryAndPRsRecursive(name);
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('EEEE, dd MMMM yyyy').format(date);
  }

  void _saveChanges() {
    final allSkipped = _editedWorkout.exercises.every((e) => e.skipped);
    if (allSkipped) {
      AppDialogs.showErrorDialog(
        context: context,
        title: 'Cannot Save Workout',
        message:
            'All exercises are skipped. You must perform at least one exercise to save the workout.',
      );
      return;
    }

    AppDialogs.showConfirmationDialog(
      context: context,
      title: 'Save Changes',
      message: 'Are you sure you want to save these changes?',
      confirmText: 'Save',
    ).then((confirm) {
      if (confirm == true && mounted) {
        const userId = '1';
        final workoutId = _editedWorkout.id;

        context.read<WorkoutBloc>().add(
          WorkoutUpdated(
            userId: userId,
            workoutId: workoutId,
            workoutData: _editedWorkout.toMap(),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final workoutDate = _editedWorkout.workoutDate;
    final exercises = _editedWorkout.exercises;

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      resizeToAvoidBottomInset: true,
      body: BlocListener<WorkoutBloc, WorkoutState>(
        listenWhen: (previous, current) {
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
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverAppBar(
                  expandedHeight: 0,
                  pinned: true,
                  centerTitle: false,
                  floating: true,
                  backgroundColor: AppColors.darkBg,
                  elevation: 0,
                  surfaceTintColor: AppColors.darkBg,
                  leading: IconButton(
                    icon: const Icon(
                      Icons.arrow_back,
                      color: AppColors.textPrimary,
                    ),
                    onPressed: () async {
                      if (_editedWorkout != widget.workout) {
                        final shouldDiscard =
                            await AppDialogs.showConfirmationDialog(
                              context: context,
                              title: 'Discard Changes?',
                              message:
                                  'You have unsaved changes. Are you sure you want to discard them?',
                              confirmText: 'Discard',
                              isDangerous: true,
                            );
                        if (shouldDiscard == true && context.mounted) {
                          Navigator.pop(context);
                        }
                      } else {
                        Navigator.pop(context);
                      }
                    },
                  ),
                  title: const Text(
                    'Edit Workout',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(
                        Icons.save_rounded,
                        color: AppColors.textPrimary,
                      ),
                      tooltip: 'Save Changes',
                      onPressed: _saveChanges,
                    ),
                    IconButton(
                      onPressed: _showReorderExercisesSheet,
                      icon: const Icon(
                        Icons.reorder_rounded,
                        color: AppColors.textPrimary,
                      ),
                      tooltip: 'Reorder Exercises',
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
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today_rounded,
                                size: 16,
                                color: AppColors.accent,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _formatDate(workoutDate),
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: DateTimeInput(
                                  label: 'Started At',
                                  dateTime: _editedWorkout.startedAt,
                                  onTap: () async {
                                    final result =
                                        await showDialog<
                                          Map<String, DateTime?>
                                        >(
                                          context: context,
                                          barrierDismissible: false,
                                          builder: (context) =>
                                              WorkoutDateTimeDialog(
                                                initialWorkoutDate: workoutDate,
                                                initialStartedAt:
                                                    _editedWorkout.startedAt,
                                                initialEndedAt:
                                                    _editedWorkout.endedAt,
                                              ),
                                        );
                                    if (result != null) {
                                      setState(() {
                                        _editedWorkout = _editedWorkout
                                            .copyWith(
                                              workoutDate:
                                                  result['workoutDate'] ??
                                                  _editedWorkout.workoutDate,
                                              startedAt: result['startedAt'],
                                              endedAt: result['endedAt'],
                                            );
                                      });
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: DateTimeInput(
                                  label: 'Ended At',
                                  dateTime: _editedWorkout.endedAt,
                                  onTap: () async {
                                    final result =
                                        await showDialog<
                                          Map<String, DateTime?>
                                        >(
                                          context: context,
                                          barrierDismissible: false,
                                          builder: (context) =>
                                              WorkoutDateTimeDialog(
                                                initialWorkoutDate: workoutDate,
                                                initialStartedAt:
                                                    _editedWorkout.startedAt,
                                                initialEndedAt:
                                                    _editedWorkout.endedAt,
                                              ),
                                        );
                                    if (result != null) {
                                      setState(() {
                                        _editedWorkout = _editedWorkout
                                            .copyWith(
                                              workoutDate:
                                                  result['workoutDate'] ??
                                                  _editedWorkout.workoutDate,
                                              startedAt: result['startedAt'],
                                              endedAt: result['endedAt'],
                                            );
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
                ),

                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        'EXERCISES (${exercises.length})',
                        style: const TextStyle(
                          color: AppColors.accent,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),

                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final exIndex = index;
                      final exercise = exercises[exIndex];

                      return Padding(
                        key: ValueKey('edit_ex_${exercise.id}'),
                        padding: const EdgeInsets.only(bottom: 16),
                        child: ExerciseListSummaryCard(
                          exercise: exercise,
                          index: exIndex,
                          onTap: () => _showExerciseEditSheet(context, exIndex),
                        ),
                      );
                    }, childCount: exercises.length),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 48),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => _showAddExerciseDialog(context),
                            icon: const Icon(Icons.add_rounded),
                            label: const Text('Add Exercise'),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: _saveChanges,
                            child: const Text(
                              'Save Changes',
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
        ),
      ),
    );
  }

  void _showExerciseEditSheet(BuildContext context, int exerciseIndex) {
    // 1. Get initial data
    final initialExercise = _editedWorkout.exercises[exerciseIndex];
    final history = _previousSessions[initialExercise.name];
    final pr = _exercisePRs[initialExercise.name];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _ExerciseEditSheet(
          initialExercise: initialExercise,
          exerciseIndex: exerciseIndex,
          history: history,
          pr: pr,
          onSave: (updatedExercise) {
            // 2. ONLY Save when confirmed
            setState(() {
              final updatedExercises = List<SessionExercise>.from(
                _editedWorkout.exercises,
              );
              // Ensure index is still valid
              if (exerciseIndex < updatedExercises.length) {
                updatedExercises[exerciseIndex] = updatedExercise;
                _editedWorkout = _editedWorkout.copyWith(
                  exercises: updatedExercises,
                );
              }
            });
            Navigator.pop(context);
          },
          onDelete: () async {
            await _confirmDeleteExercise(
              context,
              exerciseIndex,
              initialExercise.name,
            );
            // Check if deleted to close sheet
            if (context.mounted &&
                mounted &&
                (exerciseIndex >= _editedWorkout.exercises.length ||
                    _editedWorkout.exercises[exerciseIndex].id !=
                        initialExercise.id)) {
              Navigator.pop(context);
            }
          },
          onEditName: () async {
            // Note: If name changes, the sheet might need to update.
            // For now, handling basic dialog show.
            await _showEditNameDialog(
              context,
              exerciseIndex,
              initialExercise.name,
            );
          },
          onHistoryTap: () {
            _showExerciseHistory(
              context,
              initialExercise.name,
              _previousSessions[initialExercise.name],
              _exercisePRs[initialExercise.name],
            );
          },
        );
      },
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
      final historyWorkouts = await workoutRepository.getWorkouts(
        userId: userId,
      );
      final historyNames = historyWorkouts
          .expand((w) => w.exercises)
          .map((e) => e.name)
          .toSet();

      if (!context.mounted) return;

      // 2. Load from plans
      final currentPlanState = context.read<PlanBloc>().state;
      if (currentPlanState is PlansLoaded) {
        final planNames = currentPlanState.plans
            .expand((p) => p.exercises)
            .map((e) => e.name)
            .toSet();
        historyNames.addAll(planNames);
      }

      availableExercises = historyNames.toList()..sort();
    } catch (e, stackTrace) {
      log(
        'Error loading suggestions',
        name: 'WorkoutEditPage',
        error: e,
        stackTrace: stackTrace,
      );
    }

    if (!context.mounted) return;

    await AppDialogs.showExerciseEntryDialog(
      context: context,
      title: 'Rename Exercise',
      initialValue: currentName,
      suggestions: availableExercises,
      onConfirm: (newName) {
        _updateExerciseName(index, newName);
      },
    );
  }

  void _updateExerciseName(int index, String newName) {
    setState(() {
      final updatedExercises = List<SessionExercise>.from(
        _editedWorkout.exercises,
      );
      if (index < updatedExercises.length) {
        updatedExercises[index] = updatedExercises[index].copyWith(
          name: newName,
        );
        _editedWorkout = _editedWorkout.copyWith(exercises: updatedExercises);
        _loadHistoryAndPRsRecursive(newName);
      }
    });
  }

  Future<void> _confirmDeleteExercise(
    BuildContext context,
    int index,
    String name,
  ) async {
    final confirm = await AppDialogs.showConfirmationDialog(
      context: context,
      title: 'Remove Exercise',
      message: 'Are you sure you want to remove "$name"?',
      confirmText: 'Remove',
      isDangerous: true,
    );

    if (confirm == true) {
      _removeExercise(index);
    }
  }

  void _removeExercise(int index) {
    setState(() {
      final updatedExercises = List<SessionExercise>.from(
        _editedWorkout.exercises,
      );
      if (index < updatedExercises.length) {
        updatedExercises.removeAt(index);
        // re-number
        for (int i = 0; i < updatedExercises.length; i++) {
          updatedExercises[i] = updatedExercises[i].copyWith(order: i);
        }
        _editedWorkout = _editedWorkout.copyWith(exercises: updatedExercises);
      }
    });
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
        return SessionExerciseHistorySheet(
          exerciseName: exerciseName,
          history: history,
          pr: pr,
        );
      },
    );
  }

  Future<void> _showAddExerciseDialog(BuildContext context) async {
    List<String> availableExercises = [];

    // Load suggestions
    try {
      // 1. Load from history
      const userId = '1';
      final historyWorkouts = await _workoutRepository.getWorkouts(
        userId: userId,
      );
      final historyNames = historyWorkouts
          .expand((w) => w.exercises)
          .map((e) => e.name)
          .toSet();

      if (!context.mounted) return;

      // 2. Load from plans
      final currentPlanState = context.read<PlanBloc>().state;
      if (currentPlanState is PlansLoaded) {
        final planNames = currentPlanState.plans
            .expand((p) => p.exercises)
            .map((e) => e.name)
            .toSet();
        historyNames.addAll(planNames);
      } else {
        context.read<PlanBloc>().add(const PlansFetchRequested(userId: userId));
      }

      availableExercises = historyNames.toList()..sort();
    } catch (e, stackTrace) {
      log(
        'Error loading suggestions',
        name: 'WorkoutEditPage',
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
        _addExercise(exerciseName);
      },
    );
  }

  void _addExercise(String name) {
    setState(() {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final newExerciseIndex = _editedWorkout.exercises.length;

      final newExercise = SessionExercise(
        id: 'ex_${timestamp}_$newExerciseIndex',
        name: name,
        order: newExerciseIndex,
        sets: [
          ExerciseSet(
            id: 'set_${timestamp}_ex${newExerciseIndex}_s1',
            setNumber: 1,
            segments: [
              SetSegment(
                id: 'seg_${timestamp}_ex${newExerciseIndex}_s1_0',
                weight: 0.0,
                repsFrom: 1,
                repsTo: 12,
                segmentOrder: 0,
                notes: '',
              ),
            ],
          ),
        ],
      );

      final updatedExercises = List<SessionExercise>.from(
        _editedWorkout.exercises,
      )..add(newExercise);

      _editedWorkout = _editedWorkout.copyWith(exercises: updatedExercises);

      // Also load history/PR for this new exercise immediately
      _loadHistoryAndPRsRecursive(name);
    });
  }

  Future<void> _loadHistoryAndPRsRecursive(String name) async {
    const userId = '1';
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

  void _showReorderExercisesSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
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
                            style: Theme.of(context).textTheme.titleLarge
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
                        itemCount: _editedWorkout.exercises.length,
                        onReorder: (oldIndex, newIndex) {
                          setState(() {
                            final updatedExercises = List<SessionExercise>.from(
                              _editedWorkout.exercises,
                            );
                            if (oldIndex < newIndex) {
                              newIndex -= 1;
                            }
                            final item = updatedExercises.removeAt(oldIndex);
                            updatedExercises.insert(newIndex, item);

                            // Fix order index
                            for (var i = 0; i < updatedExercises.length; i++) {
                              updatedExercises[i] = updatedExercises[i]
                                  .copyWith(order: i);
                            }

                            _editedWorkout = _editedWorkout.copyWith(
                              exercises: updatedExercises,
                            );
                          });
                        },
                        itemBuilder: (context, index) {
                          final ex = _editedWorkout.exercises[index];
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

class _ExerciseEditSheet extends StatefulWidget {
  final SessionExercise initialExercise;
  final int exerciseIndex;
  final SessionExercise? history;
  final SetSegment? pr;
  final Function(SessionExercise) onSave;
  final VoidCallback onDelete;
  final VoidCallback? onEditName;
  final VoidCallback? onHistoryTap;

  const _ExerciseEditSheet({
    required this.initialExercise,
    required this.exerciseIndex,
    this.history,
    this.pr,
    required this.onSave,
    required this.onDelete,
    this.onEditName,
    this.onHistoryTap,
  });

  @override
  State<_ExerciseEditSheet> createState() => _ExerciseEditSheetState();
}

class _ExerciseEditSheetState extends State<_ExerciseEditSheet> {
  late SessionExercise _currentExercise;
  bool _isEditing = false; // Start in view mode for smooth initial load
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _saveButtonKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _currentExercise = widget.initialExercise;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      if (_saveButtonKey.currentContext != null) {
        Scrollable.ensureVisible(
          _saveButtonKey.currentContext!,
          duration: const Duration(milliseconds: 500),
          curve: Curves.fastOutSlowIn,
        );
      } else if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 500),
          curve: Curves.fastOutSlowIn,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: AppColors.darkBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Stack(
        children: [
          Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textSecondary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Content
              Expanded(child: _isEditing ? _buildEditMode() : _buildViewMode()),
            ],
          ),

          // Floating Edit Button (only in view mode)
          if (!_isEditing)
            Positioned(
              bottom: 24,
              right: 16,
              left: 16,
              child: FilledButton.icon(
                onPressed: () => setState(() => _isEditing = true),
                icon: const Icon(Icons.edit_rounded),
                label: const Text('Edit Exercise'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// VIEW MODE - Lightweight read-only widget for smooth scrolling
  Widget _buildViewMode() {
    final sets = _currentExercise.sets;

    return ListView(
      controller: _scrollController,
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        16,
        0,
        16,
        100,
      ), // Extra padding for FAB
      children: [
        ExerciseViewHeader(
          exercise: _currentExercise,
          history: widget.history,
          pr: widget.pr,
          onHistoryTap: widget.onHistoryTap,
        ),
        const SizedBox(height: 16),
        ...sets.map(
          (set) => ViewSetRow(key: ValueKey('view_set_${set.id}'), set: set),
        ),
      ],
    );
  }

  /// EDIT MODE - Full editable widgets with TextFields
  Widget _buildEditMode() {
    return SingleChildScrollView(
      controller: _scrollController,
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: Column(
        children: [
          SessionExerciseCard(
            exercise: _currentExercise,
            exerciseIndex: widget.exerciseIndex,
            history: widget.history,
            pr: widget.pr,
            isAlwaysExpanded: true,
            onSkipToggle: () {
              setState(() {
                _currentExercise = _currentExercise.copyWith(
                  skipped: !_currentExercise.skipped,
                );
              });
            },
            onUpdateSegment: (setIndex, segmentIndex, field, value) {
              setState(() {
                final currentSets = List<ExerciseSet>.from(
                  _currentExercise.sets,
                );
                final currentSegments = List<SetSegment>.from(
                  currentSets[setIndex].segments,
                );

                final segment = currentSegments[segmentIndex];
                final updatedSegment = segment.copyWith(
                  weight: field == 'weight' ? value as double : segment.weight,
                  repsFrom: field == 'repsFrom'
                      ? value as int
                      : segment.repsFrom,
                  repsTo: field == 'repsTo' ? value as int : segment.repsTo,
                  notes: field == 'notes' ? value as String : segment.notes,
                );

                currentSegments[segmentIndex] = updatedSegment;
                currentSets[setIndex] = currentSets[setIndex].copyWith(
                  segments: currentSegments,
                );
                _currentExercise = _currentExercise.copyWith(sets: currentSets);
              });
            },
            onHistoryTap: widget.onHistoryTap ?? () {},
            onAddSet: () {
              setState(() {
                final currentSets = List<ExerciseSet>.from(
                  _currentExercise.sets,
                );
                final timestamp = DateTime.now().millisecondsSinceEpoch;

                final newSet = ExerciseSet(
                  id: 'set_${timestamp}_${currentSets.length}',
                  setNumber: currentSets.length + 1,
                  segments: [
                    SetSegment(
                      id: 'seg_${timestamp}_${currentSets.length}_0',
                      weight: 0.0,
                      repsFrom: 1,
                      repsTo: 12,
                      notes: '',
                      segmentOrder: 0,
                    ),
                  ],
                );

                currentSets.add(newSet);
                _currentExercise = _currentExercise.copyWith(sets: currentSets);
                _scrollToBottom();
              });
            },
            onRemoveSet: (setIndex) {
              setState(() {
                final currentSets = List<ExerciseSet>.from(
                  _currentExercise.sets,
                );
                if (setIndex < currentSets.length) {
                  currentSets.removeAt(setIndex);
                  for (int i = 0; i < currentSets.length; i++) {
                    currentSets[i] = currentSets[i].copyWith(setNumber: i + 1);
                  }
                  _currentExercise = _currentExercise.copyWith(
                    sets: currentSets,
                  );
                }
              });
            },
            onAddDropSet: (setIndex) {
              setState(() {
                final currentSets = List<ExerciseSet>.from(
                  _currentExercise.sets,
                );
                if (setIndex < currentSets.length) {
                  final targetSet = currentSets[setIndex];
                  final segments = List<SetSegment>.from(targetSet.segments);
                  final timestamp = DateTime.now().millisecondsSinceEpoch;

                  segments.add(
                    SetSegment(
                      id: 'seg_${timestamp}_${setIndex}_${segments.length}',
                      weight: 0.0,
                      repsFrom: 1,
                      repsTo: 12,
                      notes: '',
                      segmentOrder: segments.length,
                    ),
                  );

                  currentSets[setIndex] = targetSet.copyWith(
                    segments: segments,
                  );
                  _currentExercise = _currentExercise.copyWith(
                    sets: currentSets,
                  );
                }
              });
            },
            onRemoveDropSet: (setIndex, segmentIndex) {
              setState(() {
                final currentSets = List<ExerciseSet>.from(
                  _currentExercise.sets,
                );
                if (setIndex < currentSets.length) {
                  final targetSet = currentSets[setIndex];
                  final segments = List<SetSegment>.from(targetSet.segments);

                  if (segmentIndex < segments.length) {
                    segments.removeAt(segmentIndex);
                    for (int i = 0; i < segments.length; i++) {
                      segments[i] = segments[i].copyWith(segmentOrder: i);
                    }
                    currentSets[setIndex] = targetSet.copyWith(
                      segments: segments,
                    );
                    _currentExercise = _currentExercise.copyWith(
                      sets: currentSets,
                    );
                  }
                }
              });
            },
            onEditName:
                widget.onEditName ??
                (_currentExercise.isTemplate ? null : () {}),
            onDelete: widget.onDelete,
          ),

          // Save Button
          Padding(
            key: _saveButtonKey,
            padding: const EdgeInsets.only(top: 24, bottom: 32),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => widget.onSave(_currentExercise),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Save',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
