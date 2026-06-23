import '../../../core/utils/app_logger.dart';
import 'package:flutter/material.dart';
import 'package:liftly/core/utils/app_formatters.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/constants/colors.dart';
import '../../../core/models/workout_session.dart';
import '../../../core/utils/muscle_detector.dart';
import '../../../shared/widgets/text/detail_stat_item.dart';
import '../../../shared/widgets/visuals/muscle_heatmap.dart';

class WorkoutShareSheet extends StatefulWidget {
  final WorkoutSession workout;
  final Map<MuscleGroup, int> workedMuscles;

  const WorkoutShareSheet({
    super.key,
    required this.workout,
    required this.workedMuscles,
  });

  @override
  State<WorkoutShareSheet> createState() => _WorkoutShareSheetState();
}

class _WorkoutShareSheetState extends State<WorkoutShareSheet> {
  final ScreenshotController _screenshotController = ScreenshotController();
  bool _isTransparent = false;
  bool _isTransparentDarkText = true;
  bool _isGenerating = false;
  int _currentTab = 0; // 0 for Log, 1 for Heatmap, 2 for Card

  late final Map<String, bool> _showOptions;

  @override
  void initState() {
    super.initState();
    final hasPlan = widget.workout.planName?.isNotEmpty ?? false;
    _showOptions = {
      'Date': true,
      'Plan': hasPlan,
      'Exercises': true,
      'Total Sets': true,
      'Total Volume': true,
      'Duration (H & m)': true,
      'Duration (Time)': true,
    };
  }

  String _formatDateWithTimeRange(DateTime date) {
    return AppFormatters.dateFull.format(date);
  }

  String _formatDuration(DateTime? startedAt, DateTime? endedAt) {
    if (startedAt == null || endedAt == null) return '-';
    final duration = endedAt.difference(startedAt);
    final h = duration.inHours;
    final m = duration.inMinutes % 60;
    return h > 0 ? '${h}h ${m}m' : '${m}m';
  }

  String _formatTimeRange(DateTime? startedAt, DateTime? endedAt) {
    if (startedAt == null || endedAt == null) return '-';
    final startTimeStr = AppFormatters.timeShort.format(startedAt);
    final endTimeStr = AppFormatters.timeShort.format(endedAt);
    return '$startTimeStr - $endTimeStr';
  }

  String _formatFullDuration(DateTime? startedAt, DateTime? endedAt) {
    final showDurationText = _showOptions['Duration (H & m)'] ?? false;
    final showTimeRange = _showOptions['Duration (Time)'] ?? false;

    if (!showDurationText && !showTimeRange) return '-';

    final duration = _formatDuration(startedAt, endedAt);
    final timeRange = _formatTimeRange(startedAt, endedAt);

    if (showDurationText && showTimeRange) {
      return '$duration ($timeRange)';
    } else if (showDurationText) {
      return duration;
    } else {
      return timeRange;
    }
  }

  void _toggleOption(String key) {
    if (key == 'Plan' && !(widget.workout.planName?.isNotEmpty ?? false)) {
      return;
    }
    final enabledCount = _showOptions.values.where((v) => v).length;
    if (enabledCount <= 3 && (_showOptions[key] ?? false)) {
      // Prevent unselecting if it would leave fewer than 3 options
      return;
    }
    setState(() {
      _showOptions[key] = !(_showOptions[key] ?? false);
    });
  }

  String _formatNumber(double number) {
    String str;
    if (number % 1 == 0) {
      str = number.toInt().toString();
    } else {
      str = number.toStringAsFixed(1);
    }
    // Add dot thousand separator
    final RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    return str.replaceAllMapped(reg, (Match m) => '${m[1]}.');
  }

