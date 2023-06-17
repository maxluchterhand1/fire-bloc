import 'dart:async';

import 'package:collection/collection.dart';
import 'package:evaporated_storage/core/option.dart';
import 'package:evaporated_storage/core/result.dart';
import 'package:evaporated_storage/evaporated_storage/domain/evaporated_storage.dart';
import 'package:evaporated_storage/evaporated_storage/domain/timeout_wrapper.dart';

sealed class _EvaporatedRepositoryPendingAction {}

class _EvaporatedRepositoryPendingVoidAction
    implements _EvaporatedRepositoryPendingAction {
  _EvaporatedRepositoryPendingVoidAction({
    required this.action,
  }) : completer = Completer();

  final Future<Result<void, void>> Function() action;
  final Completer<Result<void, void>> completer;
}

class _EvaporatedRepositoryPendingReadAction
    implements _EvaporatedRepositoryPendingAction {
  _EvaporatedRepositoryPendingReadAction({
    required this.action,
  }) : completer = Completer();

  final Future<Result<Option<Map<String, dynamic>>, void>> Function() action;
  final Completer<Result<Option<Map<String, dynamic>>, void>> completer;
}

enum _EvaporatedRepositoryStatus {
  uninitialized('uninitialized'),
  pending('pending'),
  allGood('allGood'),
  syncRequired('syncRequired');

  const _EvaporatedRepositoryStatus(this.stringValue);

  final String stringValue;
}

class EvaporatedRepository implements EvaporatedStorage {
  EvaporatedRepository({
    required EvaporatedStorage localStorage,
    required EvaporatedStorage remoteStorage,
  })  : _localStorage = localStorage,
        _remoteStorage = EvaporatedStorageTimeoutWrapper(
          remoteStorage,
          timeout: _remoteTimeout,
        );

  static const _evaporatedRepositoryLocalStorageKey =
      'f3ecd437-7a59-41c4-af67-cfac536b77b9';

  static const _evaporatedRepositoryStatusKey = 'status';

  static const _remoteTimeout = Duration(seconds: 7);

  static EvaporatedRepository? _instance;

  static EvaporatedRepository get instance {
    if (_instance == null) throw Exception();
    return _instance!;
  }

  final EvaporatedStorage _localStorage;

  final EvaporatedStorage _remoteStorage;

  final _pending = <_EvaporatedRepositoryPendingAction>[];

  _EvaporatedRepositoryStatus _status =
      _EvaporatedRepositoryStatus.uninitialized;

  @override
  Future<void> initialize() async {
    _instance ??= this;
    await _localStorage.initialize();
    try {
      await _remoteStorage.initialize();
    } on TimeoutException catch (_) {
      await _resolveTo(_EvaporatedRepositoryStatus.syncRequired);
      return;
    }

    final repoData =
        await _localStorage.read(_evaporatedRepositoryLocalStorageKey);

    switch (repoData) {
      case Success(value: final value):
        switch (value) {
          case Some(value: final value):
            final statusString = value[_evaporatedRepositoryStatusKey];
            if (statusString is! String) throw Exception();

            var status = _EvaporatedRepositoryStatus.values
                .firstWhereOrNull((e) => e.stringValue == statusString);
            if (status == null) throw Exception();

            if (status case _EvaporatedRepositoryStatus.syncRequired) {
              status = switch (await _synchronize()) {
                Success() => _EvaporatedRepositoryStatus.allGood,
                Failure() => _EvaporatedRepositoryStatus.syncRequired,
              };
            }
            await _resolveTo(status);
          case None():
            await _resolveTo(_EvaporatedRepositoryStatus.allGood);
        }
      case Failure():
        throw Exception();
    }
  }

  Future<void> _resolveTo(_EvaporatedRepositoryStatus status) async {
    await _resolvePending();
    switch (await _saveStatusToLocal(status)) {
      case Failure():
        throw Exception();
      case Success():
        _status = status;
    }
  }

  Future<void> _resolvePending() async {
    for (var i = 0; i < _pending.length; i++) {
      switch (_pending[i]) {
        case _EvaporatedRepositoryPendingReadAction(
            action: final action,
            completer: final completer,
          ):
          completer.complete(await action());
        case _EvaporatedRepositoryPendingVoidAction(
            action: final action,
            completer: final completer,
          ):
          completer.complete(await action());
      }
    }
  }

  Future<Result<void, void>> _synchronize() async {
    switch (await keys()) {
      case Success(value: final keys):
        for (final key in keys) {
          switch (await _localStorage.read(key)) {
            case Success(value: final value):
              switch (value) {
                case Some(value: final json):
                  switch (await _remoteStorage.write(key, json)) {
                    case Success():
                      continue;
                    case Failure():
                      return const Failure();
                  }
                case None():
                  assert(false);
                  return const Failure();
              }

            case Failure():
              assert(false);
              return const Failure();
          }
        }

      case Failure():
        assert(false);
        return const Failure();
    }

    return Success.empty();
  }

