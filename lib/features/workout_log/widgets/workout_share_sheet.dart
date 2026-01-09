import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/constants/colors.dart';
import '../../../core/models/workout_session.dart';

class WorkoutShareSheet extends StatefulWidget {
  final WorkoutSession workout;

  const WorkoutShareSheet({super.key, required this.workout});

  @override
  State<WorkoutShareSheet> createState() => _WorkoutShareSheetState();
}

class _WorkoutShareSheetState extends State<WorkoutShareSheet> {
  final ScreenshotController _screenshotController = ScreenshotController();
  bool _isTransparent = false;
  bool _isGenerating = false;

  String _formatDuration(Duration duration) {
    final h = duration.inHours;
    final m = duration.inMinutes % 60;
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
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
        final directory = await getTemporaryDirectory();
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final imagePath = await File(
          '${directory.path}/liftly_workout_$timestamp.png',
        ).create();
        await imagePath.writeAsBytes(image);

        if (context.mounted) {
          // ignore: deprecated_member_use
          await Share.shareXFiles([
            XFile(imagePath.path),
          ], text: 'My workout on Liftly!');
        }
      }
    } catch (e, stackTrace) {
      log(
        'Error sharing image',
        name: 'WorkoutShareSheet',
        error: e,
        stackTrace: stackTrace,
      );
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final workout = widget.workout;
    final duration = workout.endedAt != null && workout.startedAt != null
        ? workout.endedAt!.difference(workout.startedAt!)
        : Duration.zero;

    final totalVolume = workout.exercises.fold<double>(
      0,
      (sum, ex) => sum + (ex.skipped ? 0 : ex.totalVolume),
    );
    final exerciseCount = workout.exercises.where((ex) => !ex.skipped).length;
    final totalSets = workout.exercises.fold<int>(
      0,
      (sum, ex) => sum + (ex.skipped ? 0 : ex.sets.length),
    );

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: const BoxDecoration(
        color: AppColors.darkBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
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
                  icon: const Icon(Icons.close, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Screenshot Target Area
          Center(
            child: Stack(
              children: [
                // 1. Visual Background (Checkerboard for transparency preview)
                if (_isTransparent)
                  Container(
                    width: 320,
                    height: 400,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: CustomPaint(painter: CheckerboardPainter()),
                    ),
                  ),

                // 2. The Actual Content to Capture
                Screenshot(
                  controller: _screenshotController,
                  child: Container(
                    width: 320,
                    height: 400,
                    decoration: BoxDecoration(
                      color: _isTransparent
                          ? Colors.transparent
                          : AppColors.cardBg,
                      borderRadius: BorderRadius.circular(16),
                      // Ensure shadow/border only when NOT transparent to avoid artifacts
                      border: _isTransparent
                          ? null
                          : Border.all(color: AppColors.borderLight),
                    ),
                    alignment: Alignment.center,
                    child: Stack(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Badge - Only show if NOT generating (saving)
                              if (_isTransparent && !_isGenerating)
                                Align(
                                  alignment: Alignment.topLeft,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 1.5,
                                      ),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'TRANSPARENT',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),

                              const Spacer(),

                              _buildStatGroup('Exercises', '$exerciseCount'),
                              const SizedBox(height: 12),
                              _buildStatGroup('Total Sets', '$totalSets'),
                              const SizedBox(height: 12),
                              _buildStatGroup(
                                'Total Volume',
                                '${_formatNumber(totalVolume)} kg',
                              ),
                              const SizedBox(height: 12),
                              _buildStatGroup(
                                'Duration',
                                _formatDuration(duration),
                              ),

                              const Spacer(),

                              // App Logo/Badge
                              Column(
                                children: [
                                  Icon(
                                    Icons.fitness_center_rounded,
                                    color: AppColors.accent,
                                    size: 28,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'LIFTLY',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: AppColors.textPrimary,
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
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Options Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                _buildOptionButton(
                  label: 'Classic',
                  isActive: !_isTransparent,
                  onTap: () => setState(() => _isTransparent = false),
                ),
                const SizedBox(width: 12),
                _buildOptionButton(
                  label: 'Transparent',
                  isActive: _isTransparent,
                  onTap: () => setState(() => _isTransparent = true),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

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

          if (_isGenerating)
            Container(
              color: Colors.black54,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildStatGroup(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 24,
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
