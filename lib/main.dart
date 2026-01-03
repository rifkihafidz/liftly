import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'config/theme/app_theme.dart';
import 'core/services/sqlite_service.dart';

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

  await SQLiteService.initDatabase();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const Liftly());
}

class Liftly extends StatelessWidget {
  const Liftly({super.key});

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
