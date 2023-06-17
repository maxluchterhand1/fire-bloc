part of 'evaporated_repository_test.dart';

abstract interface class _MockEvaporatedStorage implements EvaporatedStorage {
  Map<String, Map<String, dynamic>> get storage;
}

class _MockFailingEvaporatedStorage implements _MockEvaporatedStorage {
  _MockFailingEvaporatedStorage([
    Map<String, Map<String, dynamic>>? storage,
  ]) {
    if (storage != null) this.storage.addAll(storage);
  }

  @override
  final storage = <String, Map<String, dynamic>>{};

  @override
  Future<Result<void, void>> clear() => Future.value(const Failure());

  @override
  Future<Result<void, void>> delete(String key) =>
      Future.value(const Failure());

  @override
  Future<void> initialize() => Future.value();

  @override
  Future<Result<List<String>, void>> keys() => Future.value(const Failure());

  @override
  Future<Result<Option<Map<String, dynamic>>, void>> read(String key) =>
      Future.value(const Failure());

  @override
  Future<Result<void, void>> write(String key, Map<String, dynamic> value) =>
      Future.value(const Failure());
}

class _MockSuccessfulEvaporatedStorage implements _MockEvaporatedStorage {
  _MockSuccessfulEvaporatedStorage([
    Map<String, Map<String, dynamic>>? storage,
  ]) {
    if (storage != null) this.storage.addAll(storage);
  }

  @override
  final storage = <String, Map<String, dynamic>>{};

  @override
  Future<Result<void, void>> clear() {
    storage.clear();
    return Future.value(Success.empty());
  }

  @override
  Future<Result<void, void>> delete(String key) {
    storage.remove(key);
    return Future.value(Success.empty());
  }

  @override
  Future<void> initialize() => Future.value();

  @override
  Future<Result<List<String>, void>> keys() =>
      Future.value(Success(storage.keys.toList()));

  @override
  Future<Result<Option<Map<String, dynamic>>, void>> read(String key) {
    final value = storage[key];
    if (value == null) return Future.value(const Success(None()));
    return Future.value(Success(Some(value)));
  }

  @override
  Future<Result<void, void>> write(String key, Map<String, dynamic> value) {
    storage[key] = value;
    return Future.value(Success.empty());
  }
}
