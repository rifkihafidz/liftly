import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:liftly/core/utils/app_formatters.dart';
import '../../../core/constants/colors.dart';
import '../../../core/models/workout_session.dart';
import '../../../core/models/personal_record.dart';

class SessionExerciseHistorySheet extends StatefulWidget {
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

  @override
  State<SessionExerciseHistorySheet> createState() =>
      _SessionExerciseHistorySheetState();
}

class _SessionExerciseHistorySheetState
    extends State<SessionExerciseHistorySheet> {
  late final List<(WorkoutSession, SessionExercise, int, int)> _validHistories;
  List<ExerciseSet>? _bestSets;
  String? _bestSessionDate;
  double _bestSessionVol = 0;
  bool _showBestSessionSection = false;

  @override
  void initState() {
    super.initState();
    _calculateHistories();
  }

  void _calculateHistories() {
    _validHistories = [];

    if (widget.histories != null) {
      for (final h in widget.histories!) {
        final allExercises = h.exercises;
        final totalExercises = allExercises.length;
        final matchingIndices = allExercises
            .asMap()
            .entries
            .where((e) =>
                e.value.name.toLowerCase() ==
                    widget.exerciseName.toLowerCase() &&
                e.value.variation.toLowerCase() ==
                    widget.exerciseVariation.toLowerCase())
            .toList();

        if (matchingIndices.isEmpty) continue;

        final firstIndex = matchingIndices.first.key;
        final merged = matchingIndices.map((e) => e.value).reduce((a, b) {
          final mergedSets = <ExerciseSet>[...a.sets, ...b.sets]
              .asMap()
              .entries
              .map((e) => e.value.copyWith(setNumber: e.key + 1))
              .toList();
          return a.copyWith(sets: mergedSets);
        });
        _validHistories.add((h, merged, firstIndex + 1, totalExercises));
      }
    }

    final showHistory = _validHistories.isNotEmpty;

    if (widget.pr?.bestSessionSets != null) {
      _bestSets = widget.pr!.bestSessionSets;
      _bestSessionDate = widget.pr!.bestSessionDate;
      _bestSessionVol = widget.pr!.bestSessionVolume;
    } else if (showHistory) {
      final firstHistory = _validHistories.first;
      _bestSets = firstHistory.$2.sets;
      _bestSessionDate = firstHistory.$1.workoutDate.toIso8601String();
      _bestSessionVol = firstHistory.$2.totalVolume;
    }

    _showBestSessionSection =
        _bestSets != null && _bestSets!.isNotEmpty && _bestSessionVol > 0;
  }

  String _formatNumber(double value) {
    return AppFormatters.weightFormatter.format(value);
  }

  String _formatDate(DateTime date) {
    return AppFormatters.dateShort.format(date);
  }

  Future<void> _copyLast2Sessions() async {
    if (_validHistories.isEmpty) return;

    final buffer = StringBuffer();
    buffer.writeln('Last 2 session:');

    final toCopy = _validHistories.take(2).toList();
    for (int i = 0; i < toCopy.length; i++) {
      final entry = toCopy[i];
      final session = entry.$1;
      final exercise = entry.$2;

      final dateStr = AppFormatters.dateFull.format(session.workoutDate);
      final planNameStr =
          (session.planName != null && session.planName!.isNotEmpty)
              ? '(${session.planName}) '
              : '';
      final sessionNoteStr =
          session.notes.isNotEmpty ? '(${session.notes})' : '';

      buffer.writeln('$dateStr $planNameStr$sessionNoteStr'.trimRight());
      buffer.writeln();

      for (int setIdx = 0; setIdx < exercise.sets.length; setIdx++) {
        final set = exercise.sets[setIdx];
        if (set.segments.isEmpty) continue;

        final displaySetNumber = set.setNumber > 0 ? set.setNumber : setIdx + 1;

        String setLine = 'Set $displaySetNumber ';

        for (int segIdx = 0; segIdx < set.segments.length; segIdx++) {
          final seg = set.segments[segIdx];
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

          if (segIdx == 0) {
            setLine += '${weight}kg x $reps';
          } else {
            setLine += ' -> drop $weight $reps';
          }

          if (seg.notes.isNotEmpty) {
            setLine += ' (${seg.notes})';
          }
        }
        buffer.writeln(setLine);
      }

      if (i < toCopy.length - 1) {
        buffer.writeln();
      }
    }

    await Clipboard.setData(ClipboardData(text: buffer.toString()));

    if (mounted) {
      final overlay = Overlay.of(context);
      late OverlayEntry entry;
      entry = OverlayEntry(
        builder: (context) => Positioned(
          bottom: MediaQuery.of(context).viewInsets.bottom + 32,
          left: 24,
          right: 24,
          child: Material(
            color: Colors.transparent,
            child: TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 200),
              tween: Tween(begin: 0.0, end: 1.0),
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, (1 - value) * 10),
                    child: child,
                  ),
                );
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderDark),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Text(
                  'Copied to clipboard',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      overlay.insert(entry);
      Future.delayed(const Duration(milliseconds: 2000), () {
        if (entry.mounted) {
          entry.remove();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final showHistory = _validHistories.isNotEmpty;

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
                        widget.exerciseName,
                        style: Theme.of(
                          context,
                        )
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      if (widget.exerciseVariation.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            widget.exerciseVariation,
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
                if (showHistory) ...[
                  IconButton(
                    onPressed: _copyLast2Sessions,
                    icon: const Icon(Icons.copy,
                        color: AppColors.textSecondary, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 16),
                ],
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
              for (final entry in _validHistories) ...[
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
            if (_showBestSessionSection) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            'Best Session${_bestSessionDate != null ? " (${_formatDate(DateTime.parse(_bestSessionDate!))})" : ""}',
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
                        if (_bestSessionDate != null &&
                            ((widget.pr?.bestSessionOrder != null &&
                                    widget.pr?.bestSessionTotalEx != null) ||
                                _getExerciseOrder(
                                        _validHistories, _bestSessionDate) !=
                                    null)) ...[
                          const SizedBox(width: 8),
                          _buildExerciseOrderBadge(
                            widget.pr?.bestSessionOrder ??
                                _getExerciseOrder(
                                        _validHistories, _bestSessionDate)!
                                    .$1,
                            widget.pr?.bestSessionTotalEx ??
                                _getExerciseOrder(
                                        _validHistories, _bestSessionDate)!
                                    .$2,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Total: ${_formatNumber(_bestSessionVol)} kg',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.accent,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ..._renderSets(context, _bestSets ?? []),
              const SizedBox(height: 24),
            ],
            if (widget.pr != null) ...[
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
                        value: '${_formatNumber(widget.pr!.maxWeight)} kg',
                        details: '${widget.pr!.maxWeightReps} reps',
                        icon: Icons.fitness_center_rounded,
                        date: widget.pr!.maxWeightDate,
                        variation: widget.exerciseVariation,
                        exerciseOrder: (widget.pr!.maxWeightOrder != null &&
                                widget.pr!.maxWeightTotalEx != null)
                            ? (
                                widget.pr!.maxWeightOrder!,
                                widget.pr!.maxWeightTotalEx!
                              )
                            : _getExerciseOrder(
                                _validHistories, widget.pr!.maxWeightDate),
                        sessionNotes: _getSessionNotes(
                            _validHistories, widget.pr!.maxWeightDate),
                        exerciseNotes: _getExerciseNotes(
                            _validHistories, widget.pr!.maxWeightDate),
                        setNotes: widget.pr!.maxWeightNotes,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildPRCard(
                        context,
                        label: 'Best Volume Set',
                        value: '${_formatNumber(widget.pr!.maxVolume)} kg',
                        details: widget.pr!.maxVolumeBreakdown.isNotEmpty
                            ? widget.pr!.maxVolumeBreakdown
                            : '${_formatNumber(widget.pr!.maxVolumeWeight)} kg x ${widget.pr!.maxVolumeReps}',
                        icon: Icons.auto_graph_rounded,
                        date: widget.pr!.maxVolumeDate,
                        variation: widget.exerciseVariation,
                        exerciseOrder: (widget.pr!.maxVolumeOrder != null &&
                                widget.pr!.maxVolumeTotalEx != null)
                            ? (
                                widget.pr!.maxVolumeOrder!,
                                widget.pr!.maxVolumeTotalEx!
                              )
                            : _getExerciseOrder(
                                _validHistories, widget.pr!.maxVolumeDate),
                        sessionNotes: _getSessionNotes(
                            _validHistories, widget.pr!.maxVolumeDate),
                        exerciseNotes: _getExerciseNotes(
                            _validHistories, widget.pr!.maxVolumeDate),
                        setNotes: widget.pr!.maxVolumeNotes,
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
