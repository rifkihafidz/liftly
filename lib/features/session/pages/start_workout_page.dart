import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/colors.dart';
import '../../../core/models/workout_plan.dart';
import '../../../shared/widgets/app_dialogs.dart';
import '../../plans/bloc/plan_bloc.dart';
import '../../plans/bloc/plan_event.dart';
import '../../plans/bloc/plan_state.dart';
import '../../plans/pages/create_plan_page.dart';
import 'session_page.dart';

class _SessionQueueItem {
  final String id;
  final String name;
  _SessionQueueItem(this.name) : id = UniqueKey().toString();
}

class StartWorkoutPage extends StatefulWidget {
  const StartWorkoutPage({super.key});

  @override
  State<StartWorkoutPage> createState() => _StartWorkoutPageState();
}

class _StartWorkoutPageState extends State<StartWorkoutPage> {
  WorkoutPlan? _selectedPlan;
  final _exerciseController = TextEditingController();
  final List<_SessionQueueItem> _customExercises = [];
  final Set<String> _selectedPlanExercises =
      {}; // Track which plan exercises to include
  final _exerciseFocusNode = FocusNode();
  bool _isAddingExercise = false;

  @override
  void initState() {
    super.initState();
    // Fetch plans when page is opened
    context.read<PlanBloc>().add(const PlansFetchRequested(userId: '1'));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reset selections every time this page is visited (when returning from SessionPage)
    _selectedPlan = null;
    _customExercises.clear();
    _selectedPlanExercises.clear();
  }

  @override
  void dispose() {
    _exerciseController.dispose();
    _exerciseFocusNode.dispose();
    super.dispose();
  }

  void _toggleExercise(String exerciseName) {
    setState(() {
      if (_selectedPlanExercises.contains(exerciseName)) {
        _selectedPlanExercises.remove(exerciseName);
      } else {
        _selectedPlanExercises.add(exerciseName);
      }
    });
  }

  bool _isExerciseSelected(String exerciseName) {
    return _selectedPlanExercises.contains(exerciseName);
  }

