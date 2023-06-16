import 'dart:async';

import 'package:evaporated_storage/core/option.dart';
import 'package:evaporated_storage/core/result.dart';

abstract interface class EvaporatedStorage {
  Future<Result<void, void>> clear();

  Future<Result<void, void>> delete(String key);

  Future<Result<Option<Map<String, dynamic>>, void>> read(String key);

  Future<Result<void, void>> write(String key, Map<String, dynamic> value);
}
