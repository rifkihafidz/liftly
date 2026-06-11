import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../core/utils/muscle_detector.dart';
import '../../../core/constants/anatomy_points.dart';

class MuscleHeatmap extends StatelessWidget {
  final Map<MuscleGroup, int> workedMuscles;
  final Color? textColor;

  const MuscleHeatmap({
    super.key,
    required this.workedMuscles,
    this.textColor,
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
            spacing: 20,
            runSpacing: 8,
            children: [
              _buildLegendItem(const Color(0xFFFFD600), '1-4 sets'),
              _buildLegendItem(const Color(0xFFFF7A00), '5-8 sets'),
              _buildLegendItem(const Color(0xFFE53935), '>8 sets'),
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
                              textColor: textColor,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'FRONT',
                        style: TextStyle(
                          color: (textColor ?? AppColors.textSecondary)
                              .withValues(alpha: 0.6),
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
                  color: (textColor ?? AppColors.borderDark).withValues(alpha: 0.25),
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
                              textColor: textColor,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'BACK',
                        style: TextStyle(
                          color: (textColor ?? AppColors.textSecondary)
                              .withValues(alpha: 0.6),
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
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.5),
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: textColor ?? AppColors.textSecondary,
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
  final Color? textColor;

  const AnatomyPainter({
    required this.workedMuscles,
    required this.isFront,
    this.textColor,
  });

  static const double _vW = 100.0;

  static const Color _colorLow = Color(0xFFFFD600);
  static const Color _colorMid = Color(0xFFFF7A00);
  static const Color _colorHigh = Color(0xFFE53935);

  Color _getIntensityColor(int count) {
    if (count <= 4) return _colorLow;
    if (count <= 8) return _colorMid;
    return _colorHigh;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final scaleX = size.width / _vW;
    
    final double pathMinY = 0.0;
    final double pathMaxY = isFront ? 212.0 : 222.0;
    final double pathHeight = pathMaxY - pathMinY;

    final double targetHeight = size.height * 0.95;
    final double scaleY = targetHeight / pathHeight;
    final double shiftY = (size.height - targetHeight) / 2 - (pathMinY * scaleY);

    final shiftX = 0.0;

    // Use a lighter, more solid grey for the base so the human shape stands out
    // and looks exactly like the premium reference image.
    final Color baseColor = const Color(0xFF555555);

    final baseFill = Paint()
      ..color = baseColor
      ..style = PaintingStyle.fill;

    // "Negative Space" separator using the background color (AppColors.darkBg / cardBg)
    // This creates clean gaps between all polygons, rounding off their sharp edges.
    final separatorStroke = Paint()
      ..color = AppColors.cardBg // Matches the background of the bottom sheet/card
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5 * scaleX
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

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

    final data = isFront ? AnatomyPoints.anteriorData : AnatomyPoints.posteriorData;

    // We do one single loop to draw each shape (fill first, then gap separator on top).
    // This perfectly isolates each muscle segment without overlap artifacts.
    data.forEach((group, pathsStr) {
      final isUnknown = group == MuscleGroup.unknown;
      final isActive = !isUnknown && workedMuscles.containsKey(group);

      final Paint fillPaint;
      if (isActive) {
        final count = workedMuscles[group]!;
        fillPaint = Paint()
          ..color = _getIntensityColor(count)
          ..style = PaintingStyle.fill;
      } else {
        fillPaint = baseFill;
      }

      for (final p in pathsStr) {
        final path = buildPath(p);
        // Draw the muscle color
        canvas.drawPath(path, fillPaint);
        // Draw the background-colored separator on top to carve out gaps
        canvas.drawPath(path, separatorStroke);
      }
    });
  }

  @override
  bool shouldRepaint(covariant AnatomyPainter oldDelegate) {
    return oldDelegate.workedMuscles != workedMuscles ||
        oldDelegate.isFront != isFront ||
        oldDelegate.textColor != textColor;
  }
}
