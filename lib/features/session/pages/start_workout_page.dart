import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/colors.dart';
import '../../../core/models/workout_plan.dart';
import '../../../core/models/workout_session.dart';
import '../../../shared/widgets/app_dialogs.dart';
import '../../../shared/widgets/animations/fade_in_slide.dart';
import '../../plans/bloc/plan_bloc.dart';
import '../../plans/bloc/plan_event.dart';
import '../../plans/bloc/plan_state.dart';
import '../../workout_log/repositories/workout_repository.dart';
import '../pages/session_page.dart';

enum PlanSortOption {
  recent,
  oldest,
  alphabetical,
}

class StartWorkoutPage extends StatefulWidget {
  const StartWorkoutPage({super.key});

  @override
  State<StartWorkoutPage> createState() => _StartWorkoutPageState();
}

class _StartWorkoutPageState extends State<StartWorkoutPage> {
  WorkoutPlan? _selectedPlan;
  final List<SessionExercise> _customExercises = [];
  final List<String> _availableExercises = [];
  final _workoutRepository = WorkoutRepository();
  PlanSortOption _sortOption = PlanSortOption.oldest;

  List<WorkoutPlan> _sortedPlans = [];

  // Pagination state
  int _planPageIndex = 0;
  static const int _planPerPage = 5;

  @override
  void initState() {
    super.initState();
    context.read<PlanBloc>().add(const PlansFetchRequested(userId: '1'));
    _loadAvailableExercises();
  }

  Future<void> _loadAvailableExercises() async {
    final names = <String>{};
    final planState = context.read<PlanBloc>().state;
    if (planState is PlansLoaded) {
      for (var plan in planState.plans) {
        for (var ex in plan.exercises) {
          names.add(ex.name);
        }
      }
    }
    try {
      final workouts = await _workoutRepository.getWorkouts(userId: '1');
      for (var w in workouts) {
        for (var e in w.exercises) {
          names.add(e.name);
        }
      }
    } catch (e, stackTrace) {
      log(
        'Error loading suggestions',
        name: 'StartWorkoutPage',
        error: e,
        stackTrace: stackTrace,
      );
    }

    if (mounted) {
      setState(() {
        _availableExercises.clear();
        _availableExercises.addAll(names.toList()..sort());
      });
    }
  }

  void _sortPlans() {
    final state = context.read<PlanBloc>().state;
    if (state is PlansLoaded) {
      List<WorkoutPlan> plans = List.from(state.plans);
      switch (_sortOption) {
        case PlanSortOption.recent:
          plans.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          break;
        case PlanSortOption.oldest:
          plans.sort((a, b) => a.createdAt.compareTo(b.createdAt));
          break;
        case PlanSortOption.alphabetical:
          plans.sort((a, b) => a.name.compareTo(b.name));
          break;
      }
      setState(() {
        _sortedPlans = plans;
        // Reset page index when sorting changes
        _planPageIndex = 0;
      });
    }
  }

  String _getSortLabel(PlanSortOption option) {
    switch (option) {
      case PlanSortOption.recent:
        return 'Newest First';
      case PlanSortOption.oldest:
        return 'Oldest First';
      case PlanSortOption.alphabetical:
        return 'A-Z';
    }
  }

  Future<void> _showAddExerciseDialog() async {
    // Ensure suggestions are loaded
    if (_availableExercises.isEmpty) {
      await _loadAvailableExercises();
    }

    if (!mounted) return;

    AppDialogs.showExerciseEntryDialog(
      context: context,
      title: 'Add Exercise',
      hintText: 'Exercise Name (e.g. Bench Press)',
      suggestions: _availableExercises,
      onConfirm: (name) {
        if (name.isNotEmpty) {
          setState(() {
            _customExercises.add(
              SessionExercise(
                id: UniqueKey().toString(),
                name: name,
                order: _customExercises.length,
                sets: const [],
                isTemplate: false,
              ),
            );
          });
        }
      },
    );
  }

