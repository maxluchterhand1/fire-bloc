import 'dart:async';

import 'package:fire_bloc/core/option.dart';
import 'package:fire_bloc/core/result.dart';

abstract interface class EvaporatedStorage {
  Future<void> initialize();

  Future<Result<void, void>> clear();

  Future<Result<void, void>> delete(String key);

  Future<Result<Option<Map<String, dynamic>>, void>> read(String key);

  Future<Result<void, void>> write(String key, Map<String, dynamic> value);

  Future<Result<List<String>, void>> keys();
}
