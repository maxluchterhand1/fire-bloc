part of 'fire_bloc.dart';

class _FireEmitterAdapter<State> implements Emitter<State> {
  _FireEmitterAdapter(this._emitter);

  final Emitter<FireState<State>> _emitter;

  @override
  void call(State state) => _emitter.call(FireStateLoaded(state));

  @override
  Future<void> forEach<T>(
    Stream<T> stream, {
    required State Function(T data) onData,
    State Function(Object error, StackTrace stackTrace)? onError,
  }) =>
      _emitter.forEach(
        stream,
        onData: (data) => FireStateLoaded(onData(data)),
        onError: onError == null
            ? null
            : (error, stackTrace) =>
                FireStateLoaded(onError(error, stackTrace)),
      );

  @override
  bool get isDone => _emitter.isDone;

  @override
  Future<void> onEach<T>(
    Stream<T> stream, {
    required void Function(T data) onData,
    void Function(Object error, StackTrace stackTrace)? onError,
  }) =>
      _emitter.onEach(stream, onData: onData, onError: onError);
}
