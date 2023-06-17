import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart' as fs;
import 'package:collection/collection.dart';
import 'package:evaporated_storage/core/option.dart';
import 'package:evaporated_storage/core/result.dart';
import 'package:evaporated_storage/evaporated_storage/domain/evaporated_storage.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;

final class FirestoreEvaporatedStorage implements EvaporatedStorage {
  const FirestoreEvaporatedStorage({
    required auth.FirebaseAuth auth,
    required fs.FirebaseFirestore firestore,
  })  : _auth = auth,
        _firestore = firestore;

  final auth.FirebaseAuth _auth;

  final fs.FirebaseFirestore _firestore;

  @override
  Future<void> initialize() => Future.value();

  @override
  Future<Result<void, void>> clear() async {
    try {
      switch (_userCollectionRef) {
        case Some(value: final ref):
          final snapshot = await ref.get();
          final deletions = snapshot.docs.map((e) => ref.doc(e.id).delete());
          await Future.wait(deletions);
        case None():
          break;
      }
      print('Firestore clear() success');
      return Success.empty();
    } catch (_) {
      print('Firestore clear() failure');
      return const Failure();
    }
  }

  Option<fs.CollectionReference<Map<String, dynamic>>> get _userCollectionRef {
    if (_auth.currentUser == null) return const None();
    final userId = _auth.currentUser!.uid;
    return Some(_firestore.collection(userId));
  }

  @override
  Future<Result<void, void>> delete(String key) async {
    try {
      switch (_userCollectionRef) {
        case Some(value: final ref):
          await ref.doc(key).delete();
        case None():
          break;
      }
      print('Firestore delete() success');
      return Success.empty();
    } catch (_) {
      print('Firestore delete() success');
      return const Failure();
    }
  }

  @override
  Future<Result<Option<Map<String, dynamic>>, void>> read(String key) async {
    try {
      switch (_userCollectionRef) {
        case Some(value: final ref):
          final userCollection = await ref.get();
          final blocDocument = userCollection.docs
              .firstWhereOrNull((element) => element.id == key);

          print('Firestore read() success');
          if (blocDocument == null) {
            return const Success(None());
          } else {
            return Success(Some(blocDocument.data()));
          }

        case None():
          print('Firestore read() success');
          return const Success(None());
      }
    } catch (_) {
      print('Firestore read() failure');
      return const Failure();
    }
  }

  @override
  Future<Result<void, void>> write(
    String key,
    Map<String, dynamic> value,
  ) async {
    if (_auth.currentUser == null) return const Failure();
    final userId = _auth.currentUser!.uid;
    final userCollectionRef = _firestore.collection(userId);
    try {
      await userCollectionRef.doc(key).set(value);
      print('Firestore write() success');
      return Success.empty();
    } catch (_) {
      print('Firestore write() failure');
      return const Failure();
    }
  }

  @override
  Future<Result<List<String>, void>> keys() async {
    try {
      switch (_userCollectionRef) {
        case Some(value: final ref):
          final snapshot = await ref.get();
          print('Firestore keys() success');
          return Success(snapshot.docs.map((e) => e.id).toList());
        case None():
          print('Firestore keys() success');
          return const Success([]);
      }
    } catch (_) {
      print('Firestore keys() failure');
      return const Failure();
    }
  }
}
