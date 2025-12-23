import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'config/theme/app_theme.dart';
import 'features/auth/bloc/auth_bloc.dart';
import 'features/auth/bloc/auth_state.dart';
import 'features/auth/pages/login_page.dart';
import 'features/auth/repositories/auth_repository.dart';
import 'features/home/pages/home_page.dart';
import 'features/session/bloc/session_bloc.dart';
import 'features/plans/bloc/plan_bloc.dart';
import 'features/plans/repositories/plan_repository.dart';

void main() {
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
      ],
      child: MaterialApp(
        title: 'Liftly',
        theme: AppTheme.darkTheme,
        home: const AuthWrapper(),
        debugShowCheckedModeBanner: false,
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
