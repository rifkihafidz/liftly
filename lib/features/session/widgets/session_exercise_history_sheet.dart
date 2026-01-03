import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../core/models/workout_session.dart';

class SessionExerciseHistorySheet extends StatelessWidget {
  final String exerciseName;
  final SessionExercise? history;
  final SetSegment? pr;

  const SessionExerciseHistorySheet({
    super.key,
    required this.exerciseName,
    this.history,
    this.pr,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            exerciseName,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          if (history != null) ...[
            Text(
              'Last Session',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            ...history!.sets.expand((s) {
              if (s.segments.isEmpty) return [const SizedBox.shrink()];

              return s.segments.map((seg) {
                final weight = seg.weight == seg.weight.toInt()
                    ? seg.weight.toInt()
                    : seg.weight;

                String reps;
                if (seg.repsFrom != seg.repsTo && seg.repsTo > 0) {
                  reps = '${seg.repsFrom}-${seg.repsTo}';
                } else if (seg.repsFrom <= 1 && seg.repsTo > 1) {
                  reps = '${seg.repsTo}';
                } else {
                  reps = '${seg.repsFrom}';
                }

                String notesStr = '';
                if (seg.notes.isNotEmpty) {
                  notesStr = ' (${seg.notes})';
                }

                final isDropSet = seg.segmentOrder > 0;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      if (isDropSet) ...[
                        const SizedBox(width: 6),
                        Icon(
                          Icons.subdirectory_arrow_right_rounded,
                          size: 18,
                          color: AppColors.textSecondary.withValues(alpha: 0.5),
                        ),
                        const SizedBox(width: 8),
                      ] else ...[
                        SizedBox(
                          width: 20,
                          child: Text(
                            '${s.setNumber}',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.bold,
                                ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Flexible(
                        child: Text(
                          '$weight kg × $reps$notesStr',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      if (isDropSet) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'DROP',
                            style: TextStyle(
                              color: AppColors.accent,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              });
            }),
            const SizedBox(height: 24),
          ],
          if (pr != null) ...[
            Text(
              'Personal Record (PR)',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.accent,
              ),
            ),
            const SizedBox(height: 12),
            Builder(
              builder: (context) {
                final weight = pr!.weight == pr!.weight.toInt()
                    ? pr!.weight.toInt()
                    : pr!.weight;

                final repsCount = (pr!.repsTo > pr!.repsFrom)
                    ? pr!.repsTo
                    : pr!.repsFrom;
                final reps = '$repsCount';

                String notesStr = '';
                if (pr!.notes.isNotEmpty) {
                  notesStr = ' (${pr!.notes})';
                }

                return Row(
                  children: [
                    const Icon(
                      Icons.emoji_events_outlined,
                      size: 20,
                      color: AppColors.accent,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$weight kg - $reps reps$notesStr',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }
}
