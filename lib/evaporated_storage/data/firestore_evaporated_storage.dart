import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart' as fb_fs;
import 'package:collection/collection.dart';
import 'package:evaporated_storage/core/option.dart';
import 'package:evaporated_storage/evaporated_storage/domain/evaporated_storage.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;

final class FirestoreEvaporatedStorage implements EvaporatedStorage {
  const FirestoreEvaporatedStorage({
    required fb_auth.FirebaseAuth auth,
    required fb_fs.FirebaseFirestore firestore,
  })  : _auth = auth,
        _firestore = firestore;

  final fb_auth.FirebaseAuth _auth;

  final fb_fs.FirebaseFirestore _firestore;

  @override
  Future<void> clear() async {
    switch (_userCollectionRef) {
      case Some(value: final ref):
        final snapshot = await ref.get();
        final deletions = snapshot.docs.map((e) => ref.doc(e.id).delete());
        await Future.wait(deletions);
      case None():
    }
  }

  Option<fb_fs.CollectionReference<Map<String, dynamic>>>
      get _userCollectionRef {
    if (_auth.currentUser == null) return const None();
    final userId = _auth.currentUser!.uid;
    return Some(_firestore.collection(userId));
  }

  @override
  Future<void> delete(String key) async {
    switch (_userCollectionRef) {
      case Some(value: final ref):
        await ref.doc(key).delete();
      case None():
    }
  }

  @override
  Future<Map<String, dynamic>?> read(String key) =>
      switch (_userCollectionRef) {
        Some(value: final ref) => () async {
            final userCollection = await ref.get();
            final blocDocument = userCollection.docs
                .firstWhereOrNull((element) => element.id == key);
            return blocDocument?.data();
          }(),
        None() => Future.value(),
      };

  @override
  Future<void> write(String key, Map<String, dynamic> value) async {
    if (_auth.currentUser == null) return;
    final userId = _auth.currentUser!.uid;
    final userCollectionRef = _firestore.collection(userId);
    await userCollectionRef.doc(key).set(value);
  }
}
