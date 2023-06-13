import 'package:hydrated_bloc/hydrated_bloc.dart' as hydrated_bloc;
import 'package:hydrated_bloc_firebase_storage/storage/data/firebase_storage_impl.dart';

final class FirebaseStorage {
  FirebaseStorage._();

  static hydrated_bloc.Storage create() {
    return StorageImpl();
  }
}
