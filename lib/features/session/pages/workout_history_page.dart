import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/colors.dart';
import '../../../shared/widgets/shimmer_widgets.dart';
import '../../workout_log/bloc/workout_bloc.dart';
import '../../workout_log/bloc/workout_event.dart';
import '../../workout_log/bloc/workout_state.dart';
import '../../workout_log/pages/workout_detail_page.dart';
import '../../../core/models/workout_session.dart';
import '../../../core/utils/page_transitions.dart';
import '../../../shared/widgets/animations/fade_in_slide.dart';
import '../../../shared/widgets/cards/workout_session_card.dart';

class WorkoutHistoryPage extends StatefulWidget {
  const WorkoutHistoryPage({super.key});

  @override
  State<WorkoutHistoryPage> createState() => _WorkoutHistoryPageState();
}

class _WorkoutHistoryPageState extends State<WorkoutHistoryPage> {
  final ScrollController _scrollController = ScrollController();
  bool _sortDescending = true;
  String? _selectedPlanName;
  DateTimeRange? _selectedDateRange;

  bool _isLoadingMore = false; // Flag to prevent multiple fetches
  bool _isOpening = true; // For seamless navigation shimmer

  // Cache for performance optimization
  List<WorkoutSession>? _lastInputWorkouts;
  String? _lastFilterPlan;
  DateTimeRange? _lastFilterDate;
  bool? _lastSortDescending;

  // Cached results
  List<WorkoutSession> _cachedFilteredWorkouts = [];
  Map<String, List<WorkoutSession>> _cachedGroupedWorkouts = {};
  List<String> _cachedSortedKeys = [];

