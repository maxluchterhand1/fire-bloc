import 'dart:async';

abstract interface class EvaporatedStorage {
  Future<void> clear();

  Future<void> delete(String key);

  Future<Map<String, dynamic>?> read(String key);

  Future<void> write(String key, Map<String, dynamic> value);
}
