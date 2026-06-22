import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/colors.dart';
import '../../../core/models/workout_session.dart';
import '../../../core/models/personal_record.dart';

class SessionExerciseHistorySheet extends StatelessWidget {
  final String exerciseName;
  final String exerciseVariation;
  final List<WorkoutSession>? histories;
  final PersonalRecord? pr;

  const SessionExerciseHistorySheet({
    super.key,
    required this.exerciseName,
    this.exerciseVariation = '',
    this.histories,
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
    return DateFormat('dd MMM yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final validHistories = <(WorkoutSession, SessionExercise, int, int)>[];

    if (histories != null) {
      for (final h in histories!) {
        // Collect ALL matching exercises in this session (can be >1 after rename/merge)
        final allExercises = h.exercises;
        final totalExercises = allExercises.length;
        final matchingIndices = allExercises
            .asMap()
            .entries
            .where((e) =>
                e.value.name.toLowerCase() == exerciseName.toLowerCase() &&
                e.value.variation.toLowerCase() ==
                    exerciseVariation.toLowerCase())
            .toList();

        if (matchingIndices.isEmpty) continue;

        // Merge sets if there are multiple entries with the same name in one session
        final firstIndex = matchingIndices.first.key;
        final merged = matchingIndices.map((e) => e.value).reduce((a, b) {
          final mergedSets = <ExerciseSet>[...a.sets, ...b.sets]
              .asMap()
              .entries
              .map((e) => e.value.copyWith(setNumber: e.key + 1))
              .toList();
          return a.copyWith(sets: mergedSets);
        });
        validHistories.add((h, merged, firstIndex + 1, totalExercises));
      }
    }

    final showHistory = validHistories.isNotEmpty;

    // Resolve Best Session sets for the active variation
    List<ExerciseSet>? bestSets;
    String? bestSessionDate;
    double bestSessionVol = 0;

    if (pr?.bestSessionSets != null) {
      bestSets = pr!.bestSessionSets;
      bestSessionDate = pr!.bestSessionDate;
      bestSessionVol = pr!.bestSessionVolume;
    } else if (showHistory) {
      final firstHistory = validHistories.first;
      bestSets = firstHistory.$2.sets;
      bestSessionDate = firstHistory.$1.workoutDate.toIso8601String();
      bestSessionVol = firstHistory.$2.totalVolume;
    }

    final showBestSessionSection =
        bestSets != null && bestSets.isNotEmpty && bestSessionVol > 0;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.textSecondary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exerciseName,
                        style: Theme.of(
                          context,
                        )
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      if (exerciseVariation.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            exerciseVariation,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: AppColors.accent,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: AppColors.textSecondary),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (showHistory) ...[
              for (final entry in validHistories) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Session on ${_formatDate(entry.$1.workoutDate)}',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textSecondary,
                                    ),
                              ),
                              const SizedBox(width: 8),
                              _buildExerciseOrderBadge(entry.$3, entry.$4),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${_formatNumber(entry.$2.totalVolume)} kg',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildNoteRow(context, 'Session Note', entry.$1.notes),
                _buildNoteRow(context, 'Exercise Note', entry.$2.notes),
                ..._renderSets(context, entry.$2.sets),
                const SizedBox(height: 24),
              ],
            ] else
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'No previous sessions yet',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ),
              ),
            if (showBestSessionSection) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            'Best Session${bestSessionDate != null ? " (${_formatDate(DateTime.parse(bestSessionDate))})" : ""}',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.accent,
                                ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (bestSessionDate != null &&
                            ((pr?.bestSessionOrder != null &&
                                    pr?.bestSessionTotalEx != null) ||
                                _getExerciseOrder(
                                        validHistories, bestSessionDate) !=
                                    null)) ...[
                          const SizedBox(width: 8),
                          _buildExerciseOrderBadge(
                            pr?.bestSessionOrder ??
                                _getExerciseOrder(
                                        validHistories, bestSessionDate)!
                                    .$1,
                            pr?.bestSessionTotalEx ??
                                _getExerciseOrder(
                                        validHistories, bestSessionDate)!
                                    .$2,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Total: ${_formatNumber(bestSessionVol)} kg',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.accent,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ..._renderSets(context, bestSets),
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
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _buildPRCard(
                        context,
                        label: 'Best Heavy Set',
                        value: '${_formatNumber(pr!.maxWeight)} kg',
                        details: '${pr!.maxWeightReps} reps',
                        icon: Icons.fitness_center_rounded,
                        date: pr!.maxWeightDate,
                        variation: exerciseVariation,
                        exerciseOrder: (pr!.maxWeightOrder != null &&
                                pr!.maxWeightTotalEx != null)
                            ? (pr!.maxWeightOrder!, pr!.maxWeightTotalEx!)
                            : _getExerciseOrder(
                                validHistories, pr!.maxWeightDate),
                        sessionNotes:
                            _getSessionNotes(validHistories, pr!.maxWeightDate),
                        exerciseNotes: _getExerciseNotes(
                            validHistories, pr!.maxWeightDate),
                        setNotes: pr!.maxWeightNotes,
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
                        date: pr!.maxVolumeDate,
                        variation: exerciseVariation,
                        exerciseOrder: (pr!.maxVolumeOrder != null &&
                                pr!.maxVolumeTotalEx != null)
                            ? (pr!.maxVolumeOrder!, pr!.maxVolumeTotalEx!)
                            : _getExerciseOrder(
                                validHistories, pr!.maxVolumeDate),
                        sessionNotes:
                            _getSessionNotes(validHistories, pr!.maxVolumeDate),
                        exerciseNotes: _getExerciseNotes(
                            validHistories, pr!.maxVolumeDate),
                        setNotes: pr!.maxVolumeNotes,
                      ),
                    ),
                  ],
                ),
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

        final isDropSet = seg.segmentOrder > 0;
        final displaySetNumber = s.setNumber > 0 ? s.setNumber : index + 1;

        final setRow = Padding(
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
                  '$weight kg × $reps',
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

        return <Widget>[
          setRow,
          if (seg.notes.isNotEmpty)
            _buildNoteRow(context, 'Set Note', seg.notes,
                leftPadding: isDropSet ? 32 : 28),
        ];
      }).expand<Widget>((widgets) => widgets as Iterable<Widget>);
    }).toList();
  }

  String? _getSessionNotes(
      List<(WorkoutSession, SessionExercise, int, int)> histories,
      String? date) {
    if (date == null) return null;
    try {
      final entry = histories
          .firstWhere((e) => e.$1.workoutDate.toIso8601String() == date);
      return entry.$1.notes.isNotEmpty ? entry.$1.notes : null;
    } catch (_) {
      return null;
    }
  }

  String? _getExerciseNotes(
      List<(WorkoutSession, SessionExercise, int, int)> histories,
      String? date) {
    if (date == null) return null;
    try {
      final entry = histories
          .firstWhere((e) => e.$1.workoutDate.toIso8601String() == date);
      return entry.$2.notes.isNotEmpty ? entry.$2.notes : null;
    } catch (_) {
      return null;
    }
  }

  (int, int)? _getExerciseOrder(
      List<(WorkoutSession, SessionExercise, int, int)> histories,
      String? date) {
    if (date == null) return null;
    try {
      final entry = histories
          .firstWhere((e) => e.$1.workoutDate.toIso8601String() == date);
      return (entry.$3, entry.$4);
    } catch (_) {
      return null;
    }
  }

  Widget _buildExerciseOrderBadge(int order, int total) {
    return Container(
      padding: const EdgeInsets.only(
        left: 6,
        right: 6,
        top: 2,
        bottom: 4,
      ),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        'Order: $order/$total',
        style: const TextStyle(
          color: AppColors.accent,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _buildNoteRow(BuildContext context, String label, String note,
      {double leftPadding = 0}) {
    if (note.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.only(bottom: 8, left: leftPadding),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 12, height: 1.4),
          children: [
            TextSpan(
              text: '$label: ',
              style: TextStyle(
                color: AppColors.textSecondary.withValues(alpha: 0.8),
                fontWeight: FontWeight.w600,
              ),
            ),
            TextSpan(
              text: note.trim(),
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPRCard(
    BuildContext context, {
    required String label,
    required String value,
    required String details,
    required IconData icon,
    bool isFullWidth = false,
    String? date,
    String? variation,
    (int, int)? exerciseOrder,
    String? sessionNotes,
    String? exerciseNotes,
    String? setNotes,
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
          if (date != null) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    _formatDate(DateTime.parse(date)),
                    style: TextStyle(
                      color: AppColors.textSecondary.withValues(alpha: 0.8),
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (exerciseOrder != null) ...[
                  const SizedBox(width: 6),
                  _buildExerciseOrderBadge(exerciseOrder.$1, exerciseOrder.$2),
                ],
              ],
            ),
          ],
          if (variation != null && variation.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              variation,
              style: TextStyle(
                color: AppColors.accent.withValues(alpha: 0.7),
                fontSize: 10,
                fontStyle: FontStyle.italic,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (sessionNotes != null && sessionNotes.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Session: $sessionNotes',
              style: TextStyle(
                color: AppColors.accent.withValues(alpha: 0.7),
                fontSize: 10,
                fontStyle: FontStyle.italic,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (exerciseNotes != null && exerciseNotes.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Exercise: $exerciseNotes',
              style: TextStyle(
                color: AppColors.accent.withValues(alpha: 0.7),
                fontSize: 10,
                fontStyle: FontStyle.italic,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (setNotes != null && setNotes.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Set: $setNotes',
              style: TextStyle(
                color: AppColors.accent.withValues(alpha: 0.7),
                fontSize: 10,
                fontStyle: FontStyle.italic,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}
