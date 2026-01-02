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

class StartWorkoutPage extends StatefulWidget {
  const StartWorkoutPage({super.key});

  @override
  State<StartWorkoutPage> createState() => _StartWorkoutPageState();
}

class _StartWorkoutPageState extends State<StartWorkoutPage> {
  WorkoutPlan? _selectedPlan;
  final _exerciseController = TextEditingController();
  final List<String> _customExercises = [];
  final Set<String> _selectedPlanExercises = {}; // Track which plan exercises to include

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

  void _showAddExerciseDialog() {
    _exerciseController.clear();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add Custom Exercise'),
        backgroundColor: AppColors.cardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _exerciseController,
                autofocus: true,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) {
                  if (_exerciseController.text.isNotEmpty) {
                    Navigator.pop(dialogContext);
                    setState(() {
                      _customExercises.add(_exerciseController.text);
                    });
                  }
                },
                decoration: InputDecoration(
                  labelText: 'Exercise Name',
                  hintText: 'e.g., Bench Press',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_exerciseController.text.isNotEmpty) {
                Navigator.pop(dialogContext);
                setState(() {
                  _customExercises.add(_exerciseController.text);
                });
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Start Workout'),
      ),
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
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
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
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () {
                              context.read<PlanBloc>().add(const PlansFetchRequested(userId: '1'));
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
                            color: AppColors.textSecondary.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No Plans Yet',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Create your first workout plan to get started',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
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
                                        ? AppColors.accent.withValues(alpha: 0.15)
                                        : AppColors.accent.withValues(alpha: 0.05),
                                    isSelected
                                        ? AppColors.accent.withValues(alpha: 0.08)
                                        : AppColors.accent.withValues(alpha: 0.02),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected ? AppColors.accent : AppColors.borderLight,
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              plan.name,
                                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '${plan.exercises.length} exercises',
                                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                color: AppColors.textSecondary,
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
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: plan.exercises
                                          .map((ex) => _ExerciseCheckItem(
                                            key: ValueKey('${plan.id}_${ex.name}'),
                                            exerciseName: ex.name,
                                            isChecked: () => _isExerciseSelected(ex.name),
                                            onTap: () => _toggleExercise(ex.name),
                                          ))
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
              // Custom exercises
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedPlan == null ? 'Add Exercises' : 'Add More Exercises',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (_customExercises.isNotEmpty)
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _customExercises.clear();
                            });
                          },
                          icon: const Icon(Icons.delete, size: 16),
                          label: const Text('Clear All'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_customExercises.isNotEmpty)
                    ...List.generate(_customExercises.length, (index) {
                      final exercise = _customExercises[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.accent.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                exercise,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                setState(() {
                                  _customExercises.removeAt(index);
                                });
                              },
                              icon: const Icon(Icons.close),
                              color: AppColors.error,
                              constraints: const BoxConstraints.tightFor(
                                width: 32,
                                height: 32,
                              ),
                              padding: EdgeInsets.zero,
                            ),
                          ],
                        ),
                      );
                    }),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _showAddExerciseDialog,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Custom Exercise'),
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
                    if (_selectedPlan != null && _selectedPlanExercises.isNotEmpty) {
                      for (var ex in _selectedPlan!.exercises) {
                        if (_selectedPlanExercises.contains(ex.name)) {
                          allExercises.add(ex.name);
                        }
                      }
                    }

                    // Add custom exercises
                    allExercises.addAll(_customExercises);

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
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: checked ? AppColors.accent.withValues(alpha: 0.2) : AppColors.inputBg,
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
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
