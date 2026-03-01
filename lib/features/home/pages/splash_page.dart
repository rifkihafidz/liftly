import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import '../../../core/constants/colors.dart';
import 'main_navigation_wrapper.dart';
import '../../../core/utils/page_transitions.dart';
import '../../../core/services/hive_service.dart';
import '../../../core/utils/app_logger.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8, // Start slightly larger for smoother entry
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
      ),
    );

    // Start animation and initialization in parallel
    _controller.forward();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      AppLogger.debug('Splash', 'Starting app initialization');
      
      // Wait for both animation (min duration) and Hive init (critical data)
      // No artificial delay on web since it has a native splash
      final minDuration =
          kIsWeb ? Duration.zero : const Duration(milliseconds: 1800);

      AppLogger.debug('Splash', 'Waiting for Hive init...');
      await Future.wait([
        Future.delayed(minDuration),
        HiveService.init().timeout(
          const Duration(seconds: 15),
          onTimeout: () {
            AppLogger.error('Splash', 'Hive init timeout after 15s');
            throw TimeoutException('Hive initialization timeout');
          },
        ),
      ]);

      AppLogger.debug('Splash', 'Initialization complete, navigating...');

      if (mounted) {
        Navigator.of(context).pushReplacement(
          SimpleFadePageRoute(page: const MainNavigationWrapper()),
        );
      }
    } catch (e, stackTrace) {
      AppLogger.error('Splash', 'Initialization error', e, stackTrace);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Init error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Use pure black for perfect consistency
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Opacity(
              opacity: _opacityAnimation.value,
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: RepaintBoundary(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.accent
                                  .withValues(alpha: 0.2), // Subtle glow
                              blurRadius: 40,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.fitness_center_rounded,
                          size: 64,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        'LIFTLY',
                        style:
                            Theme.of(context).textTheme.headlineLarge?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 4,
                                ),
                      ),
                      const SizedBox(height: 48),
                      const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
