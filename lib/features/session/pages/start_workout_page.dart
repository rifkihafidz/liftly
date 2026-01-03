import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/colors.dart';
import '../../../core/models/workout_plan.dart';

import '../../plans/bloc/plan_bloc.dart';
import '../../plans/bloc/plan_event.dart';
import '../../plans/bloc/plan_state.dart';

import 'session_page.dart';

import '../../../shared/widgets/shimmer_widgets.dart';
import '../../../shared/widgets/suggestion_text_field.dart';
import '../../workout_log/repositories/workout_repository.dart';

enum PlanSortOption { newest, oldest, aToZ, zToA }

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
  final _exerciseFocusNode = FocusNode();
  bool _isAddingExercise = false;
  final PlanSortOption _sortOption = PlanSortOption.newest;

  List<WorkoutPlan> _sortedPlans = [];
  final List<String> _availableExercises = [];
  final _workoutRepository = WorkoutRepository();
  int? _editingIndex;
  // _editingItemBackup not needed for in-place edit logic as we keep the item in list until modified
  // But we need to know we are editing.
  // Wait, if we edit in place, we should just use _editingIndex.
  // The item remains in _customExercises until we save or cancel.
  // Actually, standard pattern:
  // 1. On Edit: Set _editingIndex. Set controller text.
  // 2. On Save: Update _customExercises[_editingIndex]. Clear _editingIndex.
  // 3. On Cancel: Clear _editingIndex.
  // This means the "Display Widget" is replaced by "Edit Widget" at that index.
  // But we also need to ensure adding new exercises works.

  @override
  void initState() {
    super.initState();
    context.read<PlanBloc>().add(const PlansFetchRequested(userId: '1'));
    final state = context.read<PlanBloc>().state;
    if (state is PlansLoaded) {
      _sortedPlans = List.from(state.plans);
      _sortPlans();
    }
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
    } catch (e) {
      debugPrint('Error loading suggestions: $e');
    }
    if (mounted) {
      setState(() {
        _availableExercises.clear();
        _availableExercises.addAll(names.toList()..sort());
      });
    }
  }

  void _sortPlans() {
    switch (_sortOption) {
      case PlanSortOption.newest:
        _sortedPlans.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case PlanSortOption.oldest:
        _sortedPlans.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case PlanSortOption.aToZ:
        _sortedPlans.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
        break;
      case PlanSortOption.zToA:
        _sortedPlans.sort(
          (a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()),
        );
        break;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _selectedPlan = null;
    _customExercises.clear();
  }

  @override
  void dispose() {
    _exerciseController.dispose();
    _exerciseFocusNode.dispose();
    super.dispose();
  }

  void _submitCustomExercise() {
    final text = _exerciseController.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        if (_editingIndex != null) {
          // Update existing
          _customExercises[_editingIndex!] = _SessionQueueItem(text);
          _editingIndex = null;
        } else {
          // Add new
          _customExercises.add(_SessionQueueItem(text));
        }
        _exerciseController.clear();
        _isAddingExercise = false;
        FocusManager.instance.primaryFocus?.unfocus();
      });
    }
  }

  void _cancelAddingExercise() {
    setState(() {
      _editingIndex = null;
      _isAddingExercise = false;
      _exerciseController.clear();
      FocusManager.instance.primaryFocus?.unfocus();
    });
  }

  void _editCustomExercise(int index) {
    setState(() {
      _editingIndex = index;
      _exerciseController.text = _customExercises[index].name;
      // We do NOT remove the item.
      // We just set editing index so build method renders it differently.
      _isAddingExercise = false; // Ensure we aren't adding a new one at bottom

      // Slight delay to ensure list updates before focus request
      Future.delayed(const Duration(milliseconds: 50), () {
        _exerciseFocusNode.requestFocus();
      });
    });
  }

  void _startSession() {
    if (_selectedPlan == null && _customExercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a plan or add exercises')),
      );
      return;
    }

    final planExercises =
        _selectedPlan?.exercises.map((e) => e.name).toList() ?? [];
    final customExercises = _customExercises.map((e) => e.name).toList();
    final allExercises = [...planExercises, ...customExercises];

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) =>
            SessionPage(planId: _selectedPlan?.id, exerciseNames: allExercises),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: BlocConsumer<PlanBloc, PlanState>(
        listener: (context, state) {
          if (state is PlansLoaded) {
            setState(() {
              _sortedPlans = List.from(state.plans);
              _sortPlans();
            });
            _loadAvailableExercises();
          }
        },
        builder: (context, state) {
          // We can render the content regardless of loading state to show cached data if available
          // But normally we show shimmer if empty

          if (state is PlanLoading && _sortedPlans.isEmpty) {
            return const SafeArea(child: PlanListShimmer());
          }

          if (state is PlanError && _sortedPlans.isEmpty) {
            return Center(child: Text(state.message));
          }

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                pinned: true,
                centerTitle: false,
                backgroundColor: AppColors.darkBg,
                surfaceTintColor: AppColors.darkBg,
                title: Text(
                  'Start Workout',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                leading: IconButton(
                  icon: const Icon(
                    Icons.arrow_back,
                    color: AppColors.textPrimary,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ),

              // Plans Section
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'SELECT PLAN',
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
              ),

              if (_sortedPlans.isEmpty)
                const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Text(
                        'No plans available',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  sliver: SliverLayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.crossAxisExtent > 600;
                      if (isWide) {
                        return SliverGrid(
                          delegate: SliverChildBuilderDelegate((
                            context,
                            index,
                          ) {
                            final plan = _sortedPlans[index];
                            final isSelected = _selectedPlan?.id == plan.id;
                            return _buildPlanCard(plan, isSelected);
                          }, childCount: _sortedPlans.length),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 12,
                                crossAxisSpacing: 12,
                                childAspectRatio: 2.5,
                              ),
                        );
                      }
                      return SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final plan = _sortedPlans[index];
                          final isSelected = _selectedPlan?.id == plan.id;
                          return _buildPlanCard(plan, isSelected);
                        }, childCount: _sortedPlans.length),
                      );
                    },
                  ),
                ),

              // Custom Exercises Section
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SESSION QUEUE',
                        style: TextStyle(
                          color: AppColors.accent,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
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
                            if (_selectedPlan != null)
                              Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.accent.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppColors.accent.withValues(
                                      alpha: 0.2,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.bookmarks_rounded,
                                      color: AppColors.accent,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Selected Plan',
                                            style: TextStyle(
                                              color: AppColors.accent,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
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
                                      onPressed: () =>
                                          setState(() => _selectedPlan = null),
                                      icon: const Icon(Icons.close, size: 18),
                                      color: AppColors.textSecondary,
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                  ],
                                ),
                              ),

                            if (_customExercises.isNotEmpty)
                              ReorderableListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _customExercises.length,
                                onReorder: (oldIndex, newIndex) {
                                  setState(() {
                                    if (oldIndex < newIndex) newIndex -= 1;
                                    final item = _customExercises.removeAt(
                                      oldIndex,
                                    );
                                    _customExercises.insert(newIndex, item);
                                  });
                                },
                                itemBuilder: (context, index) {
                                  final exercise = _customExercises[index];
                                  // Check if this item is being edited
                                  if (_editingIndex == index) {
                                    return Container(
                                      key: ValueKey('editing_${exercise.id}'),
                                      margin: const EdgeInsets.only(bottom: 8),
                                      decoration: BoxDecoration(
                                        color: AppColors.cardBg,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: AppColors.accent,
                                        ),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 4,
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: SuggestionTextField(
                                              controller: _exerciseController,
                                              focusNode: _exerciseFocusNode,
                                              hintText: 'Exercise name...',
                                              suggestions: _availableExercises,
                                              onSubmitted: (_) =>
                                                  _submitCustomExercise(),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          IconButton.filled(
                                            onPressed: _submitCustomExercise,
                                            icon: const Icon(
                                              Icons.check_rounded,
                                            ),
                                            style: IconButton.styleFrom(
                                              backgroundColor:
                                                  AppColors.success,
                                            ),
                                          ),
                                          IconButton(
                                            onPressed: _cancelAddingExercise,
                                            icon: const Icon(
                                              Icons.close_rounded,
                                              color: AppColors.error,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }

                                  return Container(
                                    key: ValueKey(exercise.id),
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.darkBg,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.drag_handle_rounded,
                                          color: AppColors.textSecondary,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            exercise.name,
                                            style: const TextStyle(
                                              color: AppColors.textPrimary,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            InkWell(
                                              onTap: () =>
                                                  _editCustomExercise(index),
                                              child: const Padding(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                ),
                                                child: Icon(
                                                  Icons.edit_rounded,
                                                  size: 18,
                                                  color: AppColors.accent,
                                                ),
                                              ),
                                            ),
                                            InkWell(
                                              onTap: () => setState(
                                                () => _customExercises.removeAt(
                                                  index,
                                                ),
                                              ),
                                              child: const Padding(
                                                padding: EdgeInsets.only(
                                                  left: 4,
                                                ),
                                                child: Icon(
                                                  Icons.close,
                                                  color: AppColors.error,
                                                  size: 18,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),

                            if (_selectedPlan == null &&
                                _customExercises.isEmpty)
                              const Center(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(vertical: 24),
                                  child: Text(
                                    'Select a plan below or add custom exercises',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                              ),

                            // Only show Add button if NO edit is in progress
                            if (_editingIndex == null) ...[
                              const SizedBox(height: 16),
                              if (_isAddingExercise)
                                Container(
                                  decoration: BoxDecoration(
                                    color: AppColors.cardBg,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppColors.accent),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 4,
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: SuggestionTextField(
                                          controller: _exerciseController,
                                          focusNode: _exerciseFocusNode,
                                          hintText: 'Exercise name...',
                                          suggestions: _availableExercises,
                                          onSubmitted: (_) =>
                                              _submitCustomExercise(),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      IconButton.filled(
                                        onPressed: _submitCustomExercise,
                                        icon: const Icon(Icons.check_rounded),
                                        style: IconButton.styleFrom(
                                          backgroundColor: AppColors.success,
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: _cancelAddingExercise,
                                        icon: const Icon(
                                          Icons.close_rounded,
                                          color: AppColors.error,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              else
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: () {
                                      setState(() {
                                        _isAddingExercise = true;
                                        Future.delayed(
                                          const Duration(milliseconds: 100),
                                          () {
                                            _exerciseFocusNode.requestFocus();
                                          },
                                        );
                                      });
                                    },
                                    icon: const Icon(Icons.add_rounded),
                                    label: const Text('Add Exercise'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.accent,
                                      side: BorderSide(
                                        color: AppColors.accent.withValues(
                                          alpha: 0.5,
                                        ),
                                      ),
                                      padding: const EdgeInsets.all(16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Action Button
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 24,
                ),
                sliver: SliverToBoxAdapter(
                  child: FilledButton(
                    onPressed:
                        (_selectedPlan != null || _customExercises.isNotEmpty)
                        ? _startSession
                        : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      disabledBackgroundColor: AppColors.accent.withValues(
                        alpha: 0.3,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'START SESSION',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPlanCard(WorkoutPlan plan, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () {
            setState(() {
              if (isSelected) {
                _selectedPlan = null;
              } else {
                _selectedPlan = plan;
              }
            });
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(
                color: isSelected ? AppColors.accent : Colors.transparent,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.accent : AppColors.darkBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isSelected
                        ? Icons.check_rounded
                        : Icons.fitness_center_rounded,
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
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
                      const SizedBox(height: 4),
                      Text(
                        '${plan.exercises.length} Exercises',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
