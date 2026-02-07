import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'config/theme/app_theme.dart';
import 'core/services/isar_service.dart';
import 'core/services/migration_service.dart';

import 'features/home/pages/splash_page.dart';
import 'features/session/bloc/session_bloc.dart';
import 'features/plans/bloc/plan_bloc.dart';
import 'features/plans/repositories/plan_repository.dart';
import 'features/workout_log/bloc/workout_bloc.dart';
import 'features/workout_log/repositories/workout_repository.dart';

import 'package:flutter/foundation.dart';
import 'shared/widgets/error_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

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

  // Initialize Isar
  await IsarService.init();

  // Run migration from SQLite if needed (Mobile/Desktop only)
  // This will check if migration is done, if not, it will read legacy SQLite data and write to Isar
  try {
    await MigrationService.migrateIfNeeded();
  } catch (e) {
    if (kDebugMode) print("Migration error: $e");
    // Continue anyway, maybe data is fresh or migration can be retried later
  }

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
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Force a rebuild to ensure the UI is painted when returning from background
      setState(() {});
    }
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
      ],
      child: MaterialApp(
        title: 'Liftly',
        theme: AppTheme.darkTheme,
        home: const SplashPage(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
