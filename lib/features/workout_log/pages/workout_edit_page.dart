import '../../../core/utils/app_logger.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/colors.dart';

import '../../../shared/widgets/app_dialogs.dart';
import '../../../shared/widgets/workout_form_widgets.dart';
import '../../../core/models/workout_session.dart';
import '../../../core/models/personal_record.dart';
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
  final Map<String, WorkoutSession> _previousSessions = {};
  final Map<String, PersonalRecord> _exercisePRs = {};

  @override
  void initState() {
    super.initState();
    _editedWorkout = widget.workout;
    _loadHistoryAndPRs();
  }

  Future<void> _loadHistoryAndPRs() async {
    final exercises = _editedWorkout.exercises;

    for (final exercise in exercises) {
      _loadHistoryAndPRsRecursive(exercise.name, variation: exercise.variation);
    }
  }

  void _saveChanges() {
    final allSkipped = _editedWorkout.exercises.every((e) => e.skipped);
    if (allSkipped || _editedWorkout.exercises.isEmpty) {
      _showEmptyWorkoutConfirmation();
      return;
    }

    AppDialogs.showConfirmationDialog(
      context: context,
      title: 'Save Changes',
      message: 'Are you sure you want to save these changes?',
      confirmText: 'Save',
    ).then((confirm) {
      if (confirm == true && mounted) {
        const userId = AppConstants.defaultUserId;
        final workoutId = _editedWorkout.id;

        final workoutData = _editedWorkout.toMap();
        context.read<WorkoutBloc>().add(
              WorkoutUpdated(
                userId: userId,
                workoutId: workoutId,
                workoutData: workoutData,
              ),
            );
      }
    });
  }

  bool _allowPop = false;

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
            setState(() {
              _allowPop = true;
            });
            AppDialogs.showSuccessDialog(
              context: context,
              title: 'Success',
              message: 'Workout updated successfully.',
              onConfirm: () {
                // Extract context before pop
                final currentContext = context;
                Navigator.pop(currentContext);
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
        child: PopScope(
          canPop: _allowPop,
          onPopInvokedWithResult: (didPop, result) async {
            if (didPop) return;
            _handleBack();
          },
          child: Align(
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
                    title: const Text('Edit Workout'),
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
                      IconButton(
                        icon: const Icon(
                          Icons.delete_rounded,
                          color: AppColors.error,
                        ),
                        tooltip: 'Delete Workout',
                        onPressed: () => _confirmDeleteWorkout(context),
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
                              workoutDate: workoutDate,
                              startedAt: _editedWorkout.startedAt,
                              endedAt: _editedWorkout.endedAt,
                              onTap: () async {
                                final result =
                                    await showDialog<Map<String, DateTime?>>(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (context) => WorkoutDateTimeDialog(
                                    initialWorkoutDate: workoutDate,
                                    initialStartedAt: _editedWorkout.startedAt,
                                    initialEndedAt: _editedWorkout.endedAt,
                                  ),
                                );
                                if (result != null) {
                                  setState(() {
                                    _editedWorkout = _editedWorkout.copyWith(
                                      workoutDate: result['workoutDate'] ??
                                          _editedWorkout.workoutDate,
                                      startedAt: result['startedAt'],
                                      endedAt: result['endedAt'],
                                    );
                                  });
                                }
                              },
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
                          child: Stack(
                            children: [
                              ExerciseListSummaryCard(
                                exercise: exercise,
                                index: exIndex,
                                onTap: () =>
                                    _showExerciseEditSheet(context, exIndex),
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: IconButton(
                                  icon: const Icon(Icons.delete_rounded),
                                  color: AppColors.error,
                                  iconSize: 20,
                                  padding: const EdgeInsets.all(8),
                                  constraints: const BoxConstraints(),
                                  onPressed: () {
                                    AppDialogs.showConfirmationDialog(
                                      context: context,
                                      title: 'Delete Exercise',
                                      message: 'Are you sure you want to delete "${exercise.name}"?',
                                      confirmText: 'Delete',
                                      isDangerous: true,
                                    ).then((confirmed) {
                                      if (confirmed == true) {
                                        _removeExercise(exIndex);
                                      }
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                        );
                      }, childCount: exercises.length),
                    ),
                  ),
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                      16,
                      8,
                      16,
                      MediaQuery.of(context).viewInsets.bottom > 0 ? 400 : 80,
                    ),
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
      ),
    );
  }

  void _handleBack() async {
    final hasChanges = _editedWorkout != widget.workout;

    if (!hasChanges) {
      setState(() {
        _allowPop = true;
      });
      if (mounted) Navigator.pop(context);
      return;
    }

    final shouldDiscard = await AppDialogs.showUnsavedChangesDialog(
      context: context,
    );

    if (shouldDiscard == true && mounted) {
      setState(() {
        _allowPop = true;
      });
      Navigator.pop(context);
    }
  }

  void _showExerciseEditSheet(BuildContext context, int exerciseIndex) {
    // 1. Get initial data
    final initialExercise = _editedWorkout.exercises[exerciseIndex];
    final statsKey =
        '${initialExercise.name}:${initialExercise.variation}'.toLowerCase();
    final history = _previousSessions[statsKey];
    final pr = _exercisePRs[statsKey];

    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, animation, secondaryAnimation) {
        return _ExerciseEditDialog(
          initialExercise: initialExercise,
          exerciseIndex: exerciseIndex,
          history: history,
          pr: pr,
          onSave: (updatedExercise) {
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
            // Check if deleted to close dialog
            if (context.mounted &&
                mounted &&
                (exerciseIndex >= _editedWorkout.exercises.length ||
                    _editedWorkout.exercises[exerciseIndex].id !=
                        initialExercise.id)) {
              Navigator.pop(context);
            }
          },
          onRenamed: (newName, variation) {
            _updateExerciseName(exerciseIndex, newName, variation: variation);
          },
          onHistoryTap: (name, variation) {
            final statsKey = '$name:$variation'.toLowerCase();
            _showExerciseHistory(
              context,
              name,
              variation,
              _previousSessions[statsKey],
              _exercisePRs[statsKey],
            );
          },
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.95, end: 1).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            ),
            child: child,
          ),
        );
      },
    );
  }

  void _showEmptyWorkoutConfirmation() {
    AppDialogs.showConfirmationDialog(
      context: context,
      title: 'Empty Workout',
      message:
          'This workout has no completed exercises. Do you want to remove this session from history instead of saving it?',
      confirmText: 'Remove Session',
      isDangerous: true,
    ).then((confirm) {
      if (confirm == true && mounted) {
        _deleteWorkout();
      }
    });
  }

  Future<void> _confirmDeleteWorkout(BuildContext context) async {
    final confirm = await AppDialogs.showConfirmationDialog(
      context: context,
      title: 'Delete Workout',
      message:
          'Are you sure you want to delete this workout session? This action cannot be undone.',
      confirmText: 'Delete',
      isDangerous: true,
    );

    if (confirm == true && mounted) {
      _deleteWorkout();
    }
  }

  void _deleteWorkout() {
    setState(() {
      _allowPop = true;
    });
    context.read<WorkoutBloc>().add(
          WorkoutDeleted(
            userId: AppConstants.defaultUserId,
            workoutId: _editedWorkout.id,
          ),
        );
    Navigator.pop(context, true);
  }

  void _updateExerciseName(int index, String newName, {String? variation}) {
    setState(() {
      final updatedExercises = List<SessionExercise>.from(
        _editedWorkout.exercises,
      );
      if (index < updatedExercises.length) {
        final effectiveVariation =
            variation ?? updatedExercises[index].variation;
        updatedExercises[index] = updatedExercises[index].copyWith(
          name: newName,
          variation: effectiveVariation,
        );
        _editedWorkout = _editedWorkout.copyWith(exercises: updatedExercises);
        _loadHistoryAndPRsRecursive(newName, variation: effectiveVariation);
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
    String exerciseVariation,
    WorkoutSession? history,
    PersonalRecord? pr,
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
          exerciseVariation: exerciseVariation,
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
      const userId = AppConstants.defaultUserId;
      final historyNames = await _workoutRepository.getExerciseNames(
        userId: userId,
      );
      final uniqueNames = historyNames.toSet();

      if (!context.mounted) return;

      // 2. Load from plans
      final currentPlanState = context.read<PlanBloc>().state;
      if (currentPlanState is PlansLoaded) {
        final planNames = currentPlanState.plans
            .expand((p) => p.exercises)
            .map((e) => e.name)
            .toSet();
        uniqueNames.addAll(planNames);
      } else {
        context.read<PlanBloc>().add(const PlansFetchRequested(userId: userId));
      }

      availableExercises = uniqueNames.toList()..sort();
    } catch (e, stackTrace) {
      AppLogger.error('WorkoutEditPage', 'Error loading suggestions', e, stackTrace);
    }

    if (!context.mounted) return;

    AppDialogs.showExerciseEntryDialog(
      context: context,
      userId: AppConstants.defaultUserId,
      title: 'Add Exercise',
      hintText: 'Exercise Name (ex: Bench Press)',
      suggestions: availableExercises,
      onConfirm: (exerciseName, variation) {
        _addExercise(exerciseName, variation: variation);
      },
    );
  }

  void _addExercise(String name, {String variation = ''}) {
    setState(() {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final newExerciseIndex = _editedWorkout.exercises.length;

      final newExercise = SessionExercise(
        id: 'ex_${timestamp}_$newExerciseIndex',
        name: name,
        variation: variation,
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
      _loadHistoryAndPRsRecursive(name, variation: variation);
    });
  }

  Future<void> _loadHistoryAndPRsRecursive(
    String name, {
    String variation = '',
  }) async {
    const userId = AppConstants.defaultUserId;
    // Key must match the lookup format used in _showExerciseEditSheet
    final statsKey = '$name:$variation'.toLowerCase();

    final results = await Future.wait([
      _workoutRepository.getLastExerciseLog(
        userId: userId,
        exerciseName: name,
        exerciseVariation: variation,
      ),
      _workoutRepository.getExercisePR(
        userId: userId,
        exerciseName: name,
        exerciseVariation: variation,
      ),
    ]);

    if (!mounted) return;
    setState(() {
      if (results[0] != null) {
        _previousSessions[statsKey] = results[0] as WorkoutSession;
      }
      if (results[1] != null) {
        _exercisePRs[statsKey] = results[1] as PersonalRecord;
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
                              updatedExercises[i] =
                                  updatedExercises[i].copyWith(order: i);
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

class _ExerciseEditDialog extends StatefulWidget {
  final SessionExercise initialExercise;
  final int exerciseIndex;
  final WorkoutSession? history;
  final PersonalRecord? pr;
  final Function(SessionExercise) onSave;
  final VoidCallback onDelete;
  final Function(String name, String variation)? onRenamed;
  final Function(String name, String variation)? onHistoryTap;

  const _ExerciseEditDialog({
    required this.initialExercise,
    required this.exerciseIndex,
    this.history,
    this.pr,
    required this.onSave,
    required this.onDelete,
    this.onRenamed,
    this.onHistoryTap,
  });

  @override
  State<_ExerciseEditDialog> createState() => _ExerciseEditDialogState();
}

class _ExerciseEditDialogState extends State<_ExerciseEditDialog> {
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
  void didUpdateWidget(_ExerciseEditDialog oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If stats updated in parent (e.g. after rename), update local state
    // to keep _currentExercise in sync with parent's initialExercise
    if (oldWidget.initialExercise != widget.initialExercise) {
      setState(() {
        _currentExercise = widget.initialExercise;
      });
    }
  }

  Future<void> _showRenameDialog() async {
    final workoutRepository = WorkoutRepository();

    // 1. Get suggestions
    List<String> suggestions = [];
    try {
      final names = await workoutRepository.getExerciseNames(userId: AppConstants.defaultUserId);
      suggestions = names.toSet().toList()..sort();
    } catch (_) {}

    if (!mounted) return;

    AppDialogs.showExerciseEntryDialog(
      context: context,
      userId: AppConstants.defaultUserId,
      title: 'Edit Exercise',
      initialValue: _currentExercise.name,
      initialVariation: _currentExercise.variation,
      suggestions: suggestions,
      onConfirm: (newName, variation) {
        if (mounted) {
          setState(() {
            _currentExercise = _currentExercise.copyWith(
              name: newName,
              variation: variation,
            );
          });
          widget.onRenamed?.call(newName, variation);
        }
      },
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.darkBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
      insetPadding: EdgeInsets.zero,
      child: Scaffold(
        backgroundColor: AppColors.darkBg,
        appBar: AppBar(
          backgroundColor: AppColors.darkBg,
          elevation: 0,
          title: Text(_currentExercise.name),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            if (_isEditing)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: IconButton(
                  icon: const Icon(Icons.save_rounded),
                  onPressed: () {
                    widget.onSave(_currentExercise);
                  },
                ),
              ),
          ],
        ),
        body: Column(
          children: [
            // Content
            Expanded(
              child: _isEditing ? _buildEditMode() : _buildViewMode(),
            ),
          ],
        ),
      ),
    );
  }

  /// VIEW MODE - Lightweight read-only widget for smooth scrolling
  Widget _buildViewMode() {
    final sets = _currentExercise.sets;

    return ListView(
      controller: _scrollController,
      physics: const ClampingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        MediaQuery.of(context).viewInsets.bottom > 0 ? 300 : 100,
      ), // Extra padding for FAB
      children: [
        ExerciseViewHeader(
          exercise: _currentExercise,
          history: widget.history,
          pr: widget.pr,
          onHistoryTap: () => widget.onHistoryTap?.call(
            _currentExercise.name,
            _currentExercise.variation,
          ),
        ),
        const SizedBox(height: 16),
        if (!_currentExercise.skipped)
          ...sets.asMap().entries.map((entry) {
            final index = entry.key;
            final set = entry.value;
            return Padding(
              padding: EdgeInsets.only(bottom: index < sets.length - 1 ? 12 : 0),
              child: ViewSetRow(key: ValueKey('view_set_${set.id}'), set: set),
            );
          }),
        const SizedBox(height: 10),
        FilledButton.icon(
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
        const SizedBox(height: 40),
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
            onHistoryTap: () => widget.onHistoryTap?.call(
              _currentExercise.name,
              _currentExercise.variation,
            ),
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
                  repsFrom:
                      field == 'repsFrom' ? value as int : segment.repsFrom,
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
            onAddSet: () {
              setState(() {
                final currentSets = List<ExerciseSet>.from(
                  _currentExercise.sets,
                );
                final timestamp = DateTime.now().millisecondsSinceEpoch;

                // Auto-fill notes from previous set
                String initialNotes = '';
                if (currentSets.isNotEmpty) {
                  final previousSet = currentSets.last;
                  if (previousSet.segments.isNotEmpty) {
                    initialNotes = previousSet.segments.last.notes;
                  }
                }

                final newSet = ExerciseSet(
                  id: 'set_${timestamp}_${currentSets.length}',
                  setNumber: currentSets.length + 1,
                  segments: [
                    SetSegment(
                      id: 'seg_${timestamp}_${currentSets.length}_0',
                      weight: 0.0,
                      repsFrom: 1,
                      repsTo: 12,
                      notes: initialNotes,
                      segmentOrder: 0,
                    ),
                  ],
                );

                currentSets.add(newSet);
                _currentExercise = _currentExercise.copyWith(sets: currentSets);
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

                  // Auto-fill logic: From = Previous To + 1
                  int initialRepsFrom = 1;
                  int initialRepsTo = 12;

                  if (segments.isNotEmpty) {
                    final previousSegment = segments.last;
                    initialRepsFrom = previousSegment.repsTo + 1;
                    if (initialRepsTo < initialRepsFrom) {
                      initialRepsTo = initialRepsFrom;
                    }
                  }

                  segments.add(
                    SetSegment(
                      id: 'seg_${timestamp}_${setIndex}_${segments.length}',
                      weight: 0.0,
                      repsFrom: initialRepsFrom,
                      repsTo: initialRepsTo,
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
            onEditName: _showRenameDialog,
            onEditVariation: _showRenameDialog,
            onDelete: widget.onDelete,
            isLastExercise: true,
          ),

          // Save Button
          Padding(
            key: _saveButtonKey,
            padding: EdgeInsets.only(
              top: 12,
              bottom: MediaQuery.of(context).viewInsets.bottom > 0 ? 300 : 40,
            ),
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
