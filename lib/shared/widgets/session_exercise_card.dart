import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/models/workout_session.dart';
import 'workout_form_widgets.dart';

class SessionExerciseCard extends StatelessWidget {
  final Map<String, dynamic> exercise;
  final int exerciseIndex;
  final SessionExercise? history;
  final SetSegment? pr;
  final VoidCallback onSkipToggle;
  final VoidCallback onHistoryTap;
  final VoidCallback onAddSet;
  final Function(int setIndex) onRemoveSet;
  final Function(int setIndex) onAddDropSet;
  final Function(int setIndex, int segmentIndex) onRemoveDropSet;
  final Function(int setIndex, int segmentIndex, String field, dynamic value)
  onUpdateSegment;

  const SessionExerciseCard({
    super.key,
    required this.exercise,
    required this.exerciseIndex,
    this.history,
    this.pr,
    required this.onSkipToggle,
    required this.onHistoryTap,
    required this.onAddSet,
    required this.onRemoveSet,
    required this.onAddDropSet,
    required this.onRemoveDropSet,
    required this.onUpdateSegment,
  });

  @override
  Widget build(BuildContext context) {
    final sets = (exercise['sets'] as List<dynamic>?) ?? [];
    final isSkipped = exercise['skipped'] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight, width: 1),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, isSkipped),
          if (!isSkipped) ...[
            const SizedBox(height: 16),
            ...List.generate(sets.length, (setIndex) {
              final set = (sets[setIndex] as Map<dynamic, dynamic>)
                  .cast<String, dynamic>();
              final segments = (set['segments'] as List<dynamic>?) ?? [];

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (setIndex > 0)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Divider(height: 1),
                    ),
                  _buildSetHeader(context, set, segments.length > 1, setIndex),
                  const SizedBox(height: 12),
                  ...List.generate(segments.length, (segIndex) {
                    final segment =
                        (segments[segIndex] as Map<dynamic, dynamic>)
                            .cast<String, dynamic>();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: WeightField(
                              initialValue: segment['weight'].toString(),
                              onChanged: (v) => onUpdateSegment(
                                setIndex,
                                segIndex,
                                'weight',
                                double.tryParse(v) ?? 0,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: NumberField(
                              label: 'From',
                              initialValue: segment['repsFrom'].toString(),
                              onChanged: (v) => onUpdateSegment(
                                setIndex,
                                segIndex,
                                'repsFrom',
                                int.tryParse(v) ?? 0,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ToField(
                              initialValue: segment['repsTo'].toString(),
                              onChanged: (v) => onUpdateSegment(
                                setIndex,
                                segIndex,
                                'repsTo',
                                int.tryParse(v) ?? 0,
                              ),
                              onDeleteTap: (segments.length > 1 && segIndex > 0)
                                  ? () => onRemoveDropSet(setIndex, segIndex)
                                  : null,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 12),
                  if (segments.isNotEmpty)
                    NotesField(
                      initialValue: segments[0]['notes']?.toString() ?? '',
                      onChanged: (v) =>
                          onUpdateSegment(setIndex, 0, 'notes', v),
                    ),
                  const SizedBox(height: 12),
                  _buildActionButtons(context, setIndex, sets.length),
                ],
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isSkipped) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                exercise['name'],
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        if (history != null || pr != null)
          IconButton(
            icon: const Icon(
              Icons.history,
              size: 20,
              color: AppColors.textSecondary,
            ),
            tooltip: 'View History & PR',
            constraints: const BoxConstraints.tightFor(width: 32, height: 32),
            padding: EdgeInsets.zero,
            onPressed: onHistoryTap,
          ),
        const SizedBox(width: 4),
        GestureDetector(
          onTap: onSkipToggle,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isSkipped
                  ? AppColors.accent.withValues(alpha: 0.2)
                  : AppColors.inputBg,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: isSkipped ? AppColors.accent : AppColors.borderLight,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isSkipped ? Icons.check_box : Icons.check_box_outline_blank,
                  size: 14,
                  color: isSkipped ? AppColors.accent : AppColors.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  isSkipped ? 'Skipped' : 'Skip',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: isSkipped
                        ? AppColors.accent
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSetHeader(
    BuildContext context,
    Map<String, dynamic> set,
    bool isDropSet,
    int setIndex,
  ) {
    return Row(
      children: [
        Text(
          'Set ${set['setNumber']}',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.accent,
          ),
        ),
        const SizedBox(width: 8),
        if (isDropSet)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'Drop Set',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.accent,
                fontWeight: FontWeight.w600,
                fontSize: 10,
              ),
            ),
          ),
        const Spacer(),
        if (setIndex > 0)
          IconButton(
            onPressed: () => onRemoveSet(setIndex),
            icon: const Icon(Icons.delete_outline, size: 20),
            color: AppColors.error,
            tooltip: 'Remove Set',
            constraints: const BoxConstraints.tightFor(width: 32, height: 32),
            padding: EdgeInsets.zero,
          ),
      ],
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    int setIndex,
    int totalSets,
  ) {
    final bool isLastSet = setIndex == totalSets - 1;

    if (isLastSet) {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: onAddSet,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add Set', style: TextStyle(fontSize: 12)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => onAddDropSet(setIndex),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add Drop Set', style: TextStyle(fontSize: 12)),
            ),
          ),
        ],
      );
    } else {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => onAddDropSet(setIndex),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add Drop Set', style: TextStyle(fontSize: 12)),
            ),
          ),
        ],
      );
    }
  }
}
