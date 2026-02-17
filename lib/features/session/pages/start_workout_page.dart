import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/colors.dart';
import '../../../core/models/workout_plan.dart';
import '../../../core/models/workout_session.dart';

import '../../plans/bloc/plan_bloc.dart';
import '../../plans/bloc/plan_event.dart';
import '../../plans/bloc/plan_state.dart';

import 'session_page.dart';

import '../../../shared/widgets/shimmer_widgets.dart';
import '../../../shared/widgets/suggestion_text_field.dart';
import '../../workout_log/repositories/workout_repository.dart';
import '../../../core/utils/page_transitions.dart';
import '../../../shared/widgets/animations/scale_button_wrapper.dart';
import '../../../shared/widgets/animations/fade_in_slide.dart';
import '../../plans/pages/create_plan_page.dart';

enum PlanSortOption { newest, oldest, aToZ, zToA }

// _SessionQueueItem removed in favor of SessionExercise

class StartWorkoutPage extends StatefulWidget {
  const StartWorkoutPage({super.key});

  @override
  State<StartWorkoutPage> createState() => _StartWorkoutPageState();
}

class _StartWorkoutPageState extends State<StartWorkoutPage> {
  WorkoutPlan? _selectedPlan;
  final _exerciseController = TextEditingController();
  final List<SessionExercise> _customExercises = [];
  final _exerciseFocusNode = FocusNode();
  bool _isAddingExercise = false;
  PlanSortOption _sortOption = PlanSortOption.oldest;

  List<WorkoutPlan> _sortedPlans = [];
  final List<String> _availableExercises = [];
  final _workoutRepository = WorkoutRepository();
  int? _editingIndex;

  // Pagination state
  int _planPageIndex = 0;
  static const int _plansPerPage = 2;

  // Queue Pagination state
  int _queuePageIndex = 0;
  static const int _queuePerPage = 5;
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
      final historyNames = await _workoutRepository.getExerciseNames(
        userId: '1',
      );
      names.addAll(historyNames);
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

