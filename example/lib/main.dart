import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:evaporated_storage/evaporated_storage/data/firestore_evaporated_storage.dart';
import 'package:evaporated_storage/fire_bloc/domain/fire_bloc.dart';
import 'package:evaporated_storage_example/firebase_options.dart';
import 'package:evaporated_storage_example/navigation/presentation/login_navigation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FireBloc.storage = FirestoreEvaporatedStorage(
    auth: FirebaseAuth.instance,
    firestore: FirebaseFirestore.instance,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hydrated Bloc Firebase Storage Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const LoginNavigation(),
    );
  }
}
