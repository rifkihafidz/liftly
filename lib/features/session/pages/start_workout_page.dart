import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/colors.dart';
import '../../../core/models/workout_plan.dart';
import '../../../core/models/workout_session.dart';
import '../../../shared/widgets/app_dialogs.dart';
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
  final List<SessionExercise> _sessionQueue = [];
  final List<String> _availableExercises = [];
  final _workoutRepository = WorkoutRepository();
  PlanSortOption _sortOption = PlanSortOption.oldest;

  List<WorkoutPlan> _sortedPlans = [];

  // State for Paginated List UI
  int _currentPageIndex = 0;
  static const int _plansPerPage = 5;

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
        _sortedPlans = plans;
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
          _sessionQueue.add(
            SessionExercise(
              id: UniqueKey().toString(),
              name: name,
              order: _sessionQueue.length,
              sets: const [],
              isTemplate: false,
            ),
          );
        }
      },
    );
  }

  void _startSession() {
    if (_sessionQueue.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a plan or add exercises'),
          backgroundColor: AppColors.error,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    final List<SessionExercise> allExercises =
        _sessionQueue.asMap().entries.map((entry) {
      final index = entry.key;
      final ex = entry.value;
      return ex.copyWith(
        order: index,
        sets: const [], // Ensure sets are cleared for new session
      );
    }).toList();

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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Start Workout'),
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
            _loadAvailableExercises();
          }
        },
        builder: (context, state) {
          if (state is PlanLoading && _sortedPlans.isEmpty) {
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

          final plansToUse = state is PlansLoaded ? state.plans : _sortedPlans;
          final sortedPlans = List<WorkoutPlan>.from(plansToUse);
          switch (_sortOption) {
            case PlanSortOption.recent:
              sortedPlans.sort((a, b) => b.createdAt.compareTo(a.createdAt));
              break;
            case PlanSortOption.oldest:
              sortedPlans.sort((a, b) => a.createdAt.compareTo(b.createdAt));
              break;
            case PlanSortOption.alphabetical:
              sortedPlans.sort((a, b) => a.name.compareTo(b.name));
              break;
          }

          // Persistence for next build if state changes to loading/error
          _sortedPlans = sortedPlans;

          if (_sortedPlans.isNotEmpty &&
              _currentPageIndex >=
                  (_sortedPlans.length / _plansPerPage).ceil()) {
            _currentPageIndex = 0;
          }

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // 1. SELECT PLAN HEADER
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                sliver: SliverToBoxAdapter(
                  child: Text(
                    'SELECT PLAN',
                    style: TextStyle(
                      color: AppColors.accent,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),

              // 2. PLAN SELECTION LIST (Paginated)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: SliverToBoxAdapter(
                  child: _sortedPlans.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 32),
                            child: Text(
                              'No plans found.',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          ),
                        )
                      : Column(
                          children: [
                            ..._sortedPlans
                                .skip(_currentPageIndex * _plansPerPage)
                                .take(_plansPerPage)
                                .map((plan) {
                              final isSelected = _selectedPlan?.id == plan.id;
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    if (isSelected) {
                                      _selectedPlan = null;
                                      _sessionQueue.clear();
                                    } else {
                                      _selectedPlan = plan;
                                      _sessionQueue.clear();
                                      _sessionQueue.addAll(
                                        plan.exercises
                                            .map((e) => SessionExercise(
                                                  id: e.id,
                                                  name: e.name,
                                                  order: e.order,
                                                  isTemplate: true,
                                                  sets: const [],
                                                )),
                                      );
                                    }
                                  });
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.cardBg
                                        : AppColors.cardBg
                                            .withValues(alpha: 0.5),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isSelected
                                          ? AppColors.accent
                                          : Colors.white
                                              .withValues(alpha: 0.05),
                                      width: isSelected ? 2 : 1,
                                    ),
                                    boxShadow: isSelected
                                        ? [
                                            BoxShadow(
                                              color: AppColors.accent
                                                  .withValues(alpha: 0.2),
                                              blurRadius: 8,
                                              offset: const Offset(0, 4),
                                            )
                                          ]
                                        : null,
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
                                                    ? AppColors.textPrimary
                                                    : AppColors.textPrimary
                                                        .withValues(alpha: 0.8),
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '${plan.exercises.length} Exercises',
                                              style: TextStyle(
                                                color: AppColors.textSecondary,
                                                fontSize: 12,
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
                              );
                            }),
                          ],
                        ),
                ),
              ),

              // 3. PAGINATION CONTROLS
              if (_sortedPlans.length > _plansPerPage)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  sliver: SliverToBoxAdapter(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildPaginationButton(
                          icon: Icons.chevron_left_rounded,
                          isEnabled: _currentPageIndex > 0,
                          onPressed: () {
                            setState(() {
                              _currentPageIndex--;
                            });
                          },
                        ),
                        const SizedBox(width: 24),
                        Text(
                          '${_currentPageIndex + 1} / ${(_sortedPlans.length / _plansPerPage).ceil()}',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 24),
                        _buildPaginationButton(
                          icon: Icons.chevron_right_rounded,
                          isEnabled: _currentPageIndex <
                              (_sortedPlans.length / _plansPerPage).ceil() - 1,
                          onPressed: () {
                            setState(() {
                              _currentPageIndex++;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),

              // 4. EXERCISES HEADER
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
                sliver: SliverToBoxAdapter(
                  child: Text(
                    'EXERCISES',
                    style: TextStyle(
                      color: AppColors.accent,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),

              // 5. SELECTED PLAN INDICATOR (If any)
              if (_selectedPlan != null)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  sliver: SliverToBoxAdapter(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.cardBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.bookmark_rounded,
                              color: AppColors.accent,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Selected Plan',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _selectedPlan!.name,
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              setState(() {
                                _selectedPlan = null;
                                _sessionQueue.clear();
                              });
                            },
                            icon: const Icon(
                              Icons.close_rounded,
                              color: AppColors.textSecondary,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // 6. EXERCISES LIST OR EMPTY STATE
              SliverPadding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                sliver: _sessionQueue.isEmpty
                    ? SliverToBoxAdapter(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 32),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.cardBg.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: AppColors.borderDark, width: 1),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.fitness_center_outlined,
                                size: 48,
                                color: AppColors.textSecondary
                                    .withValues(alpha: 0.2),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Select a plan or add exercise\nto start your workout',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : SliverReorderableList(
                        itemCount: _sessionQueue.length,
                        onReorder: (oldIndex, newIndex) {
                          setState(() {
                            if (oldIndex < newIndex) newIndex -= 1;
                            final item = _sessionQueue.removeAt(oldIndex);
                            _sessionQueue.insert(newIndex, item);
                          });
                        },
                        itemBuilder: (context, index) {
                          final exercise = _sessionQueue[index];
                          return ReorderableDelayedDragStartListener(
                            key: ValueKey(exercise.id),
                            index: index,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: AppColors.borderDark,
                                    width: 1,
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.drag_handle_rounded,
                                    color: AppColors.textSecondary,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      exercise.name,
                                      style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.w500,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.close_rounded,
                                      color: AppColors.error,
                                      size: 16,
                                    ),
                                    constraints: const BoxConstraints(),
                                    padding: EdgeInsets.zero,
                                    onPressed: () {
                                      setState(() {
                                        _sessionQueue.removeAt(index);
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),

              // 7. ADD EXERCISE BUTTON
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
                sliver: SliverToBoxAdapter(
                  child: SizedBox(
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
                ),
              ),

              // 8. START WORKOUT BUTTON (Standard prominent button)
              if (_sessionQueue.isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  sliver: SliverToBoxAdapter(
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _startSession,
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: const Text(
                          'Start Workout',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                          backgroundColor: AppColors.accent,
                          foregroundColor: Colors.black,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

              // Bottom spacing
              SliverToBoxAdapter(child: const SizedBox(height: 48)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPaginationButton({
    required IconData icon,
    required bool isEnabled,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isEnabled
            ? AppColors.accent.withValues(alpha: 0.1)
            : AppColors.textSecondary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        onPressed: isEnabled ? onPressed : null,
        icon: Icon(
          icon,
          color: isEnabled
              ? AppColors.accent
              : AppColors.textSecondary.withValues(alpha: 0.2),
        ),
      ),
    );
  }
}
