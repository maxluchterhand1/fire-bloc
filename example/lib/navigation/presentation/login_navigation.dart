import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hydrated_bloc_firebase_storage_example/counter/presentation/counter_page.dart';
import 'package:hydrated_bloc_firebase_storage_example/login/presentation/login_page.dart';
import 'package:hydrated_bloc_firebase_storage_example/navigation/state/login_navigation_cubit.dart';

class LoginNavigation extends StatelessWidget {
  const LoginNavigation({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => LoginNavigationCubit(auth: FirebaseAuth.instance),
      child: BlocBuilder<LoginNavigationCubit, LoginNavigationState>(
        builder: (context, state) => switch (state) {
          LoginNavigationStateLoggedIn() => Navigator(
              pages: const [MaterialPage(child: CounterPage())],
              onPopPage: (_, __) => false,
            ),
          LoginNavigationStateLoggedOut() => Navigator(
              pages: const [MaterialPage(child: LoginPage())],
              onPopPage: (_, __) => false,
            ),
        },
      ),
    );
  }
}