  Future<Result<void, void>> _saveStatusToLocal(
    _EvaporatedRepositoryStatus status,
  ) =>
      _localStorage.write(
        _evaporatedRepositoryLocalStorageKey,
        {_evaporatedRepositoryStatusKey: status.stringValue},
      );

  @override
  Future<Result<void, void>> clear() async {
    switch (_status) {
      case _EvaporatedRepositoryStatus.uninitialized:
        return const Failure();
      case _EvaporatedRepositoryStatus.pending:
        _pending.add(_EvaporatedRepositoryPendingVoidAction(action: clear));
        return (_pending.last as _EvaporatedRepositoryPendingVoidAction)
            .completer
            .future;
      case _EvaporatedRepositoryStatus.syncRequired:
        return _localStorage.clear();
      case _EvaporatedRepositoryStatus.allGood:
        switch (await _remoteStorage.clear()) {
          case Failure():
            _status = _EvaporatedRepositoryStatus.syncRequired;
          case Success():
            break;
        }
        return _localStorage.clear();
    }
  }

  @override
  Future<Result<void, void>> delete(String key) async {
    switch (_status) {
      case _EvaporatedRepositoryStatus.uninitialized:
        return const Failure();
      case _EvaporatedRepositoryStatus.pending:
        _pending.add(
          _EvaporatedRepositoryPendingVoidAction(
            action: () => delete(key),
          ),
        );
        return (_pending.last as _EvaporatedRepositoryPendingVoidAction)
            .completer
            .future;
      case _EvaporatedRepositoryStatus.syncRequired:
        return _localStorage.delete(key);
      case _EvaporatedRepositoryStatus.allGood:
        switch (await _remoteStorage.delete(key)) {
          case Failure():
            _status = _EvaporatedRepositoryStatus.syncRequired;
          case Success():
            break;
        }
        return _localStorage.delete(key);
    }
  }

  @override
  Future<Result<Option<Map<String, dynamic>>, void>> read(String key) async {
    switch (_status) {
      case _EvaporatedRepositoryStatus.uninitialized:
        return const Failure();
      case _EvaporatedRepositoryStatus.pending:
        _pending.add(
          _EvaporatedRepositoryPendingReadAction(
            action: () => read(key),
          ),
        );
        return (_pending.last as _EvaporatedRepositoryPendingReadAction)
            .completer
            .future;
      case _EvaporatedRepositoryStatus.syncRequired:
        return _localStorage.read(key);
      case _EvaporatedRepositoryStatus.allGood:
        switch (await _remoteStorage.read(key)) {
          case Failure():
            _status = _EvaporatedRepositoryStatus.syncRequired;
            return _localStorage.read(key);
          case Success(value: final value):
            switch (value) {
              case Some(value: final value):
                switch (await _localStorage.write(key, value)) {
                  case Success():
                    return Success(Some(value));
                  case Failure():
                    return const Failure();
                }
              case None():
                switch (await _localStorage.delete(key)) {
                  case Success():
                    return const Success(None());
                  case Failure():
                    return const Failure();
                }
            }
        }
    }
  }

  @override
  Future<Result<void, void>> write(
    String key,
    Map<String, dynamic> value,
  ) async {
    switch (_status) {
      case _EvaporatedRepositoryStatus.uninitialized:
        return const Failure();
      case _EvaporatedRepositoryStatus.pending:
        _pending.add(
          _EvaporatedRepositoryPendingVoidAction(
            action: () => write(key, value),
          ),
        );
        return (_pending.last as _EvaporatedRepositoryPendingVoidAction)
            .completer
            .future;
      case _EvaporatedRepositoryStatus.syncRequired:
        return _localStorage.write(key, value);
      case _EvaporatedRepositoryStatus.allGood:
        switch (await _remoteStorage.write(key, value)) {
          case Failure():
            switch (await _localStorage.write(key, value)) {
              case Failure():
                return const Failure();
              case Success():
                switch (await _saveStatusToLocal(
                  _EvaporatedRepositoryStatus.syncRequired,
                )) {
                  case Success():
                    _status = _EvaporatedRepositoryStatus.syncRequired;
                    return Success.empty();
                  case Failure():
                    switch (await _localStorage.delete(key)) {
                      case Success(): // success only in undoing the write to local
                        return const Failure(); // the write is still a failure
                      case Failure():
                        throw Exception(); // at this point the relation between remote and local is corrupted
                    }
                }
            }
          case Success():
            switch (await _localStorage.write(key, value)) {
              case Success():
                return Success.empty();
              case Failure():
                switch (await _remoteStorage.delete(key)) {
                  case Success(): // success only in undoing the write to remote
                    return const Failure(); // the write is still a failure
                  case Failure():
                    throw Exception(); // at this point the relation between remote and local is corrupted
                }
            }
        }
    }
  }

  @override
  Future<Result<List<String>, void>> keys() => _localStorage.keys();
}
