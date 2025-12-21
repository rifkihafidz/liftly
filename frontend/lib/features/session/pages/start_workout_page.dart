import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/colors.dart';
import '../../../core/models/workout_plan.dart';
import '../../plans/bloc/plan_bloc.dart';
import '../../plans/bloc/plan_state.dart';
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

  @override
  void dispose() {
    _exerciseController.dispose();
    super.dispose();
  }

  void _showAddExerciseDialog() {
    _exerciseController.clear();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Custom Exercise'),
        backgroundColor: AppColors.cardBg,
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _exerciseController,
                decoration: const InputDecoration(
                  labelText: 'Exercise Name',
                  hintText: 'e.g., Bench Press',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (_exerciseController.text.isNotEmpty) {
                setState(() {
                  _customExercises.add(_exerciseController.text);
                });
                Navigator.pop(context);
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
                                _selectedPlan = plan;
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
                              child: Row(
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
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      if (_customExercises.isNotEmpty)
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _customExercises.clear();
                            });
                          },
                          icon: const Icon(Icons.delete, size: 16),
                          label: const Text('Clear'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_customExercises.isNotEmpty)
                    ...List.generate(_customExercises.length, (index) {
                      final exercise = _customExercises[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.inputBg,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.borderDark,
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  exercise,
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
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
                                  constraints: const BoxConstraints.tightFor(width: 32, height: 32),
                                  padding: EdgeInsets.zero,
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
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
              const SizedBox(height: 32),
              // Start button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Combine plan exercises + custom exercises
                    final allExercises = <String>[];

                    // Add plan exercises
                    if (_selectedPlan != null) {
                      for (var ex in _selectedPlan!.exercises) {
                        allExercises.add(ex.name);
                      }
                    }

                    // Add custom exercises
                    allExercises.addAll(_customExercises);

                    if (allExercises.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Select a plan or add exercises')),
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
                    );
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
