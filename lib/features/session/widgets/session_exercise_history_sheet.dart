import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/colors.dart';
import '../../../core/models/workout_session.dart';
import '../../../core/models/personal_record.dart';

class SessionExerciseHistorySheet extends StatelessWidget {
  final String exerciseName;
  final WorkoutSession? history;
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

  String _formatDate(DateTime date) {
    return DateFormat('d MMM yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    // Find the specific exercise in the history session
    final historyExercise = history?.exercises
        .where((e) => e.name.toLowerCase() == exerciseName.toLowerCase())
        .firstOrNull;

    final showHistory = history != null && historyExercise != null;

    final showBestSessionSection = pr != null &&
        pr!.bestSessionSets != null &&
        (pr!.bestSessionVolume > 0 || pr!.bestSessionReps > 0);

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
            if (showHistory) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Last Session (${_formatDate(history!.workoutDate)})',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                  ),
                  Text(
                    'Total Volume: ${_formatNumber(historyExercise.totalVolume)} kg',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ..._renderSets(context, historyExercise.sets),
              const SizedBox(height: 24),
            ],
            if (showBestSessionSection) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Best Session${pr!.bestSessionDate != null ? " (${_formatDate(DateTime.parse(pr!.bestSessionDate!))})" : ""}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.accent,
                        ),
                  ),
                  Text(
                    'Total Volume: ${_formatNumber(pr!.bestSessionVolume)} kg',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.accent,
                        ),
                  ),
                ],
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
    return sets.asMap().entries.expand<Widget>((entry) {
      final index = entry.key;
      final s = entry.value;

      if (s.segments.isEmpty) return [const SizedBox.shrink()];

      return s.segments.map((seg) {
        final weight =
            seg.weight == seg.weight.toInt() ? seg.weight.toInt() : seg.weight;

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
        final displaySetNumber = s.setNumber > 0 ? s.setNumber : index + 1;

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
                    '$displaySetNumber',
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
        crossAxisAlignment:
            isFullWidth ? CrossAxisAlignment.center : CrossAxisAlignment.start,
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
