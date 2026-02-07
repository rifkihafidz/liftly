import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/colors.dart';
import '../../../core/models/workout_session.dart';
import '../../stats/bloc/stats_state.dart';

class SessionExerciseHistorySheet extends StatelessWidget {
  final String exerciseName;
  final SessionExercise? history;
  final PersonalRecord? pr;

  const SessionExerciseHistorySheet({
    super.key,
    required this.exerciseName,
    this.history,
    this.pr,
  });

  String _formatNumber(double value) {
    final formatter = NumberFormat(
      '#,###.##',
      'pt_BR',
    ); // USes . for thousand, , for decimal
    return formatter.format(value);
  }

  @override
  Widget build(BuildContext context) {
    final historyVolume =
        history?.sets.fold<double>(
          0.0,
          (sum, s) =>
              sum +
              s.segments.fold<double>(
                0.0,
                (sSum, seg) =>
                    sSum + (seg.weight * (seg.repsTo - seg.repsFrom + 1)),
              ),
        ) ??
        0.0;

    final showBestSessionSection =
        pr != null &&
        pr!.bestSessionSets != null &&
        pr!.bestSessionVolume > (historyVolume + 0.1);

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Last Session',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ..._renderSets(context, history!.sets),
              const SizedBox(height: 24),
            ],
            if (showBestSessionSection) ...[
              Text(
                'Best Session',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(height: 12),
              ..._renderSets(context, pr!.bestSessionSets!),
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
              Row(
                children: [
                  Expanded(
                    child: _buildPRCard(
                      context,
                      label: 'Best Heavy Set',
                      value: '${_formatNumber(pr!.maxWeight)} kg',
                      details: '${pr!.maxWeightReps} reps',
                      icon: Icons.fitness_center_rounded,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildPRCard(
                      context,
                      label: 'Best Volume Set',
                      value: '${_formatNumber(pr!.maxVolume)} kg',
                      details: pr!.maxVolumeBreakdown.isNotEmpty
                          ? pr!.maxVolumeBreakdown
                          : '${_formatNumber(pr!.maxVolumeWeight)} kg x ${pr!.maxVolumeReps}',
                      icon: Icons.auto_graph_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _renderSets(BuildContext context, List<ExerciseSet> sets) {
    return sets.expand<Widget>((s) {
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
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
    }).toList();
  }

  Widget _buildPRCard(
    BuildContext context, {
    required String label,
    required String value,
    required String details,
    required IconData icon,
    bool isFullWidth = false,
  }) {
    return Container(
      width: isFullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: isFullWidth
            ? CrossAxisAlignment.center
            : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: isFullWidth
                ? MainAxisAlignment.center
                : MainAxisAlignment.start,
            children: [
              Icon(icon, size: 14, color: AppColors.accent),
              const SizedBox(width: 6),
              if (isFullWidth)
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.accent,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                )
              else
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: AppColors.accent,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            details,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
