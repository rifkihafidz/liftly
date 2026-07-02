import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../core/utils/muscle_detector.dart';
import '../../../core/constants/anatomy_points.dart';

class MuscleHeatmap extends StatelessWidget {
  final Map<MuscleGroup, int> workedMuscles;
  final Color? textColor;
  final double height;

  const MuscleHeatmap({
    super.key,
    required this.workedMuscles,
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
              borderRadius: BorderRadius.circular(100), // pill shape
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
                  _buildLegendItem(const Color(0xFFFFD600), '1-4 sets'),
                  const SizedBox(width: 16),
                  _buildLegendItem(const Color(0xFFFF7A00), '5-8 sets'),
                  const SizedBox(width: 16),
                  _buildLegendItem(const Color(0xFFE53935), '>8 sets'),
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
                        child: RepaintBoundary(
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
                        child: RepaintBoundary(
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

  // Path cache keyed by "f|b:scaleX:scaleY:pathStr".
  // SVG-like path strings are parsed once per canvas size and reused on
  // every repaint (e.g. when muscle highlight colors change).
  static final Map<String, Path> _pathCache = {};

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

    // "Negative Space" separator using the background color (AppColors.darkBg / cardBg)
    // This creates clean gaps between all polygons, rounding off their sharp edges.
    final separatorStroke = Paint()
      ..color = AppColors.cardBg // Matches the background of the bottom sheet/card
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5 * scaleX
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    Path buildPath(String pathStr) {
      final cacheKey = '${isFront ? 'f' : 'b'}:${scaleX.toStringAsFixed(3)}:${scaleY.toStringAsFixed(3)}:$pathStr';
      final cached = _pathCache[cacheKey];
      if (cached != null) return cached;

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
      _pathCache[cacheKey] = path;
      return path;
    }

    final data = isFront ? AnatomyPoints.anteriorData : AnatomyPoints.posteriorData;

    // We do one single loop to draw each shape (fill first, then gap separator on top).
    // This perfectly isolates each muscle segment without overlap artifacts.
    
    // 1. Build a full silhouette for the drop shadow
    final fullSilhouette = Path();
    data.forEach((group, pathsStr) {
      for (final p in pathsStr) {
        fullSilhouette.addPath(buildPath(p), Offset.zero);
      }
    });

    // Draw Drop Shadow
    final dropShadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8.0);
      
    canvas.drawPath(
      fullSilhouette.shift(Offset(0, 4.0 * scaleY)), 
      dropShadowPaint,
    );

    // 2. Base inactive color with a subtle 3D metallic gradient
    final baseShader = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFF6E6E73), // lighter metallic grey
        Color(0xFF48484A), // mid metallic grey
        Color(0xFF2C2C2E), // dark metallic grey
      ],
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final baseFill = Paint()
      ..shader = baseShader
      ..style = PaintingStyle.fill;

    // 3. Draw Muscles
    data.forEach((group, pathsStr) {
      final isUnknown = group == MuscleGroup.unknown;
      final isActive = !isUnknown && workedMuscles.containsKey(group);

      if (isActive) {
        final count = workedMuscles[group]!;
        final intensityColor = _getIntensityColor(count);
        
        final fillPaint = Paint()
          ..color = intensityColor
          ..style = PaintingStyle.fill;
          
        final glowPaint = Paint()
          ..color = intensityColor.withValues(alpha: 0.35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0 * scaleX
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);

        for (final p in pathsStr) {
          final path = buildPath(p);
          canvas.drawPath(path, glowPaint);
          canvas.drawPath(path, fillPaint);
          canvas.drawPath(path, separatorStroke);
        }
      } else {
        for (final p in pathsStr) {
          final path = buildPath(p);
          canvas.drawPath(path, baseFill);
          canvas.drawPath(path, separatorStroke);
        }
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
