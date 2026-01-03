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

class WorkoutHistoryPage extends StatefulWidget {
  const WorkoutHistoryPage({super.key});

  @override
  State<WorkoutHistoryPage> createState() => _WorkoutHistoryPageState();
}

class _WorkoutHistoryPageState extends State<WorkoutHistoryPage> {
  bool _sortDescending = true;
  String? _selectedPlanName;

  @override
  void initState() {
    super.initState();
    _loadWorkouts();
  }

  void _loadWorkouts() {
    context.read<WorkoutBloc>().add(const WorkoutsFetched());
  }

  void _showFilterDialog(List<WorkoutSession> allWorkouts) {
    final planNames = allWorkouts
        .map((w) => w.planName ?? '-')
        .toSet()
        .toList();
    planNames.sort();

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Filter by Plan',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (_selectedPlanName != null)
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _selectedPlanName = null;
                        });
                        Navigator.pop(context);
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.error,
                      ),
                      child: const Text('Clear Filter'),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              if (planNames.isEmpty ||
                  (planNames.length == 1 && planNames.first == '-'))
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      'No plans available to filter.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                )
              else
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: planNames.map((name) {
                    final isSelected = _selectedPlanName == name;
                    return FilterChip(
                      label: Text(name),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedPlanName = selected ? name : null;
                        });
                        Navigator.pop(context);
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
                  }).toList(),
                ),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: BlocBuilder<WorkoutBloc, WorkoutState>(
        builder: (context, state) {
          if (state is WorkoutLoading) {
            return const WorkoutListShimmer();
          }

          if (state is WorkoutError) {
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

          if (state is WorkoutsLoaded) {
            var workouts = List<WorkoutSession>.from(state.workouts);
            if (_selectedPlanName != null) {
              workouts = workouts
                  .where((w) => w.planName == _selectedPlanName)
                  .toList();
            }

            workouts.sort((a, b) {
              if (_sortDescending) {
                return b.workoutDate.compareTo(a.workoutDate);
              } else {
                return a.workoutDate.compareTo(b.workoutDate);
              }
            });

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverAppBar(
                  pinned: true,
                  centerTitle: false,
                  backgroundColor: AppColors.darkBg,
                  surfaceTintColor: AppColors.darkBg,
                  title: Text(
                    'Workout History',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),

                  actions: [
                    IconButton(
                      icon: Icon(
                        _sortDescending
                            ? Icons.arrow_downward_rounded
                            : Icons.arrow_upward_rounded,
                        color: AppColors.textPrimary,
                      ),
                      tooltip: _sortDescending
                          ? 'Newest First'
                          : 'Oldest First',
                      onPressed: () =>
                          setState(() => _sortDescending = !_sortDescending),
                    ),
                    IconButton(
                      icon: Icon(
                        _selectedPlanName != null
                            ? Icons.filter_list_alt
                            : Icons.filter_list_rounded,
                        color: _selectedPlanName != null
                            ? AppColors.accent
                            : AppColors.textPrimary,
                      ),
                      tooltip: 'Filter by Plan',
                      onPressed: () => _showFilterDialog(state.workouts),
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
                if (workouts.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _buildEmptyState(context),
                  )
                else
                  _buildWorkoutList(workouts),
              ],
            );
          }

          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  Widget _buildWorkoutList(List<WorkoutSession> workouts) {
    final groupedWorkouts = <String, List<WorkoutSession>>{};
    for (final workout in workouts) {
      final monthYear = DateFormat('MMMM yyyy').format(workout.workoutDate);
      if (!groupedWorkouts.containsKey(monthYear)) {
        groupedWorkouts[monthYear] = [];
      }
      groupedWorkouts[monthYear]!.add(workout);
    }

    final sortedMonthKeys = groupedWorkouts.keys.toList();

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final monthYear = sortedMonthKeys[index];
          final monthWorkouts = groupedWorkouts[monthYear]!;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  monthYear.toUpperCase(),
                  style: TextStyle(
                    color: AppColors.accent,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              ...monthWorkouts.map(
                (session) => _WorkoutHistoryCard(
                  session: session,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => WorkoutDetailPage(
                          workout: session,
                          fromSession: false,
                        ),
                      ),
                    ).then((_) => _loadWorkouts());
                  },
                ),
              ),
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
              _selectedPlanName != null
                  ? Icons.filter_list_off_rounded
                  : Icons.history_rounded,
              size: 48,
              color: AppColors.accent.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _selectedPlanName != null ? 'No workouts found' : 'No workouts yet',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _selectedPlanName != null
                ? 'Try clearing the filter or selecting a different plan.'
                : 'Complete your first workout to see it here.',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
          if (_selectedPlanName != null)
            Padding(
              padding: const EdgeInsets.only(top: 24),
              child: TextButton(
                onPressed: () => setState(() => _selectedPlanName = null),
                child: const Text('Clear Filter'),
              ),
            ),
        ],
      ),
    );
  }
}

class _WorkoutHistoryCard extends StatelessWidget {
  final WorkoutSession session;
  final VoidCallback onTap;

  const _WorkoutHistoryCard({required this.session, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final exercises = session.exercises.where((e) => !e.skipped).toList();
    final totalSets = exercises.fold(0, (sum, e) => sum + e.sets.length);
    final volume = session.totalVolume;
    final planName = session.planName ?? '-';

    String formattedVolume = '${volume.toInt()}';
    if (volume >= 1000) {
      formattedVolume = '${(volume / 1000).toStringAsFixed(1)}k';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            DateFormat(
                              'EEEE, d MMM',
                            ).format(session.workoutDate),
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            session.formattedDuration,
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (planName != '-')
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          planName,
                          style: TextStyle(
                            color: AppColors.accent,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _StatBadge(
                      icon: Icons.fitness_center_rounded,
                      label: '${exercises.length} Exercises',
                      color: const Color(0xFF6366F1), // Indigo
                    ),
                    const SizedBox(width: 8),
                    _StatBadge(
                      icon: Icons.repeat_rounded,
                      label: '$totalSets Sets',
                      color: const Color(0xFF10B981), // Emerald
                    ),
                    const SizedBox(width: 8),
                    _StatBadge(
                      icon: Icons.scale_rounded,
                      label: '$formattedVolume kg',
                      color: const Color(0xFFF59E0B), // Amber
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
