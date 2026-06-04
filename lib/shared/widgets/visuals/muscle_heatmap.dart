import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../core/utils/muscle_detector.dart';
import '../../../core/constants/anatomy_points.dart';

class MuscleHeatmap extends StatelessWidget {
  final Map<MuscleGroup, int> workedMuscles;

  const MuscleHeatmap({
    super.key,
    required this.workedMuscles,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              _buildLegendItem(Colors.yellow, '1-4 sets'),
              _buildLegendItem(Colors.orange, '5-8 sets'),
              _buildLegendItem(Colors.red, '>8 sets'),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 240,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Expanded(
                        child: AspectRatio(
                          aspectRatio: 100 / 220,
                          child: CustomPaint(
                            painter: AnatomyPainter(
                              workedMuscles: workedMuscles,
                              isFront: true,
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),
                    const Text(
                      'FRONT',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
                // Divider
                Container(
                  width: 1,
                  color: AppColors.borderDark,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Expanded(
                        child: AspectRatio(
                          aspectRatio: 100 / 220,
                          child: CustomPaint(
                            painter: AnatomyPainter(
                              workedMuscles: workedMuscles,
                              isFront: false,
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),
                    const Text(
                      'BACK',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class AnatomyPainter extends CustomPainter {
  final Map<MuscleGroup, int> workedMuscles;
  final bool isFront;

  const AnatomyPainter({required this.workedMuscles, required this.isFront});

  static const double _vW = 100.0;

  @override
  void paint(Canvas canvas, Size size) {
    final scaleX = size.width / _vW;
    
    // Front and back have different original SVG path bounds
    // The head path for both actually starts at Y = 0.
    final double pathMinY = 0.0;
    final double pathMaxY = isFront ? 212.0 : 222.0;
    final double pathHeight = pathMaxY - pathMinY;

    // Use 95% of available height to avoid clipping bounds
    final double targetHeight = size.height * 0.95;
    final double scaleY = targetHeight / pathHeight;
    final double shiftY = (size.height - targetHeight) / 2 - (pathMinY * scaleY);

    final shiftX = 0.0;

    final basePaint = Paint()
      ..color = AppColors.textSecondary.withValues(alpha: 0.18)
      ..style = PaintingStyle.fill;

    Paint getPaint(MuscleGroup group) {
      if (!workedMuscles.containsKey(group)) return basePaint;
      
      final count = workedMuscles[group]!;
      Color intensityColor;
      if (count <= 4) {
        intensityColor = Colors.yellow;
      } else if (count <= 8) {
        intensityColor = Colors.orange;
      } else {
        intensityColor = Colors.red;
      }
      
      return Paint()
        ..color = intensityColor
        ..style = PaintingStyle.fill;
    }

    // Build a closed Path from a space-separated string of "x y x y ..." coords
    Path buildPath(String pathStr) {
      final path = Path();
      final points = pathStr.split(' ').where((s) => s.isNotEmpty).toList();
      for (var i = 0; i < points.length; i += 2) {
        if (i + 1 < points.length) {
          final x = ((double.tryParse(points[i]) ?? 0) + shiftX) * scaleX;
          final y = (double.tryParse(points[i + 1]) ?? 0) * scaleY + shiftY;
          if (i == 0) {
            path.moveTo(x, y);
          } else {
            path.lineTo(x, y);
          }
        }
      }
      path.close();
      return path;
    }

    // Draw muscle group regions from anatomy_points data
    final data = isFront ? AnatomyPoints.anteriorData : AnatomyPoints.posteriorData;
    data.forEach((group, pathsStr) {
      final paint = getPaint(group);
      for (final p in pathsStr) {
        canvas.drawPath(buildPath(p), paint);
      }
    });
  }

  @override
  bool shouldRepaint(covariant AnatomyPainter oldDelegate) {
    return oldDelegate.workedMuscles != workedMuscles ||
        oldDelegate.isFront != isFront;
  }
}
