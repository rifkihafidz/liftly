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
    // Load workouts from API
    _loadWorkouts();
  }

  void _loadWorkouts() {
    context.read<WorkoutBloc>().add(const WorkoutsFetched());
  }

  void _showFilterDialog(List<WorkoutSession> allWorkouts) {
    // Extract unique plan names, defaulting to '-' for nulls
    // Use Set to ensure uniqueness, remove nulls/empty if desired, but here we explicitly track '-'
    final planNames = allWorkouts
        .map((w) => w.planName ?? '-')
        .toSet()
        .toList();
    // Sort alphabetically
    planNames.sort();

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
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
                      fontWeight: FontWeight.w600,
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
                      child: const Text('Clear Filter'),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              if (planNames.isEmpty ||
                  (planNames.length == 1 && planNames.first == '-'))
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: Text('No plans available to filter.')),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
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
                      selectedColor: AppColors.accent.withValues(alpha: 0.2),
                      checkmarkColor: AppColors.accent,
                      labelStyle: TextStyle(
                        color: isSelected
                            ? AppColors.accent
                            : AppColors.textPrimary,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                          color: isSelected
                              ? AppColors.accent
                              : AppColors.borderLight,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Workout History'),
        actions: [
          IconButton(
            icon: Icon(
              _sortDescending ? Icons.arrow_downward : Icons.arrow_upward,
            ),
            tooltip: _sortDescending ? 'Newest First' : 'Oldest First',
            onPressed: () {
              setState(() {
                _sortDescending = !_sortDescending;
              });
            },
          ),
          BlocBuilder<WorkoutBloc, WorkoutState>(
            builder: (context, state) {
              if (state is WorkoutsLoaded) {
                return IconButton(
                  icon: Icon(
                    _selectedPlanName != null
                        ? Icons.filter_list_alt
                        : Icons.filter_list,
                    color: _selectedPlanName != null ? AppColors.accent : null,
                  ),
                  tooltip: 'Filter by Plan',
                  onPressed: () => _showFilterDialog(state.workouts),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
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
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Error loading workouts',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.message,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _loadWorkouts,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state is WorkoutsLoaded) {
            // Apply filtering
            var workouts = List<WorkoutSession>.from(state.workouts);
            if (_selectedPlanName != null) {
              workouts = workouts
                  .where((w) => w.planName == _selectedPlanName)
                  .toList();
            }

            // Apply sorting
            workouts.sort((a, b) {
              if (_sortDescending) {
                return b.workoutDate.compareTo(a.workoutDate);
              } else {
                return a.workoutDate.compareTo(b.workoutDate);
              }
            });

            if (workouts.isEmpty) {
              // If filtering resulted in empty list, show message
              if (_selectedPlanName != null) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.filter_list_off,
                        size: 48,
                        color: AppColors.textSecondary.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No workouts found for plan',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '"$_selectedPlanName"',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.accent,
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _selectedPlanName = null;
                          });
                        },
                        child: const Text('Clear Filter'),
                      ),
                    ],
                  ),
                );
              }
              return _buildEmptyState(context);
            }

            // Group workouts by month
            final groupedWorkouts = <String, List<WorkoutSession>>{};
            for (final workout in workouts) {
              final monthYear = DateFormat(
                'MMMM yyyy',
              ).format(workout.workoutDate);
              if (!groupedWorkouts.containsKey(monthYear)) {
                groupedWorkouts[monthYear] = [];
              }
              groupedWorkouts[monthYear]!.add(workout);
            }

            return SafeArea(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                itemCount: groupedWorkouts.length,
                itemBuilder: (context, index) {
                  final monthYear = groupedWorkouts.keys.elementAt(index);
                  final monthWorkouts = groupedWorkouts[monthYear]!;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 4,
                        ),
                        child: Text(
                          monthYear,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.1,
                              ),
                        ),
                      ),
                      ...monthWorkouts.map((session) {
                        return _WorkoutHistoryCard(
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
                            ).then((_) {
                              _loadWorkouts();
                            });
                          },
                        );
                      }),
                    ],
                  );
                },
              ),
            );
          }

          return const Center(child: Text('Unknown state'));
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.accent.withValues(alpha: 0.1),
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.history_rounded,
                size: 48,
                color: AppColors.accent.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No workouts yet',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Start logging your workouts to build your history and track your progress.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
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
    final theme = Theme.of(context);
    final exercises = session.exercises.where((e) => !e.skipped).toList();
    int setCount = 0;
    double totalVolume = 0;

    for (final exercise in exercises) {
      setCount += exercise.sets.length;
      for (final set in exercise.sets) {
        for (final segment in set.segments) {
          totalVolume += segment.volume;
        }
      }
    }

    final planName = session.planName ?? '-';

    // Format volume (e.g., 1.2k kg)
    String formattedVolume = '${totalVolume.toInt()} kg';
    if (totalVolume >= 1000) {
      formattedVolume = '${(totalVolume / 1000).toStringAsFixed(1)}k kg';
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderLight, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              offset: const Offset(0, 2),
              blurRadius: 8,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              DateFormat(
                                'EEEE, dd MMMM yyyy',
                              ).format(session.workoutDate),
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.access_time_rounded,
                                  size: 12,
                                  color: AppColors.textSecondary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  session.formattedDuration,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (planName != '-') ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.accent.withValues(alpha: 0.2),
                            ),
                          ),
                          constraints: const BoxConstraints(maxWidth: 120),
                          child: Text(
                            planName,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: AppColors.accent,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: AppColors.textSecondary.withValues(alpha: 0.3),
                  size: 16,
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _StatBadge(
                  icon: Icons.list_alt_rounded,
                  label: '${exercises.length} Exercises',
                  color: AppColors.accent,
                ),
                _StatBadge(
                  icon: Icons.fitness_center_rounded,
                  label: '$setCount Sets',
                  color: AppColors.success,
                ),
                _StatBadge(
                  icon: Icons.bar_chart_rounded,
                  label: formattedVolume,
                  color: AppColors.warning,
                ),
              ],
            ),
          ],
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
