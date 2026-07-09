import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:liftly/ui/core/config/theme/app_theme.dart';

import 'package:liftly/ui/features/home/views/splash_page.dart';
import 'package:liftly/ui/features/session/bloc/session_bloc.dart';
import 'package:liftly/ui/features/plans/bloc/plan_bloc.dart';
import 'package:liftly/data/repositories/plan_repository.dart';
import 'package:liftly/ui/features/workout_log/bloc/workout_bloc.dart';
import 'package:liftly/data/repositories/workout_repository.dart';
import 'package:liftly/ui/features/stats/bloc/stats_bloc.dart';
import 'package:liftly/ui/features/stats/bloc/stats_event.dart';

import 'package:flutter/foundation.dart';
import 'package:liftly/ui/core/shared/widgets/error_view.dart';
import 'package:liftly/data/services/core/update_service.dart';
import 'package:liftly/data/services/core/hive_service.dart';
import 'package:liftly/data/services/core/backup_service.dart';
import 'package:liftly/ui/features/home/views/main_navigation_wrapper.dart';
import 'package:liftly/core/utils/app_logger.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    UpdateService.startPolling();
    // Initialize Hive before runApp on Web for a seamless 1x loading experience
    await HiveService.init();
    // Initialize BackupService early (non-blocking)
    unawaited(BackupService().init());
  }

  if (!kIsWeb) {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  // Custom Error UI for Framework errors
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return GlobalErrorView(details: details);
  };

  // Handle errors not caught by Flutter framework
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    AppLogger.error('AsyncError', 'Caught async error', error, stack);
    return true;
  };

  runApp(const Liftly());
}

class Liftly extends StatefulWidget {
  const Liftly({super.key});

  @override
  State<Liftly> createState() => _LiftlyState();
}

class _LiftlyState extends State<Liftly> with WidgetsBindingObserver {
  late final WorkoutRepository _workoutRepository = WorkoutRepository();
  late final PlanRepository _planRepository = PlanRepository();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (kIsWeb) {
        UpdateService.checkVersion();
      }
      // Force a UI rebuild to recover from WebGL context loss
      // which often causes a blank screen on Android Chrome after tab switching.
      setState(() {});
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) =>
              SessionBloc(workoutRepository: _workoutRepository),
        ),
        BlocProvider(
          create: (context) => PlanBloc(planRepository: _planRepository),
        ),
        BlocProvider(
          create: (context) =>
              WorkoutBloc(workoutRepository: _workoutRepository),
        ),
        BlocProvider(
          create: (context) => StatsBloc(workoutRepository: _workoutRepository)
            ..add(const StatsFetched()),
        ),
      ],
      child: MaterialApp(
        title: 'Liftly',
        theme: AppTheme.darkTheme,
        // Skip SplashPage on Web as it already has a native HTML splash
        home: kIsWeb ? const MainNavigationWrapper() : const SplashPage(),
        debugShowCheckedModeBanner: false,
        builder: kIsWeb
            ? (context, child) {
                if (child == null) return const SizedBox.shrink();
                return Container(
                  color: Colors.black,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 480),
                      child: child,
                    ),
                  ),
                );
              }
            : null,
      ),
    );
  }
}
