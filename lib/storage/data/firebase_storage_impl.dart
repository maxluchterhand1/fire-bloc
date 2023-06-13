import 'package:hydrated_bloc/hydrated_bloc.dart' as hydrated_bloc;

final class StorageImpl implements hydrated_bloc.Storage {
  @override
  Future<void> clear() {
    throw UnimplementedError();
  }

  @override
  Future<void> close() {
    throw UnimplementedError();
  }

  @override
  Future<void> delete(String key) {
    throw UnimplementedError();
  }

  @override
  dynamic read(String key) {
    throw UnimplementedError();
  }

  @override
  Future<void> write(String key, dynamic value) {
    throw UnimplementedError();
  }

}