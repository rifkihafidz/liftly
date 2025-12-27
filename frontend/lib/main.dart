import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'config/theme/app_theme.dart';
import 'core/services/hive_service.dart';
import 'features/auth/bloc/auth_bloc.dart';
import 'features/auth/bloc/auth_state.dart';
import 'features/auth/pages/login_page.dart';
import 'features/auth/repositories/auth_repository.dart';
import 'features/home/pages/home_page.dart';
import 'features/session/bloc/session_bloc.dart';
import 'features/plans/bloc/plan_bloc.dart';
import 'features/plans/repositories/plan_repository.dart';
import 'features/workout_log/bloc/workout_bloc.dart';
import 'features/workout_log/repositories/workout_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveService.initHive();
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
        BlocProvider(
          create: (context) => AuthBloc(
            authRepository: AuthRepository(),
          ),
        ),
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
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is AuthAuthenticated) {
          // Set user ID in PlanBloc
          context.read<PlanBloc>().setCurrentUserId(state.user.id);
          return const HomePage();
        }
        return const LoginPage();
      },
    );
  }
}
