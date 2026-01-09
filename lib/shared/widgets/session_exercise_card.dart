import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/models/workout_session.dart';
import 'workout_form_widgets.dart';

class SessionExerciseCard extends StatefulWidget {
  final SessionExercise exercise;
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
  // Track which set/segment to scroll to (one-shot, cleared after use)
  int? _scrollToSetIndex;
  // GlobalKey to identify the target widget for scrolling
  final GlobalKey _scrollTargetKey = GlobalKey();

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void didUpdateWidget(SessionExerciseCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Scroll logic: if new focus indices are set, scroll to that set
    final isAddSet =
        widget.exercise.sets.length > oldWidget.exercise.sets.length;
    final hasNewScrollTarget =
        widget.focusedSetIndex != null &&
        (widget.focusedSetIndex != oldWidget.focusedSetIndex ||
            widget.focusedSegmentIndex != oldWidget.focusedSegmentIndex ||
            isAddSet ||
            (widget.focusedSetIndex! < widget.exercise.sets.length &&
                oldWidget.focusedSetIndex != null &&
                oldWidget.focusedSetIndex! < oldWidget.exercise.sets.length &&
                widget.exercise.sets[widget.focusedSetIndex!].segments.length !=
                    oldWidget
                        .exercise
                        .sets[widget.focusedSetIndex!]
                        .segments
                        .length));

    if (hasNewScrollTarget) {
      // Save the scroll target
      _scrollToSetIndex = widget.focusedSetIndex;

      // Ensure expanded first
      if (!_isExpanded) {
        setState(() {
          _isExpanded = true;
        });
      }

      // ONLY perform internal scroll if it's NOT a new set being added OR if we are not in always-expanded mode.
      // For new sets in always-expanded mode (Edit Sheet), the parent handle it.
      // For standard session tracking, the card MUST manage its own scroll.
      if (!isAddSet || !widget.isAlwaysExpanded) {
        // Schedule scroll after build with a slight delay to ensure layout is ready
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted && _scrollTargetKey.currentContext != null) {
            debugPrint(
              '[SessionExerciseCard] Internal Scroll to buttons of set: $_scrollToSetIndex',
            );
            Scrollable.ensureVisible(
              _scrollTargetKey.currentContext!,
              duration: const Duration(milliseconds: 500),
              curve: Curves.fastOutSlowIn,
              alignment: widget.isLastExercise ? 0.85 : 0.8,
            );
            // Clear scroll target after scrolling
            _scrollToSetIndex = null;
          } else {
            debugPrint(
              '[SessionExerciseCard] Internal Scroll bypassed or context null',
            );
          }
        });
      } else {
        debugPrint(
          '[SessionExerciseCard] Passing scroll responsibility to parent for Add Set (AlwaysExpanded mode)',
        );
        // Still clear indices so they don't trigger again on next update
        _scrollToSetIndex = null;
      }
    }

    // Collapse if skipped
    if (widget.exercise.skipped && !oldWidget.exercise.skipped) {
      setState(() {
        _isExpanded = false;
      });
    }

    // Expand if unskipped
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

            // Body (Collapsible)
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              alignment: Alignment.topCenter,
              child: (_isExpanded || widget.isAlwaysExpanded) && !isSkipped
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Column(
                        children: [
                          const Divider(height: 1),
                          const SizedBox(height: 16),
                          ...List.generate(sets.length, (setIndex) {
                            final set = sets[setIndex];
                            final segments = set.segments;

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSetHeader(
                                  context,
                                  set,
                                  segments.length > 1,
                                  setIndex,
                                ),
                                const SizedBox(height: 12),
                                ...List.generate(segments.length, (segIndex) {
                                  final segment = segments[segIndex];

                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          flex: 2,
                                          child: WeightField(
                                            key: ValueKey(
                                              'weight_${set.id}_${segment.id}',
                                            ),
                                            initialValue: segment.weight
                                                .toString(),
                                            onChanged: (v) =>
                                                widget.onUpdateSegment(
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
                                            key: ValueKey(
                                              'repsFrom_${set.id}_${segment.id}',
                                            ),
                                            label: 'From',
                                            initialValue: segment.repsFrom
                                                .toString(),
                                            onChanged: (v) =>
                                                widget.onUpdateSegment(
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
                                            key: ValueKey(
                                              'repsTo_${set.id}_${segment.id}',
                                            ),
                                            initialValue: segment.repsTo
                                                .toString(),
                                            onChanged: (v) =>
                                                widget.onUpdateSegment(
                                                  setIndex,
                                                  segIndex,
                                                  'repsTo',
                                                  int.tryParse(v) ?? 0,
                                                ),
                                            onDeleteTap:
                                                (segments.length > 1 &&
                                                    segIndex > 0)
                                                ? () => widget.onRemoveDropSet(
                                                    setIndex,
                                                    segIndex,
                                                  )
                                                : null,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                                const SizedBox(height: 8),
                                if (segments.isNotEmpty)
                                  NotesField(
                                    initialValue: segments[0].notes,
                                    onChanged: (v) => widget.onUpdateSegment(
                                      setIndex,
                                      0,
                                      'notes',
                                      v,
                                    ),
                                  ),
                                Padding(
                                  key: setIndex == _scrollToSetIndex
                                      ? _scrollTargetKey
                                      : null,
                                  padding: const EdgeInsets.only(top: 16),
                                  child: _buildActionButtons(
                                    context,
                                    setIndex,
                                    sets.length,
                                  ),
                                ),
                              ],
                            );
                          }),
                        ],
                      ),
                    )
                  : (!(_isExpanded || widget.isAlwaysExpanded) && !isSkipped)
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
          'Vol: ${totalVol > 0 ? totalVol.toInt() : "-"} kg',
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

  Widget _buildSetHeader(
    BuildContext context,
    ExerciseSet set,
    bool isDropSet,
    int setIndex,
  ) {
    return Column(
      children: [
        if (setIndex > 0)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1),
          ),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.cardBg, // Transparent relative to bg
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
                onTap: () => widget.onRemoveSet(setIndex),
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: const Icon(
                    Icons.close,
                    size: 18,
                    color: AppColors.error,
                  ),
                ),
              ),
          ],
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

    return Row(
      children: [
        if (isLastSet) ...[
          Expanded(
            child: SizedBox(
              height: 36,
              child: TextButton.icon(
                onPressed: () {
                  FocusScope.of(context).unfocus();
                  widget.onAddSet();
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
                widget.onAddDropSet(setIndex);
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
