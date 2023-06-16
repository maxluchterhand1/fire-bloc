sealed class Result<T, E> {}

class Success<T, E> implements Result<T, E> {
  const Success(this.value);

  final T value;

  static Success<void, E> empty<E>() => Success<void, E>(null);
}

class Failure<T, E> implements Result<T, E> {
  const Failure([this.value]);

  final E? value;
}
