import 'dart:async';

import 'package:fire_bloc/core/option.dart';
import 'package:fire_bloc/core/result.dart';
import 'package:fire_bloc/evaporated_storage/domain/evaporated_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';

final class HiveEvaporatedStorage implements EvaporatedStorage {
  factory HiveEvaporatedStorage.instance() =>
      _instance ??= HiveEvaporatedStorage._();

  HiveEvaporatedStorage._();

  static HiveEvaporatedStorage? _instance;

  static const _boxName = 'hive_fire_bloc';

  late final Box<Map<dynamic, dynamic>> _box;

  @override
  Future<void> initialize() async {
    await Hive.initFlutter();
    _box = await Hive.openBox(_boxName);
  }

  @override
  Future<Result<void, void>> clear() async {
    try {
      await _box.clear();
      print('Hive clear() success');
      return Success.empty();
    } catch (_) {
      print('Hive clear() failure');
      return const Failure();
    }
  }

  @override
  Future<Result<void, void>> delete(String key) async {
    try {
      await _box.delete(key);
      print('Hive delete() success');
      return Success.empty();
    } catch (_) {
      print('Hive delete() failure');
      return const Failure();
    }
  }

  @override
  Future<Result<Option<Map<String, dynamic>>, void>> read(String key) async {
    try {
      final hiveData = _box.get(key);
      if (hiveData == null) return const Success(None());
      final result = <String, dynamic>{};
      for (final MapEntry(:key, :value) in hiveData.entries) {
        if (key is String) {
          result[key] = value;
        } else {
          print('Hive read() failure');
          assert(false);
          return const Failure();
        }
      }

      print('Hive read() success');
      return Success(Some(result as Map<String, dynamic>));
    } catch (_) {
      print('Hive read() failure');
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
      print('Hive write() success');
      return Success.empty();
    } catch (_) {
      print('Hive write() failure');
      return const Failure();
    }
  }

  @override
  Future<Result<List<String>, void>> keys() async {
    try {
      final keys = _box.keys.toList();
      print('Hive keys() success');
      return Success(keys.map((e) => e.toString()).toList());
    } catch (_) {
      print('Hive keys() failure');
      return const Failure();
    }
  }
}
