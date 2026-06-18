import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../core/utils/muscle_detector.dart';
import '../../../core/constants/anatomy_points.dart';

class RecoveryHeatmap extends StatelessWidget {
  final Map<MuscleGroup, double> recoveryLevels;
  final Color? textColor;
  final double height;

  const RecoveryHeatmap({
    super.key,
    required this.recoveryLevels,
    this.textColor,
    this.height = 240,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.cardBg.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(100),
              border: Border.all(
                color: AppColors.borderDark.withValues(alpha: 0.5),
              ),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLegendItem(const Color(0xFFE53935), 'Fatigued'), // Red
                  const SizedBox(width: 16),
                  _buildLegendItem(const Color(0xFFFFB300), 'Recovering'), // Amber
                  const SizedBox(width: 16),
                  _buildLegendItem(const Color(0xFF43A047), 'Fresh'), // Green
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: height,
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
                            painter: RecoveryAnatomyPainter(
                              recoveryLevels: recoveryLevels,
                              isFront: true,
                              textColor: textColor,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.cardBg.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.borderDark.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          'FRONT',
                          style: TextStyle(
                            color: (textColor ?? AppColors.textPrimary).withValues(alpha: 0.7),
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
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
                            painter: RecoveryAnatomyPainter(
                              recoveryLevels: recoveryLevels,
                              isFront: false,
                              textColor: textColor,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.cardBg.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.borderDark.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          'BACK',
                          style: TextStyle(
                            color: (textColor ?? AppColors.textPrimary).withValues(alpha: 0.7),
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2.0,
                          ),
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
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.4),
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

class RecoveryAnatomyPainter extends CustomPainter {
  final Map<MuscleGroup, double> recoveryLevels;
  final bool isFront;
  final Color? textColor;

  const RecoveryAnatomyPainter({
    required this.recoveryLevels,
    required this.isFront,
    this.textColor,
  });

  static const double _vW = 100.0;

  // Colors for interpolation
  static const Color _colorFatigued = Color(0xFFE53935); // Red (0% recovery)
  static const Color _colorRecovering = Color(0xFFFFB300); // Amber (50% recovery)
  static const Color _colorFresh = Color(0xFF43A047); // Green (100% recovery)

  Color _getRecoveryColor(double recovery) {
    if (recovery < 0.5) {
      // Interpolate between Red and Amber
      return Color.lerp(_colorFatigued, _colorRecovering, recovery * 2)!;
    } else {
      // Interpolate between Amber and Green
      return Color.lerp(_colorRecovering, _colorFresh, (recovery - 0.5) * 2)!;
    }
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

    final separatorStroke = Paint()
      ..color = AppColors.cardBg
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

    final fullSilhouette = Path();
    data.forEach((group, pathsStr) {
      for (final p in pathsStr) {
        fullSilhouette.addPath(buildPath(p), Offset.zero);
      }
    });

    final dropShadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8.0);
      
    canvas.drawPath(
      fullSilhouette.shift(Offset(0, 4.0 * scaleY)), 
      dropShadowPaint,
    );

    data.forEach((group, pathsStr) {
      final isUnknown = group == MuscleGroup.unknown;
      final recovery = recoveryLevels[group] ?? 1.0;

      final color = isUnknown ? const Color(0xFF48484A) : _getRecoveryColor(recovery);
      
      final fillPaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;
        
      final glowPaint = Paint()
        ..color = color.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0 * scaleX
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);

      for (final p in pathsStr) {
        final path = buildPath(p);
        if (!isUnknown) canvas.drawPath(path, glowPaint);
        canvas.drawPath(path, fillPaint);
        canvas.drawPath(path, separatorStroke);
      }
    });
  }

  @override
  bool shouldRepaint(covariant RecoveryAnatomyPainter oldDelegate) {
    return oldDelegate.recoveryLevels != recoveryLevels ||
        oldDelegate.isFront != isFront ||
        oldDelegate.textColor != textColor;
  }
}