  Future<void> _shareImage(BuildContext context) async {
    setState(() => _isGenerating = true);
    try {
      final image = await _screenshotController.capture(
        pixelRatio: 3.0, // High quality
      );

      if (image != null) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final fileName = 'liftly_workout_$timestamp.png';

        // Use XFile.fromData for cross-platform compatibility
        final xFile = XFile.fromData(
          image,
          name: fileName,
          mimeType: 'image/png',
        );

        if (context.mounted) {
          // ignore: deprecated_member_use
          await Share.shareXFiles([xFile], text: 'My workout on Liftly!');
        }
      }
    } catch (e, stackTrace) {
      AppLogger.error(
          'WorkoutShareSheet', 'Error sharing image', e, stackTrace);
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final workout = widget.workout;

    final totalVolume = workout.exercises.fold<double>(
      0,
      (sum, ex) => sum + (ex.skipped ? 0 : ex.totalVolume),
    );
    final exerciseCount = workout.exercises.where((ex) => !ex.skipped).length;
    final totalSets = workout.exercises.fold<int>(
      0,
      (sum, ex) => sum + (ex.skipped ? 0 : ex.sets.length),
    );

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: const BoxDecoration(
            color: AppColors.darkBg,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Stack(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Share Activity',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close,
                              color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Tabs for Log vs Heatmap
                  if (widget.workedMuscles.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.inputBg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            _buildTabButton('Log', 0),
                            _buildTabButton('Heatmap', 1),
                            _buildTabButton('Card', 2),
                          ],
                        ),
                      ),
                    ),

                  if (widget.workedMuscles.isNotEmpty)
                    const SizedBox(height: 16),

