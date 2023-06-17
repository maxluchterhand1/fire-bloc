import 'dart:async';

import 'package:fire_bloc/core/option.dart';
import 'package:fire_bloc/core/result.dart';
import 'package:fire_bloc/evaporated_storage/domain/evaporated_storage.dart';

class EvaporatedStorageTimeoutWrapper implements EvaporatedStorage {
  EvaporatedStorageTimeoutWrapper(
    this.evaporatedStorage, {
    required this.timeout,
  });

  final EvaporatedStorage evaporatedStorage;

  final Duration timeout;

  @override
  Future<Result<void, void>> clear() async {
    try {
      return await evaporatedStorage.clear().timeout(timeout);
    } on TimeoutException catch (_) {
      return const Failure();
    }
  }

  @override
  Future<Result<void, void>> delete(String key) async {
    try {
      return await evaporatedStorage.delete(key).timeout(timeout);
    } on TimeoutException catch (_) {
      return const Failure();
    }
  }

  @override
  Future<void> initialize() => evaporatedStorage.initialize().timeout(timeout);

  @override
  Future<Result<List<String>, void>> keys() async {
    try {
      return await evaporatedStorage.keys().timeout(timeout);
    } on TimeoutException catch (_) {
      return const Failure();
    }
  }

  @override
  Future<Result<Option<Map<String, dynamic>>, void>> read(String key) async {
    try {
      return await evaporatedStorage.read(key).timeout(timeout);
    } on TimeoutException catch (_) {
      return const Failure();
    }
  }

  @override
  Future<Result<void, void>> write(
    String key,
    Map<String, dynamic> value,
  ) async {
    try {
      return await evaporatedStorage.write(key, value).timeout(timeout);
    } on TimeoutException catch (_) {
      return const Failure();
    }
  }
}
