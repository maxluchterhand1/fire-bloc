import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:fire_bloc/core/option.dart';
import 'package:fire_bloc/core/result.dart';
import 'package:fire_bloc/evaporated_storage/data/evaporated_repository.dart';
import 'package:fire_bloc/evaporated_storage/domain/evaporated_storage.dart';

part 'fire_emitter_adapter.dart';

typedef FireEventHandler<Event, State> = FutureOr<void> Function(
  Event event,
  Emitter<State> fireEmit,
);

abstract interface class _EvaporatedStorageProviding {
  EvaporatedStorage get storage;
}

abstract class FireBloc<Event, State> extends Bloc<Event, Option<State>>
    with FireMixin<State>
    implements _EvaporatedStorageProviding {
  FireBloc(
    super.state, {
    EvaporatedStorage? storage,
  }) : _storage = storage {
    _incinerate();
  }

  @override
  EvaporatedStorage get storage => _storage ?? EvaporatedRepository.instance;

  final EvaporatedStorage? _storage;

  void fireOn<E extends Event>(
    FireEventHandler<E, State> handler, {
    EventTransformer<E>? transformer,
  }) =>
      on(
        (event, emit) => handler(event, _FireEmitterAdapter(emit)),
        transformer: transformer,
      );
}

abstract class FireCubit<State> extends Cubit<Option<State>>
    with FireMixin<State>
    implements _EvaporatedStorageProviding {
  FireCubit(
    super.state, {
    EvaporatedStorage? storage,
  }) : _storage = storage {
    _incinerate();
  }

  @override
  EvaporatedStorage get storage => _storage ?? EvaporatedRepository.instance;

  final EvaporatedStorage? _storage;

  void fireEmit(State state) => emit(Some(state));
}

mixin FireMixin<State> on BlocBase<Option<State>>
    implements _EvaporatedStorageProviding {
  bool _incinerated = false;

  Option<State>? _state;

  Map<String, dynamic>? _stateJson;

  Future<void> _incinerate() async {
    switch (await storage.read(storageToken)) {
      case Failure():
        onError(Object(), StackTrace.current); // TODO
      case Success(value: final value):
        switch (value) {
          case Some(value: final json):
            _stateJson = json;
          case None():
            break;
        }
    }

    _incinerated = true;
    emit(state);
    try {
      switch (state) {
        case Some(value: final value):
          await storage.write(storageToken, toJson(value));
        case None():
          break;
      }
    } catch (error, stackTrace) {
      onError(error, stackTrace);
      if (error is StorageNotFound) rethrow;
    }
  }

  @override
  Option<State> get state {
    if (!_incinerated) return const None();

    if (_state != null) return _state!;
    try {
      if (_stateJson == null) {
        _state = super.state;
        return super.state;
      }
      final cachedState = fromJson(_stateJson!);
      _state = cachedState;
      return cachedState;
    } catch (error, stackTrace) {
      onError(error, stackTrace);
      _state = super.state;
      return super.state;
    }
  }

  @override
  void onChange(Change<Option<State>> change) {
    super.onChange(change);
    final state = change.nextState;
    try {
      switch (state) {
        case Some(value: final value):
          storage
              .write(storageToken, toJson(value))
              .then((_) {}, onError: onError);
        case None():
          break;
      }
    } catch (error, stackTrace) {
      onError(error, stackTrace);
      rethrow;
    }
    _state = state;
  }

  String get id => '';

  String get storagePrefix => runtimeType.toString();

  String get storageToken => '$storagePrefix$id';

  Future<void> clear() => storage.delete(storageToken);

  Option<State> fromJson(Map<String, dynamic> json);

  Map<String, dynamic> toJson(State state);
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
