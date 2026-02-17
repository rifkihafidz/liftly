import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/colors.dart';
import '../../../core/models/workout_session.dart';
import '../../../core/models/personal_record.dart';

/// Lightweight header for view mode - only shows exercise info, no editing
class ExerciseViewHeader extends StatelessWidget {
  final SessionExercise exercise;
  final WorkoutSession? history;
  final PersonalRecord? pr;
  final VoidCallback? onHistoryTap;

  const ExerciseViewHeader({
    super.key,
    required this.exercise,
    this.history,
    this.pr,
    this.onHistoryTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  exercise.name,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: exercise.skipped
                            ? AppColors.textSecondary
                            : AppColors.textPrimary,
                        decoration: exercise.skipped
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                ),
              ),
              if (history != null || pr != null)
                IconButton(
                  icon: const Icon(Icons.history, size: 20),
                  color: AppColors.textSecondary,
                  tooltip: 'View History',
                  onPressed: onHistoryTap,
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(8),
                ),
            ],
          ),
          if (exercise.skipped)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'SKIPPED',
                style: TextStyle(
                  color: AppColors.error,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          if (!exercise.skipped) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.layers_outlined,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  '${exercise.sets.length} Sets',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 16),
                const Icon(
                  Icons.fitness_center_outlined,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  '${exercise.totalVolume > 0 ? NumberFormat('#,##0.##', 'pt_BR').format(exercise.totalVolume) : "-"} kg',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
          if (pr != null) ...[
            const SizedBox(height: 12),
            const Divider(height: 1, color: AppColors.borderLight),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Best Heavy',
                        style: TextStyle(
                          color: AppColors.accent,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${pr!.maxWeight == pr!.maxWeight.toInt() ? pr!.maxWeight.toInt() : pr!.maxWeight} kg',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${pr!.maxWeightReps} reps',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Best Volume',
                        style: TextStyle(
                          color: AppColors.accent,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${pr!.maxVolume == pr!.maxVolume.toInt() ? pr!.maxVolume.toInt() : pr!.maxVolume} kg',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        pr!.maxVolumeBreakdown.isNotEmpty
                            ? pr!.maxVolumeBreakdown
                            : '${pr!.maxVolumeWeight == pr!.maxVolumeWeight.toInt() ? pr!.maxVolumeWeight.toInt() : pr!.maxVolumeWeight} kg x ${pr!.maxVolumeReps}',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Lightweight set row for view mode - shows data as Text, no TextFields
class ViewSetRow extends StatelessWidget {
  final ExerciseSet set;

  const ViewSetRow({super.key, required this.set});

  @override
  Widget build(BuildContext context) {
    final segments = set.segments;
    final isDropSet = segments.length > 1;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Set header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.accent),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Set ${set.setNumber}',
                  style: TextStyle(
                    color: AppColors.accent,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
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
                    color: AppColors.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'DROP SET',
                    style: TextStyle(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w900,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),

          // Segment data rows (read-only)
          for (int i = 0; i < segments.length; i++)
            Padding(
              padding: EdgeInsets.only(bottom: i < segments.length - 1 ? 8 : 0),
              child: _buildSegmentRow(context, segments[i], i > 0),
            ),

          // Notes
          if (segments.isNotEmpty && segments[0].notes.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.notes,
                  size: 14,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    segments[0].notes,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSegmentRow(
    BuildContext context,
    SetSegment segment,
    bool isDropSegment,
  ) {
    return Row(
      children: [
        if (isDropSegment)
          const Padding(
            padding: EdgeInsets.only(right: 8),
            child: Icon(
              Icons.subdirectory_arrow_right,
              size: 16,
              color: AppColors.textSecondary,
            ),
          ),
        // Weight
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.inputBg,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${segment.weight}',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(width: 4),
              const Text(
                'kg',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        // Reps
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.inputBg,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                segment.repsFrom == segment.repsTo
                    ? '${segment.repsFrom}'
                    : '${segment.repsFrom}-${segment.repsTo}',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(width: 4),
              const Text(
                'reps',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Header for edit mode - simplified with skip and action buttons
class EditModeHeader extends StatelessWidget {
  final SessionExercise exercise;
  final VoidCallback? onSkipToggle;
  final VoidCallback? onEditName;
  final VoidCallback? onDelete;

  const EditModeHeader({
    super.key,
    required this.exercise,
    this.onSkipToggle,
    this.onEditName,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              exercise.name,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: exercise.skipped
                        ? AppColors.textSecondary
                        : AppColors.textPrimary,
                    decoration:
                        exercise.skipped ? TextDecoration.lineThrough : null,
                  ),
            ),
          ),
          TextButton(
            onPressed: onSkipToggle,
            child: Text(
              exercise.skipped ? 'Unskip' : 'Skip',
              style: TextStyle(
                color: exercise.skipped
                    ? AppColors.accent
                    : AppColors.textSecondary,
              ),
            ),
          ),
          if (onEditName != null || onDelete != null)
            PopupMenuButton<String>(
              icon: const Icon(
                Icons.more_vert,
                size: 20,
                color: AppColors.textSecondary,
              ),
              onSelected: (value) {
                if (value == 'edit') onEditName?.call();
                if (value == 'delete') onDelete?.call();
              },
              itemBuilder: (context) => [
                if (onEditName != null)
                  const PopupMenuItem(value: 'edit', child: Text('Rename')),
                if (onDelete != null)
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text(
                      'Remove',
                      style: TextStyle(color: AppColors.error),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
