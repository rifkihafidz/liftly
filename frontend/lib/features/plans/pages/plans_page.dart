import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/colors.dart';
import '../bloc/plan_bloc.dart';
import '../bloc/plan_event.dart';
import '../bloc/plan_state.dart';
import 'create_plan_page.dart';

class PlansPage extends StatefulWidget {
  const PlansPage({super.key});

  @override
  State<PlansPage> createState() => _PlansPageState();
}

class _PlansPageState extends State<PlansPage> {
  @override
  void initState() {
    super.initState();
    context.read<PlanBloc>().add(const PlansFetchRequested());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Workout Plans'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreatePlanPage(),
                ),
              );
            },
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: BlocListener<PlanBloc, PlanState>(
        listener: (context, state) {
          if (state is PlanError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
          if (state is PlanSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        child: BlocBuilder<PlanBloc, PlanState>(
          builder: (context, state) {
            if (state is PlanLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is PlansLoaded) {
              if (state.plans.isEmpty) {
                return SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.fitness_center,
                          size: 64,
                          color: AppColors.accent.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'No plans yet',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Create your first workout plan',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const CreatePlanPage(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.add),
                            label: const Text('Create Plan'),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return SafeArea(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: state.plans.length,
                  itemBuilder: (context, index) {
                    final plan = state.plans[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CreatePlanPage(plan: plan),
                          ),
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.cardBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.borderLight,
                            width: 1,
                          ),
                        ),
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
                                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      if (plan.description != null) ...[  
                                        const SizedBox(height: 4),
                                        Text(
                                          plan.description!,
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                      const SizedBox(height: 8),
                                      Text(
                                        '${plan.exercises.length} exercises',
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: AppColors.accent,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                PopupMenuButton(
                                  itemBuilder: (context) => [
                                    PopupMenuItem(
                                      child: const Text('Delete'),
                                      onTap: () {
                                        showDialog(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: const Text('Delete Plan'),
                                            content: Text(
                                              'Are you sure you want to delete "${plan.name}"? This action cannot be undone.',
                                            ),
                                            backgroundColor: AppColors.cardBg,
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(context),
                                                child: const Text('Cancel'),
                                              ),
                                              TextButton(
                                                onPressed: () {
                                                  Navigator.pop(context);
                                                  context.read<PlanBloc>().add(
                                                    PlanDeleted(planId: plan.id),
                                                  );
                                                },
                                                child: const Text(
                                                  'Delete',
                                                  style: TextStyle(color: Colors.red),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: plan.exercises.take(4).map((ex) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.inputBg,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    ex.name,
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                            if (plan.exercises.length > 4) ...[  
                              const SizedBox(height: 8),
                              Text(
                                '+${plan.exercises.length - 4} more',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.textSecondary,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            }

            return const Center(child: Text('No plans'));
          },
        ),
      ),
    );
  }
}