  // No popup dialog, inline addition
  void _submitCustomExercise() {
    final text = _exerciseController.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        _customExercises.add(_SessionQueueItem(text));
        _exerciseController.clear();
        _isAddingExercise = false; // Close form after adding
        FocusManager.instance.primaryFocus?.unfocus();
      });
    }
  }

  void _cancelAddingExercise() {
    setState(() {
      _isAddingExercise = false;
      _exerciseController.clear();
      FocusManager.instance.primaryFocus?.unfocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Start Workout')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Choose a Plan or Create Freestyle',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Select an existing plan or add custom exercises',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              // Plans list
              BlocBuilder<PlanBloc, PlanState>(
                builder: (context, state) {
                  if (state is PlanLoading) {
                    return Center(
                      child: Column(
                        children: [
                          const SizedBox(height: 32),
                          const CircularProgressIndicator(),
                          const SizedBox(height: 16),
                          Text(
                            'Loading plans...',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 32),
                        ],
                      ),
                    );
                  }
                  if (state is PlanError) {
                    return Center(
                      child: Column(
                        children: [
                          const SizedBox(height: 32),
                          Icon(
                            Icons.error_outline,
                            size: 48,
                            color: AppColors.accent,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Failed to load plans',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            state.message,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppColors.textSecondary),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () {
                              context.read<PlanBloc>().add(
                                const PlansFetchRequested(userId: '1'),
                              );
                            },
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry'),
                          ),
                          const SizedBox(height: 32),
                        ],
                      ),
                    );
                  }
                  if (state is PlansLoaded && state.plans.isEmpty) {
                    return Center(
                      child: Column(
                        children: [
                          const SizedBox(height: 32),
                          Icon(
                            Icons.fitness_center_outlined,
                            size: 64,
                            color: AppColors.textSecondary.withValues(
                              alpha: 0.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No Plans Yet',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Create your first workout plan to get started',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: AppColors.textSecondary),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const CreatePlanPage(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.add),
                            label: const Text('Create Plan'),
                          ),
                          const SizedBox(height: 32),
                        ],
                      ),
                    );
                  }
                  if (state is PlansLoaded && state.plans.isNotEmpty) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your Plans',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        ...state.plans.map((plan) {
                          final isSelected = _selectedPlan?.id == plan.id;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                if (isSelected) {
                                  // Deselect the plan
                                  _selectedPlan = null;
                                  _selectedPlanExercises.clear();
                                } else {
                                  // Select the plan
                                  _selectedPlan = plan;
                                  // Select all exercises from this plan by default
                                  _selectedPlanExercises.clear();
                                  for (var ex in plan.exercises) {
                                    _selectedPlanExercises.add(ex.name);
                                  }
                                }
                              });
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    isSelected
                                        ? AppColors.accent.withValues(
                                            alpha: 0.15,
                                          )
                                        : AppColors.accent.withValues(
                                            alpha: 0.05,
                                          ),
                                    isSelected
                                        ? AppColors.accent.withValues(
                                            alpha: 0.08,
                                          )
                                        : AppColors.accent.withValues(
                                            alpha: 0.02,
                                          ),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.accent
                                      : AppColors.borderLight,
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              plan.name,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleMedium
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '${plan.exercises.length} exercises',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall
                                                  ?.copyWith(
                                                    color:
                                                        AppColors.textSecondary,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (isSelected)
                                        Icon(
                                          Icons.check_circle,
                                          color: AppColors.accent,
                                          size: 28,
                                        ),
                                    ],
                                  ),
                                  if (isSelected) ...[
                                    const SizedBox(height: 12),
                                    Text(
                                      'Exercises:',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: AppColors.textSecondary,
                                          ),
                                    ),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: plan.exercises
                                          .map(
                                            (ex) => _ExerciseCheckItem(
                                              key: ValueKey(
                                                '${plan.id}_${ex.name}',
                                              ),
                                              exerciseName: ex.name,
                                              isChecked: () =>
                                                  _isExerciseSelected(ex.name),
                                              onTap: () =>
                                                  _toggleExercise(ex.name),
                                            ),
                                          )
                                          .toList(),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        }),
                        const SizedBox(height: 24),
                      ],
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
              // Custom Exercises Section
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Custom Exercises',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      if (_customExercises.isNotEmpty)
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _customExercises.clear();
                            });
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.error,
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(50, 30),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text('Clear All'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Selected custom exercises list
                  if (_customExercises.isNotEmpty)
                    ReorderableListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _customExercises.length,
                      onReorder: (oldIndex, newIndex) {
                        setState(() {
                          if (oldIndex < newIndex) {
                            newIndex -= 1;
                          }
                          final item = _customExercises.removeAt(oldIndex);
                          _customExercises.insert(newIndex, item);
                        });
                      },
                      itemBuilder: (context, index) {
                        final exercise = _customExercises[index];
                        return Container(
                          key: ValueKey(exercise.id),
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.accent.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.drag_handle,
                                    color: AppColors.textSecondary,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    exercise.name,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w500,
                                          color: AppColors.textPrimary,
                                        ),
                                  ),
                                ],
                              ),
                              InkWell(
                                onTap: () {
                                  setState(() {
                                    _customExercises.removeAt(index);
                                  });
                                },
                                child: Icon(
                                  Icons.close,
                                  size: 20,
                                  color: AppColors.error,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                  // Dynamic Input Field vs Button
                  // Input Field (visible when adding)
                  if (_isAddingExercise) ...[
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.inputBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.accent),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      child: ValueListenableBuilder<TextEditingValue>(
                        valueListenable: _exerciseController,
                        builder: (context, value, child) {
                          final isEnabled = value.text.trim().isNotEmpty;
                          return Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _exerciseController,
                                  focusNode: _exerciseFocusNode,
                                  autofocus: true,
                                  textInputAction: TextInputAction.done,
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(color: AppColors.textPrimary),
                                  decoration: InputDecoration(
                                    hintText: 'Enter exercise name...',
                                    hintStyle: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                    border: InputBorder.none,
                                  ),
                                  onSubmitted: (_) {
                                    if (isEnabled) _submitCustomExercise();
                                  },
                                ),
                              ),
                              IconButton(
                                onPressed: isEnabled
                                    ? _submitCustomExercise
                                    : null,
                                icon: const Icon(Icons.check),
                                color: isEnabled
                                    ? AppColors.success
                                    : AppColors.textSecondary,
                                tooltip: 'Add',
                              ),
                              IconButton(
                                onPressed: _cancelAddingExercise,
                                icon: const Icon(Icons.close),
                                color: AppColors.error,
                                tooltip: 'Cancel',
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Add Button (Always visible)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _isAddingExercise
                          ? null // Disable if already adding
                          : () {
                              setState(() {
                                _isAddingExercise = true;
                              });
                            },
                      icon: const Icon(Icons.add),
                      label: const Text('Add Custom Exercise'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                        side: BorderSide(
                          color: _isAddingExercise
                              ? AppColors.borderLight.withValues(alpha: 0.3)
                              : AppColors.borderLight,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Start button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Combine selected plan exercises + custom exercises
                    final allExercises = <String>[];

                    // Add selected plan exercises (in order)
                    if (_selectedPlan != null &&
                        _selectedPlanExercises.isNotEmpty) {
                      for (var ex in _selectedPlan!.exercises) {
                        if (_selectedPlanExercises.contains(ex.name)) {
                          allExercises.add(ex.name);
                        }
                      }
                    }

                    // Add custom exercises
                    allExercises.addAll(_customExercises.map((e) => e.name));

                    if (allExercises.isEmpty) {
                      AppDialogs.showErrorDialog(
                        context: context,
                        title: 'Exercises Required',
                        message: 'Select a plan or add exercises first.',
                      );
                      return;
                    }

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SessionPage(
                          exerciseNames: allExercises,
                          planId: _selectedPlan?.id,
                        ),
                      ),
                    ).then((_) {
                      // Reset state when user returns from SessionPage
                      setState(() {
                        _selectedPlan = null;
                        _customExercises.clear();
                        _selectedPlanExercises.clear();
                      });
                    });
                  },
                  child: const Text('Start Workout'),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExerciseCheckItem extends StatelessWidget {
  final String exerciseName;
  final bool Function() isChecked;
  final VoidCallback onTap;

  const _ExerciseCheckItem({
    super.key,
    required this.exerciseName,
    required this.isChecked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Builder(
        builder: (context) {
          final checked = isChecked();
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: checked
                  ? AppColors.accent.withValues(alpha: 0.2)
                  : AppColors.inputBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: checked ? AppColors.accent : AppColors.borderLight,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  checked ? Icons.check_box : Icons.check_box_outline_blank,
                  size: 16,
                  color: checked ? AppColors.accent : AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  exerciseName,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.textPrimary),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
