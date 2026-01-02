import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'config/theme/app_theme.dart';
import 'core/services/sqlite_service.dart';
import 'features/home/pages/home_page.dart';
import 'features/session/bloc/session_bloc.dart';
import 'features/plans/bloc/plan_bloc.dart';
import 'features/plans/repositories/plan_repository.dart';
import 'features/workout_log/bloc/workout_bloc.dart';
import 'features/workout_log/repositories/workout_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SQLiteService.initDatabase();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
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
          create: (context) => PlanBloc(
            planRepository: PlanRepository(),
          ),
        ),
        BlocProvider(
          create: (context) => WorkoutBloc(
            workoutRepository: WorkoutRepository(),
          ),
        ),
      ],
      child: MaterialApp(
        title: 'Liftly',
        theme: AppTheme.darkTheme,
        home: const HomePage(),
      ),
    );
  }
}
