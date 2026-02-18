import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/colors.dart';
import '../../core/models/workout_session.dart';
import '../../core/models/personal_record.dart';

import 'workout_form_widgets.dart';

class SessionExerciseCard extends StatefulWidget {
  final SessionExercise exercise;
  final int exerciseIndex;
  final WorkoutSession? history;
  final PersonalRecord? pr;
  final VoidCallback onSkipToggle;
  final VoidCallback onHistoryTap;
  final VoidCallback onAddSet;
  final Function(int setIndex) onRemoveSet;
  final Function(int setIndex) onAddDropSet;
  final Function(int setIndex, int segmentIndex) onRemoveDropSet;
  final Function(int setIndex, int segmentIndex, String field, dynamic value)
      onUpdateSegment;
  final VoidCallback? onEditName;
  final VoidCallback? onDelete;
  final int? focusedSetIndex;
  final int? focusedSegmentIndex;
  final bool isAlwaysExpanded;
  final bool isLastExercise;

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
    this.onEditName,
    this.onDelete,
    this.focusedSetIndex,
    this.focusedSegmentIndex,
    this.isAlwaysExpanded = false,
    this.isLastExercise = false,
  });

  @override
  State<SessionExerciseCard> createState() => _SessionExerciseCardState();
}

class _SessionExerciseCardState extends State<SessionExerciseCard> {
  bool _isExpanded = true;
  int? _scrollToSetIndex;
  final GlobalKey _scrollTargetKey = GlobalKey();

  @override
  void dispose() {
    super.dispose();
  }

  String _formatNumber(double value) {
    final formatter = NumberFormat('#,###.##', 'pt_BR');
    return formatter.format(value);
  }

