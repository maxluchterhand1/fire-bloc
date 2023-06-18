import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:evaporated_storage_example/firebase_options.dart';
import 'package:evaporated_storage_example/navigation/presentation/login_navigation.dart';
import 'package:fire_bloc/evaporated_storage/data/evaporated_repository.dart';
import 'package:fire_bloc/evaporated_storage/data/firestore_evaporated_storage.dart';
import 'package:fire_bloc/evaporated_storage/data/hive_evaporated_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final remoteStorage = FirestoreEvaporatedStorage(
    auth: FirebaseAuth.instance,
    firestore: FirebaseFirestore.instance,
  );

  final localStorage = HiveEvaporatedStorage.instance();

  EvaporatedRepository.instance = EvaporatedRepository(
    localStorage: localStorage,
    remoteStorage: remoteStorage,
  );

  await EvaporatedRepository.instance.initialize();

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