  @override
  void initState() {
    super.initState();
    _loadWorkouts();
    _scrollController.addListener(_onScroll);

    // Give some time for the page transition to complete before rendering heavy list
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() => _isOpening = false);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isBottom && !_isLoadingMore) {
      final state = context.read<WorkoutBloc>().state;
      if (state is WorkoutsLoaded && !state.hasReachedMax) {
        setState(() {
          _isLoadingMore = true;
        });
        context.read<WorkoutBloc>().add(
              WorkoutsFetched(offset: state.workouts.length),
            );
      }
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    // Pre-fetch earlier (at 70% scroll) for smoother experience
    return currentScroll >= (maxScroll * 0.7);
  }

  void _loadWorkouts() {
    context.read<WorkoutBloc>().add(
          const WorkoutsFetched(limit: 20, offset: 0),
        );
  }

  void _showFilterDialog(List<WorkoutSession> allWorkouts) {
    final planNames = allWorkouts
        .map((w) => w.planName)
        .where((name) => name != null && name.isNotEmpty)
        .cast<String>()
        .toSet()
        .toList();
    planNames.sort();

    // final hasNoPlan =
    //     allWorkouts.any((w) => w.planName == null || w.planName!.isEmpty);

    String? tempPlanName = _selectedPlanName;
    DateTimeRange? tempDateRange = _selectedDateRange;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(24),
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.85,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Filter Workouts',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                      ),
                      if (tempPlanName != null || tempDateRange != null)
                        TextButton(
                          onPressed: () {
                            setModalState(() {
                              tempPlanName = null;
                              tempDateRange = null;
                            });
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.error,
                          ),
                          child: const Text('Reset'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // DATE RANGE SECTION
                          Text(
                            'Date Range',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              _buildDateChip(
                                'All Time',
                                null,
                                tempDateRange,
                                (val) =>
                                    setModalState(() => tempDateRange = val),
                                context,
                              ),
                              _buildDateChip(
                                'Last 7 Days',
                                DateTimeRange(
                                  start: DateTime.now()
                                      .subtract(const Duration(days: 7)),
                                  end: DateTime.now(),
                                ),
                                tempDateRange,
                                (val) =>
                                    setModalState(() => tempDateRange = val),
                                context,
                              ),
                              _buildDateChip(
                                'Last 30 Days',
                                DateTimeRange(
                                  start: DateTime.now()
                                      .subtract(const Duration(days: 30)),
                                  end: DateTime.now(),
                                ),
                                tempDateRange,
                                (val) =>
                                    setModalState(() => tempDateRange = val),
                                context,
                              ),
                              ActionChip(
                                avatar: const Icon(Icons.date_range, size: 16),
                                label: Text(
                                  tempDateRange != null &&
                                          !_isStandardRange(tempDateRange!)
                                      ? '${DateFormat('MMM d').format(tempDateRange!.start)} - ${DateFormat('MMM d').format(tempDateRange!.end)}'
                                      : 'Custom Range',
                                ),
                                backgroundColor: AppColors.inputBg,
                                labelStyle: const TextStyle(
                                    color: AppColors.textPrimary),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                    color: tempDateRange != null &&
                                            !_isStandardRange(tempDateRange!)
                                        ? AppColors.accent
                                        : Colors.transparent,
                                  ),
                                ),
                                onPressed: () async {
                                  final picked = await showDateRangePicker(
                                    context: context,
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime.now(),
                                    initialDateRange: tempDateRange,
                                    builder: (context, child) {
                                      return Theme(
                                        data: Theme.of(context).copyWith(
                                          colorScheme: const ColorScheme.dark(
                                            primary: AppColors.accent,
                                            onPrimary: Colors.white,
                                            surface: AppColors.cardBg,
                                            onSurface: AppColors.textPrimary,
                                          ),
                                          dialogTheme: const DialogThemeData(
                                            backgroundColor: AppColors.cardBg,
                                          ),
                                        ),
                                        child: child!,
                                      );
                                    },
                                  );
                                  if (picked != null) {
                                    setModalState(() {
                                      tempDateRange = DateTimeRange(
                                          start: picked.start,
                                          end: picked.end.add(const Duration(
                                              hours: 23, minutes: 59)));
                                    });
                                  }
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          const SizedBox(height: 24),
                          Divider(color: AppColors.borderDark),
                          const SizedBox(height: 24),
                          const SizedBox(height: 24),

                          // PLANS SECTION
                          Text(
                            'Filter by Plan',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                          ),
                          const SizedBox(height: 12),
                          if (planNames.isEmpty ||
                              (planNames.length == 1 && planNames.first == '-'))
                            Center(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 24),
                                child: Text(
                                  'No plans available to filter.',
                                  style:
                                      TextStyle(color: AppColors.textSecondary),
                                ),
                              ),
                            )
                          else
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: [
                                // Always show No Plan option to avoid confusion
                                // if (hasNoPlan)
                                FilterChip(
                                  label: const Text('No Plan'),
                                  selected: tempPlanName == '',
                                  onSelected: (selected) {
                                    setModalState(() {
                                      tempPlanName = selected ? '' : null;
                                    });
                                  },
                                  backgroundColor: AppColors.inputBg,
                                  selectedColor: AppColors.accent,
                                  checkmarkColor: Colors.white,
                                  labelStyle: TextStyle(
                                    color: tempPlanName == ''
                                        ? Colors.white
                                        : AppColors.textPrimary,
                                    fontWeight: tempPlanName == ''
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(
                                      color: tempPlanName == ''
                                          ? AppColors.accent
                                          : Colors.transparent,
                                    ),
                                  ),
                                ),
                                ...planNames.map((name) {
                                  final isSelected = tempPlanName == name;
                                  return FilterChip(
                                    label: Text(name),
                                    selected: isSelected,
                                    onSelected: (selected) {
                                      setModalState(() {
                                        tempPlanName = selected ? name : null;
                                      });
                                    },
                                    backgroundColor: AppColors.inputBg,
                                    selectedColor: AppColors.accent,
                                    checkmarkColor: Colors.white,
                                    labelStyle: TextStyle(
                                      color: isSelected
                                          ? Colors.white
                                          : AppColors.textPrimary,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      side: BorderSide(
                                        color: isSelected
                                            ? AppColors.accent
                                            : Colors.transparent,
                                      ),
                                    ),
                                  );
                                }),
                              ],
                            ),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: AppColors.borderLight),
                            foregroundColor: AppColors.textPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: FilledButton(
                          onPressed: () {
                            setState(() {
                              _selectedPlanName = tempPlanName;
                              _selectedDateRange = tempDateRange;
                            });
                            Navigator.pop(context);
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.accent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Apply Filter',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: BlocListener<WorkoutBloc, WorkoutState>(
        listener: (context, state) {
          if (state is WorkoutsLoaded || state is WorkoutError) {
            if (mounted) {
              setState(() {
                _isLoadingMore = false;
              });
            }
          }
        },
        child: BlocBuilder<WorkoutBloc, WorkoutState>(
          builder: (context, state) {
            // Only show shimmer on initial load or transition
            if ((state is WorkoutInitial && _isOpening) ||
                (state is WorkoutLoading && _lastInputWorkouts == null)) {
              return const WorkoutListShimmer();
            }

            if (state is WorkoutError && _lastInputWorkouts == null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      size: 64,
                      color: AppColors.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading workouts',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      state.message,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _loadWorkouts,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.all(16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Retry',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            if (state is WorkoutsLoaded || _lastInputWorkouts != null) {
              final workoutsToUse = state is WorkoutsLoaded
                  ? state.workouts
                  : _lastInputWorkouts!;
              final hasReachedMax =
                  state is WorkoutsLoaded ? state.hasReachedMax : false;

              // Memoization: Only recompute if inputs change
              if (_lastInputWorkouts != workoutsToUse ||
                  _lastFilterPlan != _selectedPlanName ||
                  _lastFilterDate != _selectedDateRange ||
                  _lastSortDescending != _sortDescending) {
                _lastInputWorkouts = workoutsToUse;
                _lastFilterPlan = _selectedPlanName;
                _lastFilterDate = _selectedDateRange;
                _lastSortDescending = _sortDescending;

                // 1. Filter
                var filtered = List<WorkoutSession>.from(workoutsToUse);
                if (_selectedPlanName != null) {
                  if (_selectedPlanName!.isEmpty) {
                    filtered = filtered
                        .where((w) => w.planName == null || w.planName!.isEmpty)
                        .toList();
                  } else {
                    filtered = filtered
                        .where((w) => w.planName == _selectedPlanName)
                        .toList();
                  }
                }

                if (_selectedDateRange != null) {
                  filtered = filtered.where((w) {
                    return w.effectiveDate.isAfter(_selectedDateRange!.start
                            .subtract(const Duration(seconds: 1))) &&
                        w.effectiveDate.isBefore(_selectedDateRange!.end
                            .add(const Duration(seconds: 1)));
                  }).toList();
                }

                // 2. Sort
                filtered.sort((a, b) {
                  if (_sortDescending) {
                    return b.effectiveDate.compareTo(a.effectiveDate);
                  } else {
                    return a.effectiveDate.compareTo(b.effectiveDate);
                  }
                });
                _cachedFilteredWorkouts = filtered;

                // 3. Group
                _cachedGroupedWorkouts = {};
                for (final workout in filtered) {
                  final monthYear =
                      DateFormat('MMMM yyyy').format(workout.effectiveDate);
                  if (!_cachedGroupedWorkouts.containsKey(monthYear)) {
                    _cachedGroupedWorkouts[monthYear] = [];
                  }
                  _cachedGroupedWorkouts[monthYear]!.add(workout);
                }
                _cachedSortedKeys = _cachedGroupedWorkouts.keys.toList();
              }

              final workouts = _cachedFilteredWorkouts;

              return CustomScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverAppBar(
                    pinned: true,
                    automaticallyImplyLeading: false,
                    leadingWidth: 56,
                    leading: const SizedBox.shrink(),
                    title: const Text('Workout History'),
                    actions: [
                      IconButton(
                        icon: Icon(
                          _sortDescending
                              ? Icons.arrow_downward_rounded
                              : Icons.arrow_upward_rounded,
                          color: AppColors.textPrimary,
                        ),
                        tooltip:
                            _sortDescending ? 'Newest First' : 'Oldest First',
                        onPressed: () =>
                            setState(() => _sortDescending = !_sortDescending),
                      ),
                      IconButton(
                        icon: Icon(
                          _selectedPlanName != null ||
                                  _selectedDateRange != null
                              ? Icons.filter_list_alt
                              : Icons.filter_list_rounded,
                          color: _selectedPlanName != null ||
                                  _selectedDateRange != null
                              ? AppColors.accent
                              : AppColors.textPrimary,
                        ),
                        tooltip: 'Filter by Plan',
                        onPressed: () => _showFilterDialog(workoutsToUse),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                  if (workouts.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _buildEmptyState(context),
                    )
                  else ...[
                    _buildWorkoutList(
                        _cachedGroupedWorkouts, _cachedSortedKeys),
                    if (!hasReachedMax && _isLoadingMore)
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.all(24.0),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                      ),
                  ],
                ],
              );
            }

            return const WorkoutListShimmer();
          },
        ),
      ),
    );
  }

  Widget _buildWorkoutList(Map<String, List<WorkoutSession>> groupedWorkouts,
      List<String> sortedMonthKeys) {
    // Grouping logic moved to build method for memoization

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final monthYear = sortedMonthKeys[index];
          final monthWorkouts = groupedWorkouts[monthYear]!;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Use a constant-ish header to avoid rebuilds
              _MonthHeader(title: monthYear.toUpperCase()),
              ...monthWorkouts.asMap().entries.map((entry) {
                final exerciseIndex = entry.key;
                final session = entry.value;
                return FadeInSlide(
                  index: exerciseIndex,
                  child: RepaintBoundary(
                    child: WorkoutSessionCard(
                      session: session,
                      onTap: () {
                        Navigator.push(
                          context,
                          SmoothPageRoute(
                            page: WorkoutDetailPage(
                              workout: session,
                              fromSession: false,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                );
              }),
            ],
          );
        }, childCount: sortedMonthKeys.length),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              shape: BoxShape.circle,
            ),
            child: Icon(
              _selectedPlanName != null || _selectedDateRange != null
                  ? Icons.filter_list_off_rounded
                  : Icons.history_rounded,
              size: 48,
              color: AppColors.accent.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _selectedPlanName != null || _selectedDateRange != null
                ? 'No workouts found'
                : 'No workouts yet',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
          ),
          const SizedBox(height: 12),
          Text(
            _selectedPlanName != null || _selectedDateRange != null
                ? 'Try clearing the filter or selecting a different range.'
                : 'Complete your first workout to see it here.',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
          if (_selectedPlanName != null || _selectedDateRange != null)
            Padding(
              padding: const EdgeInsets.only(top: 24),
              child: TextButton(
                onPressed: () => setState(() {
                  _selectedPlanName = null;
                  _selectedDateRange = null;
                }),
                child: const Text('Clear Filter'),
              ),
            ),
        ],
      ),
    );
  }

  bool _isStandardRange(DateTimeRange range) {
    final now = DateTime.now();
    final diff = now.difference(range.start).inDays;
    return diff == 7 || diff == 30 || diff == 365;
  }

  Widget _buildDateChip(
    String label,
    DateTimeRange? range,
    DateTimeRange? currentGroupValue,
    Function(DateTimeRange?) onSelected,
    BuildContext context,
  ) {
    final isSelected = range == null
        ? currentGroupValue == null
        : (currentGroupValue != null &&
            currentGroupValue.duration.inDays == range.duration.inDays &&
            // Simple check for "Last X Days" logic matches roughly
            currentGroupValue.start.day == range.start.day);

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (range != null) {
          final now = DateTime.now();
          final start = now.subtract(range.duration);
          onSelected(DateTimeRange(start: start, end: now));
        } else {
          onSelected(null);
        }
      },
      backgroundColor: AppColors.inputBg,
      selectedColor: AppColors.accent,
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppColors.textPrimary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? AppColors.accent : Colors.transparent,
        ),
      ),
    );
  }
}

class _MonthHeader extends StatelessWidget {
  final String title;
  const _MonthHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(
        title,
        style: TextStyle(
          color: AppColors.accent,
          fontWeight: FontWeight.bold,
          fontSize: 12,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}
