import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/colors.dart';
import '../../../shared/widgets/app_dialogs.dart';
import '../../../shared/widgets/shimmer_widgets.dart';
import '../../../core/models/workout_plan.dart';
import '../bloc/plan_bloc.dart';
import '../bloc/plan_event.dart';
import '../bloc/plan_state.dart';
import 'create_plan_page.dart';
import '../../../core/utils/page_transitions.dart';
import '../../../shared/widgets/animations/scale_button_wrapper.dart';
import '../../../shared/widgets/animations/fade_in_slide.dart';

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
                        centerTitle: false,
                        backgroundColor: AppColors.darkBg,
                        surfaceTintColor: AppColors.darkBg,
                        title: Text(
                          'Workout Plans',
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
                              });
                            },
                            itemBuilder: (context) =>
                                PlanSortOption.values.map((option) {
                                  return PopupMenuItem(
                                    value: option,
                                    child: Row(
                                      children: [
                                        if (_sortOption == option)
                                          Icon(
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
                                  style: Theme.of(context).textTheme.bodyMedium
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
                                  style: FilledButton.styleFrom(
                                    backgroundColor: AppColors.accent,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.all(16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
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
                                      child: _buildPlanCard(
                                        context,
                                        sortedPlans[index],
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
                                    child: _buildPlanCard(
                                      context,
                                      sortedPlans[index],
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

  Widget _buildPlanCard(BuildContext context, WorkoutPlan plan) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: ScaleButtonWrapper(
        child: Material(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                SmoothPageRoute(page: CreatePlanPage(plan: plan)),
              );
            },
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
                              plan.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            if (plan.description != null &&
                                plan.description!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  plan.description!,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: AppColors.textSecondary.withValues(
                                      alpha: 0.8,
                                    ),
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      PopupMenuButton(
                        icon: Icon(
                          Icons.more_vert_rounded,
                          color: AppColors.textSecondary,
                        ),
                        color: AppColors.darkBg,
                        surfaceTintColor: AppColors.darkBg,
                        position: PopupMenuPosition.under,
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            child: Row(
                              children: [
                                Icon(
                                  Icons.edit_rounded,
                                  size: 20,
                                  color: AppColors.textPrimary,
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Edit',
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            onTap: () {
                              Future.delayed(
                                const Duration(milliseconds: 100),
                                () {
                                  if (context.mounted) {
                                    Navigator.push(
                                      context,
                                      SmoothPageRoute(
                                        page: CreatePlanPage(plan: plan),
                                      ),
                                    );
                                  }
                                },
                              );
                            },
                          ),
                          PopupMenuItem(
                            child: Row(
                              children: [
                                Icon(
                                  Icons.delete_rounded,
                                  size: 20,
                                  color: AppColors.error,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Delete',
                                  style: TextStyle(color: AppColors.error),
                                ),
                              ],
                            ),
                            onTap: () {
                              Future.delayed(
                                const Duration(milliseconds: 0),
                                () {
                                  if (context.mounted) {
                                    _showDeleteConfirmDialog(context, plan);
                                  }
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.darkBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.list_alt_rounded,
                          size: 16,
                          color: AppColors.accent,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${plan.exercises.length} Exercises',
                          style: TextStyle(
                            color: AppColors.accent,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Column(
                    children: plan.exercises
                        .take(3)
                        .toList()
                        .asMap()
                        .entries
                        .map((entry) {
                          final index = entry.key;
                          final ex = entry.value;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                Text(
                                  '${index + 1}.',
                                  style: TextStyle(
                                    color: AppColors.textSecondary.withValues(
                                      alpha: 0.5,
                                    ),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    fontFeatures: const [
                                      FontFeature.tabularFigures(),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    ex.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        })
                        .toList(),
                  ),
                  if (plan.exercises.length > 3)
                    Padding(
                      padding: const EdgeInsets.only(top: 4, left: 24),
                      child: Text(
                        '+ ${plan.exercises.length - 3} more exercises',
                        style: TextStyle(
                          color: AppColors.textSecondary.withValues(alpha: 0.5),
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
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