                  // Screenshot Target Area
                  Center(
                    child: SizedBox(
                      width: 280,
                      height: _calculateScreenshotHeight(),
                      child: FittedBox(
                        child: Stack(
                          children: [
                            // 1. Visual Background (Checkerboard for transparency preview)
                            if (_isTransparent)
                              Container(
                                width: 320,
                                height: _calculateContainerHeight(),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: CustomPaint(
                                      painter: CheckerboardPainter()),
                                ),
                              ),

                            // 2. The Actual Content to Capture
                            Screenshot(
                              controller: _screenshotController,
                              child: Container(
                                width: 320,
                                height: _calculateContainerHeight(),
                                decoration: BoxDecoration(
                                  color: _isTransparent
                                      ? Colors.transparent
                                      : AppColors.cardBg,
                                  borderRadius: BorderRadius.circular(16),
                                  // Ensure shadow/border only when NOT transparent to avoid artifacts
                                  border: _isTransparent
                                      ? null
                                      : Border.all(
                                          color: AppColors.borderLight),
                                ),
                                alignment: Alignment.center,
                                child: Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: _currentTab == 2
                                      ? _buildCardTabContent(workout,
                                          totalVolume, exerciseCount, totalSets)
                                      : Column(
                                          children: [
                                            // Badge - Only show if NOT generating (saving)
                                            if (_isTransparent &&
                                                !_isGenerating)
                                              Align(
                                                alignment: Alignment.topLeft,
                                                child: Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    border: Border.all(
                                                      color: Colors.white,
                                                      width: 1.5,
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            4),
                                                  ),
                                                  child: const Text(
                                                    'TRANSPARENT',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ),

                                            if (_currentTab == 0) ...[
                                              const Spacer(),
                                              if (_showOptions['Date'] ??
                                                  true) ...[
                                                _buildStatGroup(
                                                  'Date',
                                                  _formatDateWithTimeRange(
                                                      workout.effectiveDate),
                                                  isSmall: true,
                                                ),
                                                const SizedBox(height: 10),
                                              ],
                                              if ((workout.planName
                                                          ?.isNotEmpty ??
                                                      false) &&
                                                  (_showOptions['Plan'] ??
                                                      true)) ...[
                                                _buildStatGroup(
                                                    'Plan', workout.planName!),
                                                const SizedBox(height: 8),
                                              ],
                                              if (_showOptions['Exercises'] ??
                                                  true) ...[
                                                _buildStatGroup('Exercises',
                                                    '$exerciseCount'),
                                                const SizedBox(height: 8),
                                              ],
                                              if (_showOptions['Total Sets'] ??
                                                  true) ...[
                                                _buildStatGroup(
                                                    'Total Sets', '$totalSets'),
                                                const SizedBox(height: 8),
                                              ],
                                              if (_showOptions[
                                                      'Total Volume'] ??
                                                  true) ...[
                                                _buildStatGroup(
                                                  'Total Volume',
                                                  '${_formatNumber(totalVolume)} kg',
                                                ),
                                                const SizedBox(height: 8),
                                              ],
                                              if ((_showOptions[
                                                          'Duration (H & m)'] ??
                                                      true) ||
                                                  (_showOptions[
                                                          'Duration (Time)'] ??
                                                      true)) ...[
                                                _buildStatGroup(
                                                  'Duration',
                                                  _formatFullDuration(
                                                      workout.startedAt,
                                                      workout.endedAt),
                                                ),
                                                const SizedBox(height: 8),
                                              ],
                                            ] else ...[
                                              // Heatmap Tab Content
                                              const Spacer(),
                                              Text(
                                                'Muscle Heatmap',
                                                style: TextStyle(
                                                  color: _isTransparent
                                                      ? (_isTransparentDarkText
                                                          ? Colors.black87
                                                          : Colors.white)
                                                      : AppColors.textPrimary,
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.w900,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              MuscleHeatmap(
                                                workedMuscles:
                                                    widget.workedMuscles,
                                                textColor: _isTransparent
                                                    ? (_isTransparentDarkText
                                                        ? Colors.black54
                                                        : Colors.white70)
                                                    : null,
                                              ),
                                              const SizedBox(height: 16),
                                            ],

                                            // App Logo/Badge
                                            Column(
                                              children: [
                                                const Icon(
                                                  Icons.fitness_center_rounded,
                                                  color: AppColors.accent,
                                                  size: 28,
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  'LIFTLY',
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                    color: _isTransparent
                                                        ? (_isTransparentDarkText
                                                            ? Colors.black87
                                                            : Colors.white)
                                                        : AppColors.textPrimary,
                                                    fontWeight: FontWeight.w900,
                                                    fontSize: 14,
                                                    letterSpacing: 2,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  if (_currentTab == 0) ...[
                    // Display Options Checklist
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Show Data Points (min. 3)',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: _showOptions.keys.map((key) {
                              final isActive = _showOptions[key] ?? false;
                              final isDisabled = key == 'Plan' &&
                                  !(workout.planName?.isNotEmpty ?? false);

                              return GestureDetector(
                                onTap: isDisabled
                                    ? null
                                    : () => _toggleOption(key),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isDisabled
                                        ? AppColors.inputBg
                                            .withValues(alpha: 0.5)
                                        : isActive
                                            ? AppColors.accent
                                                .withValues(alpha: 0.1)
                                            : AppColors.inputBg,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isActive && !isDisabled
                                          ? AppColors.accent
                                          : Colors.transparent,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        isActive
                                            ? Icons.check_circle_rounded
                                            : Icons.circle_outlined,
                                        size: 12,
                                        color: isDisabled
                                            ? AppColors.textSecondary
                                                .withValues(alpha: 0.3)
                                            : isActive
                                                ? AppColors.accent
                                                : AppColors.textSecondary,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        key,
                                        style: TextStyle(
                                          color: isDisabled
                                              ? AppColors.textSecondary
                                                  .withValues(alpha: 0.3)
                                              : isActive
                                                  ? AppColors.textPrimary
                                                  : AppColors.textSecondary,
                                          fontSize: 11,
                                          fontWeight: isActive
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Options Row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        _buildOptionButton(
                          label: 'Normal',
                          isActive: !_isTransparent,
                          onTap: () => setState(() => _isTransparent = false),
                        ),
                        const SizedBox(width: 8),
                        _buildOptionButton(
                          label: 'Tr. Light',
                          isActive: _isTransparent && !_isTransparentDarkText,
                          onTap: () => setState(() {
                            _isTransparent = true;
                            _isTransparentDarkText = false;
                          }),
                        ),
                        const SizedBox(width: 8),
                        _buildOptionButton(
                          label: 'Tr. Dark',
                          isActive: _isTransparent && _isTransparentDarkText,
                          onTap: () => setState(() {
                            _isTransparent = true;
                            _isTransparentDarkText = true;
                          }),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Share Actions - Simplified
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildShareIcon(
                          icon: Icons.save_alt_rounded,
                          label: 'Save Image',
                          color: AppColors.accent,
                          onTap: () => _shareImage(context),
                        ),
                        _buildShareIcon(
                          icon: Icons.ios_share_rounded,
                          label: 'Share to...',
                          color: AppColors.textPrimary,
                          onTap: () => _shareImage(context),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (_isGenerating)
                Positioned.fill(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  double _calculateScreenshotHeight() {
    return _calculateContainerHeight() * (280 / 320);
  }

  double _calculateContainerHeight() {
    if (_currentTab == 1) {
      double h = 510; // Increased to prevent overflow and fit title
      if (_isTransparent && !_isGenerating) {
        h += 32; // Accommodate transparent badge
      }
      return h;
    } else if (_currentTab == 2) {
      double h =
          570; // Base height for Card layout (reduced to fit smaller heatmap)
      if (widget.workout.planName?.isNotEmpty ?? false) {
        h += 32;
      }
      if (_isTransparent && !_isGenerating) {
        h += 32;
      }
      return h;
    }
    double h = 445;
    if ((widget.workout.planName?.isNotEmpty ?? false) &&
        (_showOptions['Plan'] ?? true)) {
      h += 40;
    }
    return h;
  }

  Widget _buildTabButton(String title, int index) {
    final isActive = _currentTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _currentTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isActive ? AppColors.darkBg : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: TextStyle(
              color: isActive ? AppColors.textPrimary : AppColors.textSecondary,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatGroup(String label, String value, {bool isSmall = false}) {
    final textColor = _isTransparent
        ? (_isTransparentDarkText ? Colors.black87 : Colors.white)
        : AppColors.textPrimary;
    final labelColor = _isTransparent
        ? (_isTransparentDarkText ? Colors.black54 : Colors.white70)
        : AppColors.textSecondary;

    return Column(
      children: [
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: labelColor,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: textColor,
            fontSize: isSmall ? 16 : 24,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  Widget _buildOptionButton({
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? AppColors.accent : AppColors.inputBg,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.white : AppColors.textSecondary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShareIcon({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardTabContent(WorkoutSession workout, double totalVolume,
      int exerciseCount, int totalSets) {
    final textColor = _isTransparent
        ? (_isTransparentDarkText ? Colors.black87 : Colors.white)
        : AppColors.textPrimary;
    final labelColor = _isTransparent
        ? (_isTransparentDarkText ? Colors.black54 : Colors.white70)
        : AppColors.textSecondary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Badge
        if (_isTransparent && !_isGenerating)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: 1.5),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              'TRANSPARENT',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold),
            ),
          ),

        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            '${_formatDateWithTimeRange(workout.effectiveDate)}'
            '${(workout.startedAt != null && workout.endedAt != null) ? ' (${_formatTimeRange(workout.startedAt, workout.endedAt)})' : ''}',
            style: TextStyle(
              color: textColor,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        if (workout.planName?.isNotEmpty ?? false) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.bookmark, color: AppColors.accent, size: 16),
              const SizedBox(width: 8),
              Text(
                workout.planName!,
                style: const TextStyle(
                  color: AppColors.accent,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: DetailStatItem(
                icon: Icons.timer_rounded,
                value: _formatDuration(workout.startedAt, workout.endedAt),
                label: 'Duration',
                color: AppColors.accent,
                valueColor: textColor,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: DetailStatItem(
                icon: Icons.fitness_center_rounded,
                value: '$exerciseCount',
                label: 'Exercises',
                color: const Color(0xFF6366F1),
                valueColor: textColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: DetailStatItem(
                icon: Icons.format_list_numbered_rounded,
                value: '$totalSets',
                label: 'Total Sets',
                color: const Color(0xFFF59E0B),
                valueColor: textColor,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: DetailStatItem(
                icon: Icons.scale_rounded,
                value: _formatNumber(totalVolume),
                label: 'Total Volume',
                color: const Color(0xFF10B981),
                unit: 'kg',
                valueColor: textColor,
                unitColor: labelColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          'Muscle Heatmap',
          style: TextStyle(
            color: labelColor,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        MuscleHeatmap(
          workedMuscles: widget.workedMuscles,
          textColor: labelColor,
          height: 160, // Smaller height to prevent overflow in Card view
        ),
        // App Logo/Badge
        Center(
          child: Column(
            children: [
              const Icon(
                Icons.fitness_center_rounded,
                color: AppColors.accent,
                size: 28,
              ),
              const SizedBox(height: 4),
              Text(
                'LIFTLY',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class CheckerboardPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white24;
    const squareSize = 20.0;
    for (double i = 0; i < size.width; i += squareSize * 2) {
      for (double j = 0; j < size.height; j += squareSize * 2) {
        canvas.drawRect(Rect.fromLTWH(i, j, squareSize, squareSize), paint);
        canvas.drawRect(
          Rect.fromLTWH(i + squareSize, j + squareSize, squareSize, squareSize),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
