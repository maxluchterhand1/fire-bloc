import 'package:evaporated_storage/evaporated_storage.dart';
import 'package:evaporated_storage_example/counter/state/counter_cubit.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CounterPage extends StatefulWidget {
  const CounterPage({super.key});

  @override
  State<CounterPage> createState() => _CounterPageState();
}

class _CounterPageState extends State<CounterPage> {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CounterCubit(),
      child: Builder(
        builder: (context) {
          return Scaffold(
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(height: 100),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        BlocBuilder<CounterCubit, Option<int>>(
                          builder: (context, state) {
                            switch (state) {
                              case Some(value: final value):
                                return Text('Count: $value');
                              case None():
                                return const CircularProgressIndicator();
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () =>
                              context.read<CounterCubit>().increment(),
                          child: const Text('Increment'),
                        ),
                      ],
                    ),
                    SizedBox(
                      height: 100,
                      child: Center(
                        child: ElevatedButton(
                          onPressed: FirebaseAuth.instance.signOut,
                          child: const Text('Sign out'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