  String _getSortLabel(PlanSortOption option) {
    switch (option) {
      case PlanSortOption.newest:
        return 'Newest First';
      case PlanSortOption.oldest:
        return 'Oldest First';
      case PlanSortOption.aToZ:
        return 'Name (A-Z)';
      case PlanSortOption.zToA:
        return 'Name (Z-A)';
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

  void _addCustomExercise() {
    final name = _exerciseController.text.trim();
    if (name.isNotEmpty) {
      setState(() {
        final newItem = SessionExercise(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: name,
          order: _customExercises.length, // Ensure order is set
          sets: const [],
        );
        _customExercises.add(newItem);
      });
      _exerciseController.clear();
      _isAddingExercise = false;
      // _exerciseFocusNode.unfocus(); // Keep focus for rapid entry? Maybe better to unfocus.
      _exerciseFocusNode.requestFocus(); // Keep focus for rapid entry
    }
  }

  void _updateCustomExercise() {
    if (_editingIndex == null) return;
    final name = _exerciseController.text.trim();
    if (name.isNotEmpty) {
      final oldItem = _customExercises[_editingIndex!];
      final newItem = oldItem.copyWith(name: name);
      setState(() {
        _customExercises[_editingIndex!] = newItem;
        _editingIndex = null;
        _exerciseController.clear();
      });
      _exerciseFocusNode.unfocus();
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

  void _startSession() {
    if (_selectedPlan == null && _customExercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a plan or add exercises')),
      );
      return;
    }

    final List<SessionExercise> allExercises = [];

    allExercises.addAll(
      _customExercises.map((e) {
        // Update orders based on current list position
        return e.copyWith(
          order: _customExercises.indexOf(e),
          sets: [], // Ensure sets are cleared/initialized for new session
        );
      }).toList(),
    );

    Navigator.push(
      context,
      SmoothPageRoute(
        page: SessionPage(
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
                automaticallyImplyLeading: false,
                title: Text(
                  'Start Workout',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
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
                    itemBuilder: (context) =>
                        PlanSortOption.values.map((option) {
                      return PopupMenuItem(
                        value: option,
                        child: Row(
                          children: [
                            if (_sortOption == option)
                              const Icon(
                                Icons.check,
                                size: 16,
                                color: AppColors.accent,
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
                SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          Text(
                            'No plans available',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                SmoothPageRoute(page: const CreatePlanPage()),
                              );
                            },
                            icon: const Icon(Icons.add_rounded),
                            label: const Text('CREATE PLAN'),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.accent,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ],
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
                            return FadeInSlide(
                              index: index,
                              child: _buildPlanCard(plan, isSelected),
                            );
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
                      final plansToShow = _sortedPlans
                          .skip(_planPageIndex * _plansPerPage)
                          .take(_plansPerPage)
                          .toList();

                      return SliverToBoxAdapter(
                        child: Column(
                          children: [
                            ...plansToShow.asMap().entries.map((entry) {
                              final index = entry.key;
                              final plan = entry.value;
                              final isSelected = _selectedPlan?.id == plan.id;
                              return FadeInSlide(
                                index: index,
                                child: _buildPlanCard(plan, isSelected),
                              );
                            }),
                            if (_sortedPlans.length > _plansPerPage)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    IconButton(
                                      onPressed: _planPageIndex > 0
                                          ? () =>
                                              setState(() => _planPageIndex--)
                                          : null,
                                      icon: const Icon(
                                        Icons.chevron_left_rounded,
                                      ),
                                      color: AppColors.accent,
                                      disabledColor: AppColors.textSecondary
                                          .withValues(alpha: 0.3),
                                    ),
                                    Text(
                                      '${_planPageIndex + 1} / ${(_sortedPlans.length / _plansPerPage).ceil()}',
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: (_planPageIndex + 1) *
                                                  _plansPerPage <
                                              _sortedPlans.length
                                          ? () =>
                                              setState(() => _planPageIndex++)
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
                        ),
                      );
                    },
                  ),
                ),

              // Custom Exercises Section
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
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
                      if (_selectedPlan != null)
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.cardBg,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.accent.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.bookmarks_rounded,
                                  color: AppColors.accent,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Selected Plan',
                                      style: TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
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
                                onPressed: () =>
                                    setState(() => _selectedPlan = null),
                                icon: const Icon(Icons.close, size: 20),
                                color: AppColors.textSecondary,
                                visualDensity: VisualDensity.compact,
                              ),
                            ],
                          ),
                        ),
                      Container(
                        decoration: BoxDecoration(
                          color: _customExercises.isNotEmpty
                              ? AppColors.cardBg
                              : null,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (_customExercises.isNotEmpty) ...[
                              ..._customExercises
                                  .skip(_queuePageIndex * _queuePerPage)
                                  .take(_queuePerPage)
                                  .toList()
                                  .asMap()
                                  .entries
                                  .map((entry) {
                                final index =
                                    (_queuePageIndex * _queuePerPage) +
                                        entry.key;
                                final exercise = entry.value;

                                // Last visible item on this specific page
                                final currentVisibleCount = _customExercises
                                    .skip(_queuePageIndex * _queuePerPage)
                                    .take(_queuePerPage)
                                    .length;
                                final isLastOnPage =
                                    entry.key == currentVisibleCount - 1;

                                if (_editingIndex == index) {
                                  return FadeInSlide(
                                    index: entry.key,
                                    child: Container(
                                      key: ValueKey(
                                        'editing_${exercise.id}',
                                      ),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        border: Border(
                                          bottom: isLastOnPage
                                              ? BorderSide.none
                                              : BorderSide(
                                                  color:
                                                      Colors.white.withValues(
                                                    alpha: 0.05,
                                                  ),
                                                ),
                                        ),
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
                                                  _updateCustomExercise(),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          IconButton(
                                            onPressed: _updateCustomExercise,
                                            icon: const Icon(
                                              Icons.check_rounded,
                                              color: AppColors.success,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }

                                return FadeInSlide(
                                  index: entry.key,
                                  child: Container(
                                    key: ValueKey(exercise.id),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border(
                                        bottom: isLastOnPage
                                            ? BorderSide.none
                                            : BorderSide(
                                                color: Colors.white.withValues(
                                                  alpha: 0.05,
                                                ),
                                              ),
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
                                              height: 1.2,
                                            ),
                                          ),
                                        ),
                                        if (!exercise.isTemplate) ...[
                                          IconButton(
                                            onPressed: () {
                                              setState(() {
                                                _editingIndex = index;
                                                _exerciseController.text =
                                                    exercise.name;
                                                _exerciseFocusNode
                                                    .requestFocus();
                                              });
                                            },
                                            icon: const Icon(
                                              Icons.edit_rounded,
                                              size: 16,
                                              color: AppColors.textSecondary,
                                            ),
                                            style: IconButton.styleFrom(
                                              tapTargetSize:
                                                  MaterialTapTargetSize
                                                      .shrinkWrap,
                                            ),
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                            visualDensity:
                                                VisualDensity.compact,
                                          ),
                                          const SizedBox(width: 16),
                                          IconButton(
                                            onPressed: () {
                                              setState(() {
                                                _customExercises.removeAt(
                                                  index,
                                                );
                                                final maxPage =
                                                    ((_customExercises.length -
                                                                1) /
                                                            _queuePerPage)
                                                        .floor();
                                                // Check if we need to go back a page
                                                if (_queuePageIndex > maxPage &&
                                                    maxPage >= 0) {
                                                  _queuePageIndex = maxPage;
                                                } else if (_customExercises
                                                    .isEmpty) {
                                                  _queuePageIndex = 0;
                                                }
                                              });
                                            },
                                            icon: const Icon(
                                              Icons.close_rounded,
                                              size: 16,
                                              color: AppColors.textSecondary,
                                            ),
                                            style: IconButton.styleFrom(
                                              tapTargetSize:
                                                  MaterialTapTargetSize
                                                      .shrinkWrap,
                                            ),
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                            visualDensity:
                                                VisualDensity.compact,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                );
                              }),

                              // Queue Pagination Controls
                              if (_customExercises.length > _queuePerPage)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 4,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      IconButton(
                                        onPressed: _queuePageIndex > 0
                                            ? () => setState(
                                                  () => _queuePageIndex--,
                                                )
                                            : null,
                                        icon: const Icon(
                                          Icons.chevron_left_rounded,
                                        ),
                                        color: AppColors.accent,
                                        disabledColor: AppColors.textSecondary
                                            .withValues(alpha: 0.3),
                                        visualDensity: VisualDensity.compact,
                                      ),
                                      Text(
                                        '${_queuePageIndex + 1} / ${(_customExercises.length / _queuePerPage).ceil()}',
                                        style: const TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: (_queuePageIndex + 1) *
                                                    _queuePerPage <
                                                _customExercises.length
                                            ? () => setState(
                                                  () => _queuePageIndex++,
                                                )
                                            : null,
                                        icon: const Icon(
                                          Icons.chevron_right_rounded,
                                        ),
                                        color: AppColors.accent,
                                        disabledColor: AppColors.textSecondary
                                            .withValues(alpha: 0.3),
                                        visualDensity: VisualDensity.compact,
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                            if (_selectedPlan == null &&
                                _customExercises.isEmpty &&
                                !_isAddingExercise)
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
                      if (_editingIndex == null) ...[
                        const SizedBox(height: 16),
                        if (_isAddingExercise)
                          Container(
                            decoration: BoxDecoration(
                              color: AppColors.cardBg,
                              borderRadius: BorderRadius.circular(16),
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
                                    hintText: 'New exercise...',
                                    suggestions: _availableExercises,
                                    onSubmitted: (_) => _addCustomExercise(),
                                  ),
                                ),
                                IconButton(
                                  onPressed: _addCustomExercise,
                                  icon: const Icon(
                                    Icons.check_rounded,
                                    color: AppColors.success,
                                  ),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                                const SizedBox(width: 16),
                                IconButton(
                                  onPressed: _cancelAddingExercise,
                                  icon: const Icon(
                                    Icons.close_rounded,
                                    color: AppColors.textSecondary,
                                  ),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
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
                                padding: const EdgeInsets.all(16),
                                side: const BorderSide(color: AppColors.accent),
                                foregroundColor: AppColors.accent,
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
                      disabledBackgroundColor: AppColors.accent.withValues(
                        alpha: 0.3,
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
      child: ScaleButtonWrapper(
        child: Material(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: () {
              setState(() {
                _queuePageIndex = 0; // Reset queue pagination
                if (isSelected) {
                  _selectedPlan = null;
                  if (_customExercises.isNotEmpty) {
                    _customExercises.clear();
                  }
                } else {
                  _selectedPlan = plan;
                  _customExercises.clear();
                  _customExercises.addAll(
                    plan.exercises.map(
                      (e) => SessionExercise(
                        id: DateTime.now().millisecondsSinceEpoch.toString() +
                            e.id,
                        name: e.name,
                        order: e.order,
                        isTemplate: true,
                        sets: const [],
                      ),
                    ),
                  );
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
                      color:
                          isSelected ? Colors.white : AppColors.textSecondary,
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
      ),
    );
  }
}