  void _startSession() {
    if (_selectedPlan == null && _customExercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a plan or add exercises'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final List<SessionExercise> allExercises = [];

    // If a plan is selected, add its exercises first
    if (_selectedPlan != null) {
      allExercises.addAll(
        _selectedPlan!.exercises.map((e) {
          return SessionExercise(
            id: e.id,
            name: e.name,
            order: e.order,
            isTemplate: true,
            sets: const [], // Ensure sets are cleared/initialized for new session
          );
        }).toList(),
      );
    }

    // Add custom exercises after plan exercises
    allExercises.addAll(
      _customExercises.map((e) {
        // Update orders based on current list position
        return e.copyWith(
          order: allExercises.length + _customExercises.indexOf(e),
          sets: const [], // Ensure sets are cleared/initialized for new session
        );
      }).toList(),
    );

    // Navigate to SessionPage
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SessionPage(
          planId: _selectedPlan?.id,
          planName: _selectedPlan?.name,
          exercises: allExercises,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        backgroundColor: AppColors.darkBg,
        surfaceTintColor: AppColors.darkBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Start Workout',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          PopupMenuButton<PlanSortOption>(
            icon: const Icon(
              Icons.sort_rounded,
              color: AppColors.textPrimary,
            ),
            tooltip: 'Sort Plans',
            position: PopupMenuPosition.under,
            color: AppColors.darkBg,
            elevation: 0,
            surfaceTintColor: AppColors.darkBg,
            onSelected: (option) {
              setState(() {
                _sortOption = option;
                _sortPlans();
              });
            },
            itemBuilder: (context) => PlanSortOption.values.map((option) {
              return PopupMenuItem(
                value: option,
                child: Row(
                  children: [
                    if (_sortOption == option)
                      const Icon(
                        Icons.check,
                        size: 16,
                        color: AppColors.accent,
                        // weight: 24, // Check if weight is valid property for Icon, removed to be safe
                      )
                    else
                      const SizedBox(width: 16),
                    const SizedBox(width: 8),
                    Text(
                      _getSortLabel(option),
                      style: TextStyle(
                        color: _sortOption == option
                            ? AppColors.accent
                            : AppColors.textPrimary,
                        fontWeight: _sortOption == option
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: BlocConsumer<PlanBloc, PlanState>(
        listener: (context, state) {
          if (state is PlansLoaded) {
            _sortPlans();
            _loadAvailableExercises();
          }
        },
        builder: (context, state) {
          if (state is PlanLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.accent),
            );
          }

          if (state is PlanError) {
            return Center(
              child: Text(
                state.message,
                style: const TextStyle(color: AppColors.error),
              ),
            );
          }

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Plans Section
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Select Plan',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_sortedPlans.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: AppColors.cardBg,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.05),
                            ),
                          ),
                          child: const Center(
                            child: Text(
                              'No plans found',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          ),
                        )
                      else ...[
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: (_sortedPlans.length -
                                      (_planPageIndex * _planPerPage)) >
                                  _planPerPage
                              ? _planPerPage
                              : (_sortedPlans.length -
                                  (_planPageIndex * _planPerPage)),
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final actualIndex =
                                (_planPageIndex * _planPerPage) + index;
                            final plan = _sortedPlans[actualIndex];
                            final isSelected = _selectedPlan?.id == plan.id;

                            return FadeInSlide(
                              index: index,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    if (isSelected) {
                                      _selectedPlan = null;
                                    } else {
                                      _selectedPlan = plan;
                                    }
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.accent.withValues(
                                            alpha: 0.1,
                                          )
                                        : AppColors.cardBg,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isSelected
                                          ? AppColors.accent
                                          : Colors.white.withValues(
                                              alpha: 0.05,
                                            ),
                                      width: isSelected ? 2 : 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              plan.name,
                                              style: TextStyle(
                                                color: isSelected
                                                    ? AppColors.accent
                                                    : AppColors.textPrimary,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                            if (plan.description != null &&
                                                plan.description!
                                                    .isNotEmpty) ...[
                                              const SizedBox(height: 4),
                                              Text(
                                                plan.description!,
                                                style: TextStyle(
                                                  color: isSelected
                                                      ? AppColors.accent
                                                          .withValues(
                                                          alpha: 0.8,
                                                        )
                                                      : AppColors.textSecondary,
                                                  fontSize: 14,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                            const SizedBox(height: 8),
                                            Text(
                                              '${plan.exercises.length} Exercises',
                                              style: TextStyle(
                                                color: isSelected
                                                    ? AppColors.accent
                                                        .withValues(
                                                        alpha: 0.6,
                                                      )
                                                    : AppColors.textSecondary
                                                        .withValues(
                                                        alpha: 0.5,
                                                      ),
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (isSelected)
                                        const Icon(
                                          Icons.check_circle_rounded,
                                          color: AppColors.accent,
                                          size: 24,
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        // Plan Pagination Controls
                        if (_sortedPlans.length > _planPerPage)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  onPressed: _planPageIndex > 0
                                      ? () => setState(
                                            () => _planPageIndex--,
                                          )
                                      : null,
                                  icon: const Icon(
                                    Icons.chevron_left_rounded,
                                  ),
                                  color: AppColors.accent,
                                  disabledColor: AppColors.textSecondary
                                      .withValues(alpha: 0.3),
                                ),
                                Text(
                                  '${_planPageIndex + 1} / ${(_sortedPlans.length / _planPerPage).ceil()}',
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                IconButton(
                                  onPressed:
                                      (_planPageIndex + 1) * _planPerPage <
                                              _sortedPlans.length
                                          ? () => setState(
                                                () => _planPageIndex++,
                                              )
                                          : null,
                                  icon: const Icon(
                                    Icons.chevron_right_rounded,
                                  ),
                                  color: AppColors.accent,
                                  disabledColor: AppColors.textSecondary
                                      .withValues(alpha: 0.3),
                                ),
                              ],
                            ),
                          ),
                      ],

                      if (_customExercises.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        const Text(
                          'Custom Exercises',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ..._customExercises.asMap().entries.map((entry) {
                          final index = entry.key;
                          final exercise = entry.value;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.cardBg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.05),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    exercise.name,
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.close_rounded,
                                    color: AppColors.error,
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _customExercises.removeAt(index);
                                    });
                                  },
                                ),
                              ],
                            ),
                          );
                        }),
                      ],

                      const SizedBox(height: 16),

                      // Add Exercise Button (Always visible)
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _showAddExerciseDialog,
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('Add Exercise'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.all(16),
                            side: const BorderSide(color: AppColors.accent),
                            foregroundColor: AppColors.accent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      if (_selectedPlan == null && _customExercises.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 32),
                            child: Text(
                              'Select a plan or add exercises to start',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              // Bottom spacing
              SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          );
        },
      ),
      floatingActionButton:
          (_selectedPlan != null || _customExercises.isNotEmpty)
              ? FloatingActionButton.extended(
                  onPressed: _startSession,
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.black,
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text(
                    'Start Workout',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                )
              : null,
    );
  }
}
