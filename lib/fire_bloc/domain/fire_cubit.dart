import 'package:bloc/bloc.dart';
import 'package:fire_bloc/core/option.dart';
import 'package:fire_bloc/evaporated_storage/data/evaporated_repository.dart';
import 'package:fire_bloc/evaporated_storage/domain/evaporated_storage.dart';
import 'package:fire_bloc/fire_bloc/domain/fire_mixin.dart';
import 'package:meta/meta.dart';

/// {@template fire_cubit}
/// Specialized [Cubit] which handles initializing the [Cubit] state
/// based on the persisted state. This allows state to be persisted
/// across hot restarts, complete app restarts, re-installations and switching
/// devices.
///
/// ```dart
/// class CounterCubit extends FireCubit<int> {
///   CounterCubit() : super(0);
///
///   void increment() {
///     switch (state) {
///       case Some(value: final value):
///         fireEmit(value + 1);
///       case None():
///     }
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
///
/// {@endtemplate}
abstract class FireCubit<State> extends Cubit<Option<State>>
    with FireMixin<State>
    implements EvaporatedStorageProviding {
  /// {@macro fire_cubit}
  FireCubit(
    State state, {
    EvaporatedStorage? storage,
  })  : _storage = storage,
        super(Some(state)) {
    incinerate();
  }

  @override
  EvaporatedStorage get storage => _storage ?? EvaporatedRepository.instance;

  final EvaporatedStorage? _storage;

  /// Updates the [state] to the provided [state].
  /// [fireEmit] does nothing if the [state] being emitted
  /// is equal to the current [state].
  ///
  /// To allow for the possibility of notifying listeners of the initial state,
  /// emitting a state which is equal to the initial state is allowed as long
  /// as it is the first thing emitted by the instance.
  ///
  /// * Throws a [StateError] if the cubit/bloc is closed.
  @protected
  @visibleForTesting
  void fireEmit(State state) => emit(Some(state));
}