  @override
  void didUpdateWidget(SessionExerciseCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    final isAddSet =
        widget.exercise.sets.length > oldWidget.exercise.sets.length;
    final hasNewScrollTarget = (widget.focusedSetIndex != null &&
            (widget.focusedSetIndex != oldWidget.focusedSetIndex ||
                widget.focusedSegmentIndex != oldWidget.focusedSegmentIndex ||
                isAddSet ||
                (widget.focusedSetIndex! < widget.exercise.sets.length &&
                    oldWidget.focusedSetIndex != null &&
                    oldWidget.focusedSetIndex! <
                        oldWidget.exercise.sets.length &&
                    widget.exercise.sets[widget.focusedSetIndex!].segments
                            .length !=
                        oldWidget.exercise.sets[widget.focusedSetIndex!]
                            .segments.length))) ||
        (isAddSet && widget.focusedSetIndex == null);

    if (hasNewScrollTarget) {
      _scrollToSetIndex = widget.focusedSetIndex ??
          (isAddSet ? widget.exercise.sets.length - 1 : null);

      if (!_isExpanded) {
        setState(() {
          _isExpanded = true;
        });
      }

      // Use WidgetsBinding to scroll after the frame is rendered
      // This ensures the layout is complete before scrolling
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _scrollTargetKey.currentContext == null) return;

        // Use a short delay to ensure keyboard dismissal animation completes
        Future.delayed(const Duration(milliseconds: 300), () {
          if (!mounted || _scrollTargetKey.currentContext == null) return;

          // If keyboard is open, pull the target row higher (alignment 0.15)
          // to ensure buttons below it (Add Set, etc.) remain visible.
          final media = MediaQuery.of(_scrollTargetKey.currentContext!);
          final keyboardHeight = media.viewInsets.bottom;
          final isKeyboardOpen = keyboardHeight > 100;

          double alignment;
          if (isKeyboardOpen) {
            alignment = 0.15; // Pull up to top 15% of visible area
          } else {
            alignment = widget.isLastExercise ? 0.7 : 0.45;
          }

          Scrollable.ensureVisible(
            _scrollTargetKey.currentContext!,
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutCubic,
            alignment: alignment,
          ).then((_) {
            if (mounted) {
              setState(() {
                _scrollToSetIndex = null;
              });
            }
          });
        });
      });
    }

    if (widget.exercise.skipped && !oldWidget.exercise.skipped) {
      setState(() {
        _isExpanded = false;
      });
    }

    if (!widget.exercise.skipped && oldWidget.exercise.skipped) {
      setState(() {
        _isExpanded = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final sets = widget.exercise.sets;
    final isSkipped = widget.exercise.skipped;

    return RepaintBoundary(
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSkipped
                ? AppColors.borderLight.withValues(alpha: 0.5)
                : AppColors.borderLight,
            width: 1,
          ),
          boxShadow: [
            if (_isExpanded || widget.isAlwaysExpanded)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header (Always visible)
            InkWell(
              onTap: isSkipped || widget.isAlwaysExpanded
                  ? null
                  : () => setState(() => _isExpanded = !_isExpanded),
              borderRadius: BorderRadius.vertical(
                top: const Radius.circular(16),
                bottom: Radius.circular(
                  (_isExpanded || widget.isAlwaysExpanded) ? 0 : 16,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _buildHeader(context, isSkipped),
              ),
            ),

            // Body (Collapsible) - Skip AnimatedSize when always expanded for better performance
            if (widget.isAlwaysExpanded && !isSkipped)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  children: [
                    const Divider(height: 1),
                    if (widget.pr != null) ...[
                      const SizedBox(height: 12),
                      _buildPRSummary(context),
                      const SizedBox(height: 12),
                      const Divider(height: 1),
                    ],
                    const SizedBox(height: 16),
                    for (int setIndex = 0; setIndex < sets.length; setIndex++)
                      _SetRow(
                        key: ValueKey('set_row_${sets[setIndex].id}'),
                        set: sets[setIndex],
                        setIndex: setIndex,
                        totalSets: sets.length,
                        exerciseName: widget.exercise.name,
                        scrollTargetKey: setIndex == _scrollToSetIndex
                            ? _scrollTargetKey
                            : null,
                        onUpdateSegment: widget.onUpdateSegment,
                        onRemoveSet: widget.onRemoveSet,
                        onAddSet: widget.onAddSet,
                        onAddDropSet: widget.onAddDropSet,
                        onRemoveDropSet: widget.onRemoveDropSet,
                        isLastExercise: widget.isLastExercise,
                      ),
                  ],
                ),
              )
            else
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                alignment: Alignment.topCenter,
                child: _isExpanded && !isSkipped
                    ? Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Column(
                          children: [
                            const Divider(height: 1),
                            if (widget.pr != null) ...[
                              const SizedBox(height: 12),
                              _buildPRSummary(context),
                              const SizedBox(height: 12),
                              const Divider(height: 1),
                            ],
                            const SizedBox(height: 16),
                            for (int setIndex = 0;
                                setIndex < sets.length;
                                setIndex++)
                              _SetRow(
                                key: ValueKey('set_row_${sets[setIndex].id}'),
                                set: sets[setIndex],
                                setIndex: setIndex,
                                totalSets: sets.length,
                                exerciseName: widget.exercise.name,
                                scrollTargetKey: setIndex == _scrollToSetIndex
                                    ? _scrollTargetKey
                                    : null,
                                onUpdateSegment: widget.onUpdateSegment,
                                onRemoveSet: widget.onRemoveSet,
                                onAddSet: widget.onAddSet,
                                onAddDropSet: widget.onAddDropSet,
                                onRemoveDropSet: widget.onRemoveDropSet,
                                isLastExercise: widget.isLastExercise,
                              ),
                          ],
                        ),
                      )
                    : (!_isExpanded && !isSkipped)
                        ? Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            child: _buildCollapsedSummary(context),
                          )
                        : const SizedBox.shrink(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCollapsedSummary(BuildContext context) {
    final sets = widget.exercise.sets;
    final setCount = sets.length;
    final totalVol = widget.exercise.totalVolume;

    return Row(
      children: [
        Icon(Icons.layers_outlined, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Text(
          '$setCount Sets',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(width: 16),
        Icon(Icons.fitness_center, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Text(
          'Vol: ${totalVol > 0 ? _formatNumber(totalVol) : "-"} kg',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, bool isSkipped) {
    return Row(
      children: [
        // Exercise Name & Number
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.exercise.name,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isSkipped
                          ? AppColors.textSecondary
                          : AppColors.textPrimary,
                      decoration: isSkipped ? TextDecoration.lineThrough : null,
                    ),
              ),
            ],
          ),
        ),

        // Actions
        if (widget.history != null || widget.pr != null)
          IconButton(
            icon: const Icon(
              Icons.history,
              size: 20,
              color: AppColors.textSecondary,
            ),
            tooltip: 'View History & PR',
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.all(8),
            onPressed: widget.onHistoryTap,
          ),

        // Skip Button (Compact Chip)
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onSkipToggle,
            borderRadius: BorderRadius.circular(20),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isSkipped
                    ? AppColors.textSecondary.withValues(alpha: 0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSkipped
                      ? Colors.transparent
                      : AppColors.borderLight.withValues(alpha: 0.5),
                ),
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Row(
                  key: ValueKey(isSkipped),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isSkipped
                          ? Icons.check_circle_outline
                          : Icons.circle_outlined,
                      size: 14,
                      color: isSkipped
                          ? AppColors.textSecondary
                          : AppColors.textSecondary.withValues(alpha: 0.7),
                    ),
                    if (isSkipped) ...[
                      const SizedBox(width: 4),
                      Text(
                        'Skipped',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                              fontSize: 10,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),

        // Menu
        if (widget.onEditName != null || widget.onDelete != null)
          PopupMenuButton<String>(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: const Icon(
              Icons.more_vert,
              size: 20,
              color: AppColors.textSecondary,
            ),
            onSelected: (value) {
              if (value == 'edit' && widget.onEditName != null) {
                widget.onEditName!();
              } else if (value == 'delete' && widget.onDelete != null) {
                widget.onDelete!();
              }
            },
            itemBuilder: (context) => [
              if (widget.onEditName != null)
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 20),
                      SizedBox(width: 8),
                      Text('Rename'),
                    ],
                  ),
                ),
              if (widget.onDelete != null)
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: AppColors.error, size: 20),
                      SizedBox(width: 8),
                      Text('Remove', style: TextStyle(color: AppColors.error)),
                    ],
                  ),
                ),
            ],
          ),

        // Expand/Collapse Chevron
        const SizedBox(width: 4),
        if (!widget.isAlwaysExpanded)
          Icon(
            _isExpanded
                ? Icons.keyboard_arrow_up_rounded
                : Icons.keyboard_arrow_down_rounded,
            color: AppColors.textSecondary,
            size: 24,
          ),
      ],
    );
  }

  Widget _buildPRSummary(BuildContext context) {
    final pr = widget.pr!;
    return Row(
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
                '${_formatNumber(pr.maxWeight)} kg',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${pr.maxWeightReps} reps',
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
                '${_formatNumber(pr.maxVolume)} kg',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                pr.maxVolumeBreakdown.isNotEmpty
                    ? pr.maxVolumeBreakdown
                    : '${_formatNumber(pr.maxVolumeWeight)} kg x ${pr.maxVolumeReps}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Extracted widget for a single set row - allows Flutter to skip rebuilding
/// unchanged sets when only one set changes.
class _SetRow extends StatelessWidget {
  final ExerciseSet set;
  final int setIndex;
  final int totalSets;
  final String exerciseName;
  final GlobalKey? scrollTargetKey;
  final Function(int setIndex, int segmentIndex, String field, dynamic value)
      onUpdateSegment;
  final Function(int setIndex) onRemoveSet;
  final VoidCallback onAddSet;
  final Function(int setIndex) onAddDropSet;
  final Function(int setIndex, int segmentIndex) onRemoveDropSet;
  final bool isLastExercise;

  const _SetRow({
    super.key,
    required this.set,
    required this.setIndex,
    required this.totalSets,
    required this.exerciseName,
    this.scrollTargetKey,
    required this.onUpdateSegment,
    required this.onRemoveSet,
    required this.onAddSet,
    required this.onAddDropSet,
    required this.onRemoveDropSet,
    required this.isLastExercise,
  });

  @override
  Widget build(BuildContext context) {
    final segments = set.segments;
    final isDropSet = segments.length > 1;

    final targetedPadding = isLastExercise
        ? const EdgeInsets.only(bottom: 175)
        : const EdgeInsets.only(bottom: 150);

    return RepaintBoundary(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SetHeader(
            set: set,
            setIndex: setIndex,
            exerciseName: exerciseName,
            isDropSet: isDropSet,
            onRemoveSet: onRemoveSet,
          ),
          const SizedBox(height: 12),
          // Use indexed iteration instead of List.generate
          for (int segIndex = 0; segIndex < segments.length; segIndex++)
            _SegmentRow(
              key: ValueKey('seg_row_${set.id}_${segments[segIndex].id}'),
              segment: segments[segIndex],
              previousSegment: segIndex > 0 ? segments[segIndex - 1] : null,
              setIndex: setIndex,
              segmentIndex: segIndex,
              setId: set.id,
              canDelete: segments.length > 1 && segIndex > 0,
              onUpdateSegment: onUpdateSegment,
              onRemoveDropSet: onRemoveDropSet,
              scrollPadding: targetedPadding,
            ),
          const SizedBox(height: 8),
          if (segments.isNotEmpty)
            NotesField(
              key: ValueKey('notes_${set.id}'),
              initialValue: segments[0].notes,
              onChanged: (v) => onUpdateSegment(setIndex, 0, 'notes', v),
              scrollPadding: targetedPadding,
            ),
          Padding(
            key: scrollTargetKey,
            padding: const EdgeInsets.only(top: 16),
            child: _ActionButtons(
              setIndex: setIndex,
              totalSets: totalSets,
              onAddSet: onAddSet,
              onAddDropSet: onAddDropSet,
            ),
          ),
        ],
      ),
    );
  }
}

