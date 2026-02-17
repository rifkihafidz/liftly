import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/colors.dart';
import '../../../shared/widgets/app_dialogs.dart';
import '../../../shared/widgets/shimmer_widgets.dart';
import '../../../core/models/workout_plan.dart';
import '../../plans/bloc/plan_bloc.dart';
import '../../plans/bloc/plan_event.dart';
import '../../plans/bloc/plan_state.dart';
import 'create_plan_page.dart';
import '../../../core/utils/page_transitions.dart';
import '../../../shared/widgets/animations/fade_in_slide.dart';
import '../../../shared/widgets/cards/plan_card.dart';

enum PlanSortOption { newest, oldest, nameAZ, nameZA }

class PlansPage extends StatefulWidget {
  const PlansPage({super.key});

  @override
  State<PlansPage> createState() => _PlansPageState();
}

class _PlansPageState extends State<PlansPage> {
  PlanSortOption _sortOption = PlanSortOption.newest;

  @override
  void initState() {
    super.initState();
    context.read<PlanBloc>().add(const PlansFetchRequested(userId: '1'));
  }

  String _getSortLabel(PlanSortOption option) {
    switch (option) {
      case PlanSortOption.newest:
        return 'Newest First';
      case PlanSortOption.oldest:
        return 'Oldest First';
      case PlanSortOption.nameAZ:
        return 'Name (A-Z)';
      case PlanSortOption.nameZA:
        return 'Name (Z-A)';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: BlocListener<PlanBloc, PlanState>(
        listener: (context, state) {
          if (state is PlanError) {
            AppDialogs.showErrorDialog(
              context: context,
              title: 'Error Occurred',
              message: state.message,
            );
          }
          if (state is PlanSuccess) {
            AppDialogs.showSuccessDialog(
              context: context,
              title: 'Success',
              message: state.message,
            );
          }
        },
        child: BlocBuilder<PlanBloc, PlanState>(
          builder: (context, state) {
            if (state is PlanLoading) {
              return const PlanListShimmer();
            }

            if (state is PlansLoaded) {
              final sortedPlans = List<WorkoutPlan>.from(state.plans);
              switch (_sortOption) {
                case PlanSortOption.newest:
                  sortedPlans.sort(
                    (a, b) => b.createdAt.compareTo(a.createdAt),
                  );
                  break;
                case PlanSortOption.oldest:
                  sortedPlans.sort(
                    (a, b) => a.createdAt.compareTo(b.createdAt),
                  );
                  break;
                case PlanSortOption.nameAZ:
                  sortedPlans.sort(
                    (a, b) =>
                        a.name.toLowerCase().compareTo(b.name.toLowerCase()),
                  );
                  break;
                case PlanSortOption.nameZA:
                  sortedPlans.sort(
                    (a, b) =>
                        b.name.toLowerCase().compareTo(a.name.toLowerCase()),
                  );
                  break;
              }

              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  child: CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      SliverAppBar(
                        pinned: true,
                        automaticallyImplyLeading: false,
                        leadingWidth: 56,
                        leading: const SizedBox.shrink(),
                        title: const Text('Workout Plans'),
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
                          IconButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                SmoothPageRoute(page: const CreatePlanPage()),
                              );
                            },
                            icon: const Icon(
                              Icons.add_circle_outline_rounded,
                              color: AppColors.accent,
                            ),
                            tooltip: 'Create New Plan',
                          ),
                          const SizedBox(width: 8),
                        ],
                      ),
                      if (sortedPlans.isEmpty)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(
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
                                    Icons.fitness_center_rounded,
                                    size: 48,
                                    color: AppColors.accent.withValues(
                                      alpha: 0.5,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  'No plans yet',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                      ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Create your first workout plan to get started.',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                ),
                                const SizedBox(height: 32),
                                FilledButton.icon(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      SmoothPageRoute(
                                        page: const CreatePlanPage(),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.add),
                                  label: const Text(
                                    'Create Plan',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                          sliver: SliverLayoutBuilder(
                            builder: (context, constraints) {
                              if (constraints.crossAxisExtent > 600) {
                                return SliverGrid(
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    mainAxisSpacing: 16,
                                    crossAxisSpacing: 16,
                                    mainAxisExtent: 260,
                                  ),
                                  delegate: SliverChildBuilderDelegate(
                                    (context, index) => FadeInSlide(
                                      index: index,
                                      child: PlanCard(
                                        plan: sortedPlans[index],
                                        onTap: () => _navigateToCreatePlan(
                                          context,
                                          sortedPlans[index],
                                        ),
                                        onEdit: () => _navigateToCreatePlan(
                                          context,
                                          sortedPlans[index],
                                        ),
                                        onDelete: () =>
                                            _showDeleteConfirmDialog(
                                          context,
                                          sortedPlans[index],
                                        ),
                                      ),
                                    ),
                                    childCount: sortedPlans.length,
                                  ),
                                );
                              }
                              return SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) => FadeInSlide(
                                    index: index,
                                    child: Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 16,
                                      ),
                                      child: PlanCard(
                                        plan: sortedPlans[index],
                                        onTap: () => _navigateToCreatePlan(
                                          context,
                                          sortedPlans[index],
                                        ),
                                        onEdit: () => _navigateToCreatePlan(
                                          context,
                                          sortedPlans[index],
                                        ),
                                        onDelete: () =>
                                            _showDeleteConfirmDialog(
                                          context,
                                          sortedPlans[index],
                                        ),
                                      ),
                                    ),
                                  ),
                                  childCount: sortedPlans.length,
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }

            return const Center(child: CircularProgressIndicator());
          },
        ),
      ),
    );
  }

  void _navigateToCreatePlan(BuildContext context, WorkoutPlan plan) {
    Navigator.push(context, SmoothPageRoute(page: CreatePlanPage(plan: plan)));
  }

  void _showDeleteConfirmDialog(BuildContext context, WorkoutPlan plan) {
    AppDialogs.showConfirmationDialog(
      context: context,
      title: 'Delete Plan',
      message:
          'Are you sure you want to delete "${plan.name}"? This action cannot be undone.',
      confirmText: 'Delete',
      isDangerous: true,
    ).then((confirm) {
      if (confirm == true && context.mounted) {
        context.read<PlanBloc>().add(PlanDeleted(userId: '1', planId: plan.id));
      }
    });
  }
}
