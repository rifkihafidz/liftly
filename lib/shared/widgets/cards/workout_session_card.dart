import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/colors.dart';
import '../../../core/models/workout_session.dart';
import '../animations/scale_button_wrapper.dart';
import '../chips/stat_badge.dart';

class WorkoutSessionCard extends StatelessWidget {
  final WorkoutSession session;
  final VoidCallback onTap;

  const WorkoutSessionCard({
    super.key,
    required this.session,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final exercises = session.exercises.where((e) => !e.skipped).toList();
    final totalSets = exercises.fold(0, (sum, e) => sum + e.sets.length);
    final volume = session.totalVolume;
    final planName = session.planName ?? '-';

    final volumeFormatter = NumberFormat('#,##0.##', 'pt_BR');
    String formattedVolume = volumeFormatter.format(volume);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ScaleButtonWrapper(
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
                                'EEEE, dd MMMM yyyy',
                              ).format(session.effectiveDate),
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
                            if (session.startedAt != null &&
                                session.endedAt != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                '${DateFormat('HH:mm').format(session.startedAt!)} - ${DateFormat('HH:mm').format(session.endedAt!)}',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
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
                      StatBadge(
                        icon: Icons.fitness_center_rounded,
                        label: '${exercises.length} Exercises',
                        color: const Color(0xFF6366F1), // Indigo
                      ),
                      const SizedBox(width: 8),
                      StatBadge(
                        icon: Icons.repeat_rounded,
                        label: '$totalSets Sets',
                        color: const Color(0xFF10B981), // Emerald
                      ),
                      const SizedBox(width: 8),
                      StatBadge(
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
      ),
    );
  }
}
