import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:evaporated_storage/evaporated_storage/domain/evaporated_storage.dart';

part 'fire_emitter_adapter.dart';

typedef FireEventHandler<Event, State> = FutureOr<void> Function(
  Event event,
  Emitter<State> fireEmit,
);

sealed class FireState<T> {}

class FireStateLoaded<T> implements FireState<T> {
  FireStateLoaded(this.value);

  final T value;
}

class FireStateLoading<T> implements FireState<T> {}

abstract class FireBloc<Event, State> extends Bloc<Event, FireState<State>>
    with FireMixin<State> {
  FireBloc(super.state) {
    _incinerate();
  }

  static EvaporatedStorage? _storage;

  static set storage(EvaporatedStorage? storage) => _storage = storage;

  static EvaporatedStorage get storage {
    if (_storage == null) throw const StorageNotFound();
    return _storage!;
  }

  void fireOn<E extends Event>(
    FireEventHandler<E, State> handler, {
    EventTransformer<E>? transformer,
  }) =>
      on(
        (event, emit) => handler(event, _FireEmitterAdapter(emit)),
        transformer: transformer,
      );
}

abstract class FireCubit<State> extends Cubit<FireState<State>>
    with FireMixin<State> {
  FireCubit(super.state) {
    _incinerate();
  }

  void fireEmit(State state) => emit(FireStateLoaded(state));
}

