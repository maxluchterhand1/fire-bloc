import 'dart:async';

import 'package:evaporated_storage/core/option.dart';
import 'package:evaporated_storage/core/result.dart';
import 'package:evaporated_storage/evaporated_storage/domain/evaporated_storage.dart';
import 'package:hive/hive.dart';

final class HiveEvaporatedStorage implements EvaporatedStorage {
  HiveEvaporatedStorage();

  static const _boxName = 'hive_evaporated_storage';

  final _box = Hive.box<Map<String, dynamic>>(_boxName);

  @override
  Future<Result<void, void>> clear() async {
    try {
      await _box.clear();
      return Success.empty();
    } catch (_) {
      return const Failure();
    }
  }

  @override
  Future<Result<void, void>> delete(String key) async {
    try {
      await _box.delete(key);
      return Success.empty();
    } catch (_) {
      return const Failure();
    }
  }

  @override
  Future<Result<Option<Map<String, dynamic>>, void>> read(String key) async {
    try {
      final result = _box.get(key);
      if (result == null) return const Success(None());
      return Success(Some(result));
    } catch (_) {
      return const Failure();
    }
  }

  @override
  Future<Result<void, void>> write(
    String key,
    Map<String, dynamic> value,
  ) async {
    try {
      await _box.put(key, value);
      return Success.empty();
    } catch (_) {
      return const Failure();
    }
  }
}
