import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:fire_bloc/core/option.dart';
import 'package:fire_bloc/evaporated_storage/data/evaporated_repository.dart';
import 'package:fire_bloc/evaporated_storage/domain/evaporated_storage.dart';
import 'package:fire_bloc/fire_bloc/domain/fire_mixin.dart';

part 'fire_emitter_adapter.dart';

/// An event handler is responsible for reacting to an incoming [Event]
/// and can emit zero or more states via the [Emitter].
typedef FireEventHandler<Event, State> = FutureOr<void> Function(
  Event event,
  Emitter<State> fireEmit,
);

/// {@template fire_bloc}
/// Specialized [Bloc] which handles initializing the [Bloc] state
/// based on the persisted state. This allows state to be persisted
/// across hot restarts, complete app restarts, re-installations and switching
/// devices.
///
/// ```dart
/// sealed class CounterEvent {}
/// class CounterIncrement implements CounterEvent {}
/// class CounterDecrement implements CounterEvent {}
///
/// class CounterBloc extends FireBloc<CounterEvent, int> {
///   CounterBloc() : super(0) {
///     fireOn((event, emit) {
///       switch (state) {
///         case Some(value: final value):
///           switch (event) {
///             case CounterIncrement():
///               emit(value + 1);
///             case CounterDecrement():
///               emit(value - 1);
///           }
///         case None():
///           break;
///       }
///     });
///   }
///
///   @override
///   Option<int> fromJson(Map<String, dynamic> json) => switch (json['value']) {
///         final int value => Some(value),
///         _ => const None(),
///       };
///
///   @override
///   Map<String, dynamic> toJson(int state) => {'value': state};
/// }
/// ```
/// {@endtemplate}

abstract class FireBloc<Event, State> extends Bloc<Event, Option<State>>
    with FireMixin<State>
    implements EvaporatedStorageProviding {
  /// {@macro fire_bloc}
  FireBloc(
    State state, {
    EvaporatedStorage? storage,
  })  : _storage = storage,
        super(Some(state)) {
    incinerate();
  }

  @override
  EvaporatedStorage get storage => _storage ?? EvaporatedRepository.instance;

  final EvaporatedStorage? _storage;

  /// Register the event handler for all events (of type [Event]).
  /// [Event] should be a sealed class that all subtypes (concrete events)
  /// should implement.
  ///
  /// ```dart
  /// sealed class CounterEvent {}
  /// class CounterIncrement implements CounterEvent {}
  /// class CounterDecrement implements CounterEvent {}
  ///
  /// class CounterBloc extends FireBloc<CounterEvent, int> {
  ///   CounterBloc() : super(0) {
  ///     fireOn((event, emit) {
  ///       switch (state) {
  ///         case Some(value: final value):
  ///           switch (event) {
  ///             case CounterIncrement():
  ///               emit(value + 1);
  ///             case CounterDecrement():
  ///               emit(value - 1);
  ///           }
  ///         case None():
  ///           break;
  ///       }
  ///     });
  ///   }
  ///   ...
  /// }
  /// ```
  ///
  /// By default, events will be processed concurrently.
  ///
  /// See also:
  ///
  /// * [EventTransformer] to customize how events are processed.
  /// * [package:bloc_concurrency](https://pub.dev/packages/bloc_concurrency) for an
  /// opinionated set of event transformers.
  ///
  void fireOn(
    FireEventHandler<Event, State> handler, {
    EventTransformer<Event>? transformer,
  }) =>
      on<Event>(
        (event, emit) => handler(event, _FireEmitterAdapter(emit)),
        transformer: transformer,
      );
}