mixin FireMixin<State> on BlocBase<FireState<State>> {
  bool _incinerated = false;

  FireState<State>? _state;

  Map<String, dynamic>? _stateJson;

  Future<void> _incinerate() async {
    final storage = FireBloc.storage;
    try {
      _stateJson = await storage.read(storageToken);
    } catch (error, stackTrace) {
      onError(error, stackTrace);
    }
    _incinerated = true;
    emit(state);
    try {
      final stateJson = _toJson(state);
      if (stateJson != null) {
        await storage.write(storageToken, stateJson);
      }
    } catch (error, stackTrace) {
      onError(error, stackTrace);
      if (error is StorageNotFound) rethrow;
    }
  }

  @override
  FireState<State> get state {
    if (!_incinerated) return FireStateLoading<State>();

    if (_state != null) return _state!;
    try {
      if (_stateJson == null) {
        _state = super.state;
        return super.state;
      }
      final cachedState = _fromJson(_stateJson);
      if (cachedState == null) {
        _state = super.state;
        return super.state;
      }
      _state = cachedState;
      return cachedState;
    } catch (error, stackTrace) {
      onError(error, stackTrace);
      _state = super.state;
      return super.state;
    }
  }

  @override
  void onChange(Change<FireState<State>> change) {
    super.onChange(change);
    final storage = FireBloc.storage;
    final state = change.nextState;
    try {
      final stateJson = _toJson(state);
      if (stateJson != null) {
        storage.write(storageToken, stateJson).then((_) {}, onError: onError);
      }
    } catch (error, stackTrace) {
      onError(error, stackTrace);
      rethrow;
    }
    _state = state;
  }

  FireStateLoaded<State>? _fromJson(dynamic json) {
    final dynamic traversedJson = _traverseRead(json);
    final castJson = _cast<Map<String, dynamic>>(traversedJson);
    final innerState = fromJson(castJson ?? <String, dynamic>{});
    return innerState == null ? null : FireStateLoaded(innerState);
  }

  Map<String, dynamic>? _toJson(FireState<State> state) {
    switch (state) {
      case FireStateLoaded():
        return _cast<Map<String, dynamic>>(
          _traverseWrite(toJson(state.value)).value,
        );
      case FireStateLoading():
        return null;
    }
  }

  dynamic _traverseRead(dynamic value) {
    if (value is Map) {
      return value.map<String, dynamic>((dynamic key, dynamic value) {
        return MapEntry<String, dynamic>(
          _cast<String>(key) ?? '',
          _traverseRead(value),
        );
      });
    }
    if (value is List) {
      for (var i = 0; i < value.length; i++) {
        value[i] = _traverseRead(value[i]);
      }
    }
    return value;
  }

  T? _cast<T>(dynamic x) => x is T ? x : null;

  _Traversed _traverseWrite(Object? value) {
    final dynamic traversedAtomicJson = _traverseAtomicJson(value);
    if (traversedAtomicJson is! NIL) {
      return _Traversed.atomic(traversedAtomicJson);
    }
    final dynamic traversedComplexJson = _traverseComplexJson(value);
    if (traversedComplexJson is! NIL) {
      return _Traversed.complex(traversedComplexJson);
    }
    try {
      _checkCycle(value);
      final dynamic customJson = _toEncodable(value);
      final dynamic traversedCustomJson = _traverseJson(customJson);
      if (traversedCustomJson is NIL) {
        throw FireUnsupportedError(value);
      }
      _removeSeen(value);
      return _Traversed.complex(traversedCustomJson);
    } on FireCyclicError catch (e) {
      throw FireUnsupportedError(value, cause: e);
    } on FireUnsupportedError {
      rethrow; // do not stack `FireUnsupportedError`
    } catch (e) {
      throw FireUnsupportedError(value, cause: e);
    }
  }

  dynamic _traverseAtomicJson(dynamic object) {
    if (object is num) {
      if (!object.isFinite) return const NIL();
      return object;
    } else if (identical(object, true)) {
      return true;
    } else if (identical(object, false)) {
      return false;
    } else if (object == null) {
      return null;
    } else if (object is String) {
      return object;
    }
    return const NIL();
  }

  dynamic _traverseComplexJson(dynamic object) {
    if (object is List) {
      if (object.isEmpty) return object;
      _checkCycle(object);
      List<dynamic>? list;
      for (var i = 0; i < object.length; i++) {
        final traversed = _traverseWrite(object[i]);
        list ??= traversed.outcome == _Outcome.atomic
            ? object.sublist(0)
            : (<dynamic>[]..length = object.length);
        list[i] = traversed.value;
      }
      _removeSeen(object);
      return list;
    } else if (object is Map) {
      _checkCycle(object);
      final map = <String, dynamic>{};
      object.forEach((dynamic key, dynamic value) {
        final castKey = _cast<String>(key);
        if (castKey != null) {
          map[castKey] = _traverseWrite(value).value;
        }
      });
      _removeSeen(object);
      return map;
    }
    return const NIL();
  }

  dynamic _traverseJson(dynamic object) {
    final dynamic traversedAtomicJson = _traverseAtomicJson(object);
    return traversedAtomicJson is! NIL
        ? traversedAtomicJson
        : _traverseComplexJson(object);
  }

  // ignore: avoid_dynamic_calls
  dynamic _toEncodable(dynamic object) => object.toJson();

  final _seen = <dynamic>[];

  void _checkCycle(Object? object) {
    for (var i = 0; i < _seen.length; i++) {
      if (identical(object, _seen[i])) {
        throw FireCyclicError(object);
      }
    }
    _seen.add(object);
  }

  void _removeSeen(dynamic object) {
    assert(_seen.isNotEmpty, 'seen must not be empty');
    assert(identical(_seen.last, object), 'last seen object must be identical');
    _seen.removeLast();
  }

  String get id => '';

  String get storagePrefix => runtimeType.toString();

  String get storageToken => '$storagePrefix$id';

  Future<void> clear() => FireBloc.storage.delete(storageToken);

  State? fromJson(Map<String, dynamic> json);

  Map<String, dynamic>? toJson(State state);
}

class FireCyclicError extends FireUnsupportedError {
  FireCyclicError(Object? object) : super(object);

  @override
  String toString() => 'Cyclic error while state traversing';
}

class StorageNotFound implements Exception {
  const StorageNotFound();

  @override
  String toString() {
    return 'Storage was accessed before it was initialized.\n'
        'Please ensure that storage has been initialized.\n\n'
        'For example:\n\n'
        'FireBloc.storage = await FireStorage.build();';
  }
}

class FireUnsupportedError extends Error {
  FireUnsupportedError(
    this.unsupportedObject, {
    this.cause,
  });

  final Object? unsupportedObject;

  final Object? cause;

  @override
  String toString() {
    final safeString = Error.safeToString(unsupportedObject);
    final prefix = cause != null
        ? 'Converting object to an encodable object failed:'
        : 'Converting object did not return an encodable object:';
    return '$prefix $safeString';
  }
}

class NIL {
  const NIL();
}

enum _Outcome { atomic, complex }

class _Traversed {
  _Traversed._({required this.outcome, required this.value});

  _Traversed.atomic(dynamic value)
      : this._(outcome: _Outcome.atomic, value: value);

  _Traversed.complex(dynamic value)
      : this._(outcome: _Outcome.complex, value: value);
  final _Outcome outcome;
  final dynamic value;
}
