import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:liftly/core/constants/app_constants.dart';
import '../../../core/constants/colors.dart';
import '../../session/bloc/session_bloc.dart';
import '../../session/bloc/session_event.dart';
import '../../session/bloc/session_state.dart';
import '../../session/pages/start_workout_page.dart';
import '../../session/pages/workout_history_page.dart';
import '../../plans/pages/plans_page.dart';
import '../../stats/pages/stats_page.dart';
import '../../session/pages/session_page.dart';
import '../../../shared/widgets/app_dialogs.dart';
import '../../settings/pages/settings_page.dart';
import '../../../core/utils/page_transitions.dart';
import '../../../shared/widgets/animations/scale_button_wrapper.dart';
import '../../../shared/widgets/animations/fade_in_slide.dart';

import '../../../shared/widgets/cards/menu_grid_item.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _quote = '';

  @override
  void initState() {
    super.initState();
    _quote = _getRandomQuote();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  String _getRandomQuote() {
    final quotes = [
      'Ready to crush your goals today?',
      'Consistent action creates consistent results.',
      'The only bad workout is the one that didn\'t happen.',
      'Your body can stand almost anything. It\'s your mind that you have to convince.',
      'Fitness is not about being better than someone else. It\'s about being better than you were yesterday.',
      'Discipline is doing what needs to be done, even if you don\'t want to do it.',
      'Success starts with self-discipline.',
      'Don\'t stop when you\'re tired. Stop when you\'re done.',
      'Motivation is what gets you started. Habit is what keeps you going.',
      'Invest in yourself. It pays the best interest.',
    ];
    return (quotes..shuffle()).first;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: BlocListener<SessionBloc, SessionState>(
        listener: (context, state) async {
          if (state is SessionDraftCheckSuccess) {
            final draft = state.draft;
            if (draft != null) {
              final confirm = await AppDialogs.showConfirmationDialog(
                context: context,
                title: 'Resume Draft?',
                message:
                    'You have an unfinished workout from ${DateFormat('EEEE, dd MMMM yyyy').format(draft.createdAt)}. Do you want to resume it?',
                confirmText: 'Resume',
                cancelText: 'New Workout',
              );

              if (!context.mounted) return;

              if (confirm == true) {
                // Resume Draft
                Navigator.push(
                  context,
                  SmoothPageRoute(page: SessionPage(draftSession: draft)),
                );
              } else {
                // Start New Workout
                Navigator.push(
                  context,
                  SmoothPageRoute(page: const StartWorkoutPage()),
                );
              }
            } else {
              // No Draft
              Navigator.push(
                context,
                SmoothPageRoute(page: const StartWorkoutPage()),
              );
            }
          } else if (state is SessionError) {
            AppDialogs.showErrorDialog(
              context: context,
              title: "Error",
              message: state.message,
            );
          }
        },
        child: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FadeInSlide(
                        index: 0,
                        child: Text(
                          DateFormat(
                            'EEEE, dd MMMM yyyy',
                          ).format(DateTime.now()).toUpperCase(),
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: AppColors.accent,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.5,
                                  ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      FadeInSlide(
                        index: 1,
                        child: Text(
                          _getGreeting(),
                          style: Theme.of(context)
                              .textTheme
                              .displaySmall
                              ?.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w800,
                                height: 1.1,
                                fontSize: 32,
                              ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      FadeInSlide(
                        index: 2,
                        child: Text(
                          _quote,
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: AppColors.textSecondary,
                                    fontSize: 16,
                                  ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Hero Section - Start Workout
                      FadeInSlide(
                        index: 3,
                        child: _HeroCard(
                          title: 'Start Workout',
                          subtitle: 'Log a new session manually',
                          icon: Icons.add_rounded,
                          onTap: () {
                            context.read<SessionBloc>().add(
                                  const SessionCheckDraftRequested(userId: '1'),
                                );
                          },
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: SliverLayoutBuilder(
                  builder: (context, constraints) {
                    final crossAxisCount =
                        constraints.crossAxisExtent > 600 ? 3 : 2;
                    return SliverGrid(
                      delegate: SliverChildListDelegate([
                        FadeInSlide(
                          index: 4,
                          child: MenuGridItem(
                            title: 'History',
                            subtitle: 'Past sessions',
                            icon: Icons.history_rounded,
                            color: const Color(0xFF6366F1), // Indigo
                            onTap: () => Navigator.push(
                              context,
                              SmoothPageRoute(page: const WorkoutHistoryPage()),
                            ),
                          ),
                        ),
                        FadeInSlide(
                          index: 5,
                          child: MenuGridItem(
                            title: 'Statistics',
                            subtitle: 'Your progress',
                            icon: Icons.bar_chart_rounded,
                            color: const Color(0xFF10B981), // Emerald
                            onTap: () => Navigator.push(
                              context,
                              SmoothPageRoute(page: const StatsPage()),
                            ),
                          ),
                        ),
                        FadeInSlide(
                          index: 6,
                          child: MenuGridItem(
                            title: 'Plans',
                            subtitle: 'Routines',
                            icon: Icons.bookmarks_rounded,
                            color: const Color(0xFFF59E0B), // Amber
                            onTap: () => Navigator.push(
                              context,
                              SmoothPageRoute(page: const PlansPage()),
                            ),
                          ),
                        ),
                        FadeInSlide(
                          index: 7,
                          child: MenuGridItem(
                            title: 'Settings',
                            subtitle: 'Preferences',
                            icon: Icons.settings_rounded,
                            color: const Color(0xFF64748B), // Slate
                            onTap: () => Navigator.push(
                              context,
                              SmoothPageRoute(page: const SettingsPage()),
                            ),
                          ),
                        ),
                      ]),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 1.1,
                      ),
                    );
                  },
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: Text(
                      AppConstants.appVersion,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary.withValues(
                              alpha: 0.5,
                            ),
                            fontSize: 12,
                            letterSpacing: 1.0,
                          ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _HeroCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ScaleButtonWrapper(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.accent,
                  AppColors.accent.withValues(alpha: 0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accent.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'NEW SESSION',
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                    fontSize: 10,
                                  ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        title,
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 22,
                                ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: AppColors.accent, size: 28),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
