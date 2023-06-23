import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:fire_bloc/core/option.dart';
import 'package:fire_bloc/evaporated_storage/domain/evaporated_storage.dart';
import 'package:fire_bloc/core/result.dart';
import 'package:meta/meta.dart';

abstract interface class EvaporatedStorageProviding {
  EvaporatedStorage get storage;
}

/// A mixin which enables automatic state persistence
/// for [FireBloc] and [FireCubit] classes.
///
/// The [incinerate] method must be invoked in the constructor body
/// when using the [FireMixin] directly.
///
/// If a mixin is not necessary, it is recommended to
/// extend [FireBloc] and [FireCubit] respectively.
///
/// ```dart
/// class CounterCubit extends Cubit<Option<int>> with FireMixin<int> {
///   CounterCubit() : super(const Some(0)) {
///     incinerate();
///   }
///
///   @override
///   EvaporatedStorage get storage => EvaporatedRepository.instance;
///
///   @override
///   Option<int> fromJson(Map<String, dynamic> json) {
///     ...
///   }
///
///
///   @override
///   Map<String, dynamic> toJson(int state) {
///     ...
///   }
///   ...
/// }
/// ```
///
/// See also:
///
/// * [FireBloc] to enable automatic state persistence/restoration with [Bloc]
/// * [FireCubit] to enable automatic state persistence/restoration with [Cubit]
///
mixin FireMixin<State> on BlocBase<Option<State>>
    implements EvaporatedStorageProviding {
  bool _incinerated = false;

  Option<State>? _state;

  Map<String, dynamic>? _stateJson;

  /// Populates the internal state storage with the latest state.
  /// This should be called when using the [FireMixin]
  /// directly within the constructor body.
  ///
  ///
  /// ```dart
  /// class CounterCubit extends Cubit<Option<int>> with FireMixin<int> {
  ///   CounterCubit() : super(const Some(0)) {
  ///     incinerate();
  ///     ...
  ///   }
  ///   ...
  /// }
  /// ```
  Future<void> incinerate() async {
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

  /// [id] is used to uniquely identify multiple instances
  /// of the same [FireBloc] type.
  /// In most cases it is not necessary;
  /// however, if you wish to intentionally have multiple instances
  /// of the same [FireBloc], then you must override [id]
  /// and return a unique identifier for each [FireBloc] instance
  /// in order to keep the caches independent of each other.
  String get id => '';

  /// Storage prefix which can be overridden to provide a custom
  /// storage namespace.
  /// Defaults to [runtimeType] but should be overridden in cases
  /// where stored data should be resilient to obfuscation or persist
  /// between debug/release builds.
  String get storagePrefix => runtimeType.toString();

  /// `storageToken` is used as registration token for evaporated storage.
  /// Composed of [storagePrefix] and [id].
  @nonVirtual
  String get storageToken => '$storagePrefix$id';

  /// [clear] is used to wipe the stored state of a [FireBloc] from the local
  /// and the remote storage. Calling [clear] will delete the stored state of
  /// the bloc but will not modify the current state of the bloc.
  Future<void> clear() => storage.delete(storageToken);

  /// Responsible for converting the `Map<String, dynamic>` representation
  /// of the bloc state into a concrete instance of the bloc state.
  Option<State> fromJson(Map<String, dynamic> json);

  /// Responsible for converting a concrete instance of the bloc state
  /// into the the `Map<String, dynamic>` representation.
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
