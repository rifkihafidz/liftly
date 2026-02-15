import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'config/theme/app_theme.dart';

import 'features/home/pages/splash_page.dart';
import 'features/session/bloc/session_bloc.dart';
import 'features/plans/bloc/plan_bloc.dart';
import 'features/plans/repositories/plan_repository.dart';
import 'features/workout_log/bloc/workout_bloc.dart';
import 'features/workout_log/repositories/workout_repository.dart';
import 'features/stats/bloc/stats_bloc.dart';
import 'features/stats/bloc/stats_event.dart';

import 'package:flutter/foundation.dart';
import 'shared/widgets/error_view.dart';
import 'core/services/update_service.dart';
import 'core/services/hive_service.dart';
import 'features/home/pages/main_navigation_wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    UpdateService.startPolling();
    // Initialize Hive before runApp on Web for a seamless 1x loading experience
    await HiveService.init();
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
    if (kReleaseMode) {
      // Logic for logging to analytics/crashlytics in release
    }
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    if (kDebugMode) {
      print('Caught async error: $error');
      print(stack);
    }
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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && kIsWeb) {
      UpdateService.checkVersion();
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
        BlocProvider(create: (context) => SessionBloc()),
        BlocProvider(
          create: (context) => PlanBloc(planRepository: PlanRepository()),
        ),
        BlocProvider(
          create: (context) =>
              WorkoutBloc(workoutRepository: WorkoutRepository()),
        ),
        BlocProvider(
          create: (context) =>
              StatsBloc()..add(const StatsFetched(userId: '1')),
        ),
      ],
      child: MaterialApp(
        title: 'Liftly',
        theme: AppTheme.darkTheme,
        // Skip SplashPage on Web as it already has a native HTML splash
        home: kIsWeb ? const MainNavigationWrapper() : const SplashPage(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