/// Extracted widget for set header - static UI that rarely changes
class _SetHeader extends StatelessWidget {
  final ExerciseSet set;
  final int setIndex;
  final String exerciseName;
  final bool isDropSet;
  final Function(int setIndex) onRemoveSet;

  const _SetHeader({
    required this.set,
    required this.setIndex,
    required this.exerciseName,
    required this.isDropSet,
    required this.onRemoveSet,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (setIndex > 0)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1),
          ),
        // Exercise name badge - shows context for which exercise user is working on
        if (setIndex > 0)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.textSecondary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                exerciseName.toUpperCase(),
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                border: Border.all(color: AppColors.accent, width: 1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Set ${set.setNumber}',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.accent,
                    ),
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
                  'DROP SET',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.accent,
                        fontWeight: FontWeight.w900,
                        fontSize: 10,
                        letterSpacing: 0.5,
                      ),
                ),
              ),
            const Spacer(),
            const Spacer(),
            if (setIndex > 0)
              InkWell(
                onTap: () => onRemoveSet(setIndex),
                borderRadius: BorderRadius.circular(16),
                child: const Padding(
                  padding: EdgeInsets.all(4.0),
                  child: Icon(Icons.close, size: 18, color: AppColors.error),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// Extracted widget for a single segment row - allows Flutter to skip rebuilding
/// unchanged segments when only one segment is edited.
class _SegmentRow extends StatelessWidget {
  final SetSegment segment;
  final SetSegment? previousSegment;
  final int setIndex;
  final int segmentIndex;
  final String setId;
  final bool canDelete;
  final Function(int setIndex, int segmentIndex, String field, dynamic value)
      onUpdateSegment;
  final Function(int setIndex, int segmentIndex) onRemoveDropSet;
  final EdgeInsets scrollPadding;

  const _SegmentRow({
    super.key,
    required this.segment,
    this.previousSegment,
    required this.setIndex,
    required this.segmentIndex,
    required this.setId,
    required this.canDelete,
    required this.onUpdateSegment,
    required this.onRemoveDropSet,
    this.scrollPadding = const EdgeInsets.all(20.0),
  });

  @override
  Widget build(BuildContext context) {
    // Validation Logic
    final isToInvalid = segment.repsTo < segment.repsFrom;
    final isDropSetInvalid = segmentIndex > 0 &&
        previousSegment != null &&
        (segment.repsFrom <= previousSegment!.repsFrom ||
            segment.repsTo <= previousSegment!.repsTo);

    return RepaintBoundary(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: WeightField(
                key: ValueKey('weight_${setId}_${segment.id}'),
                initialValue: segment.weight.toString(),
                onChanged: (v) => onUpdateSegment(
                  setIndex,
                  segmentIndex,
                  'weight',
                  double.tryParse(v.replaceAll(',', '.')) ?? 0,
                ),
                scrollPadding: scrollPadding,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: NumberField(
                key: ValueKey('repsFrom_${setId}_${segment.id}'),
                label: 'From',
                initialValue: segment.repsFrom.toString(),
                onChanged: (v) => onUpdateSegment(
                  setIndex,
                  segmentIndex,
                  'repsFrom',
                  int.tryParse(v) ?? 0,
                ),
                hasError: isDropSetInvalid,
                scrollPadding: scrollPadding,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ToField(
                key: ValueKey('repsTo_${setId}_${segment.id}'),
                initialValue: segment.repsTo.toString(),
                onChanged: (v) => onUpdateSegment(
                  setIndex,
                  segmentIndex,
                  'repsTo',
                  int.tryParse(v) ?? 0,
                ),
                onDeleteTap: canDelete
                    ? () => onRemoveDropSet(setIndex, segmentIndex)
                    : null,
                hasError: isToInvalid || isDropSetInvalid,
                scrollPadding: scrollPadding,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Extracted widget for action buttons - static UI that only depends on position
class _ActionButtons extends StatelessWidget {
  final int setIndex;
  final int totalSets;
  final VoidCallback onAddSet;
  final Function(int setIndex) onAddDropSet;

  const _ActionButtons({
    required this.setIndex,
    required this.totalSets,
    required this.onAddSet,
    required this.onAddDropSet,
  });

  @override
  Widget build(BuildContext context) {
    final bool isLastSet = setIndex == totalSets - 1;

    return Row(
      children: [
        if (isLastSet) ...[
          Expanded(
            child: SizedBox(
              height: 36,
              child: TextButton.icon(
                onPressed: () {
                  FocusScope.of(context).unfocus();
                  onAddSet();
                },
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Set'),
                style: TextButton.styleFrom(
                  backgroundColor: AppColors.inputBg,
                  foregroundColor: AppColors.textPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: SizedBox(
            height: 36,
            child: TextButton.icon(
              onPressed: () {
                FocusScope.of(context).unfocus();
                onAddDropSet(setIndex);
              },
              icon: const Icon(Icons.subdirectory_arrow_right, size: 16),
              label: const Text('Drop Set'),
              style: TextButton.styleFrom(
                backgroundColor: AppColors.inputBg,
                foregroundColor: AppColors.textSecondary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
