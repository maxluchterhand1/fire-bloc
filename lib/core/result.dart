// ignore_for_file: public_member_api_docs

/// Result<T, E> is used for returning and propagating errors.
/// It is a sealed class with the variants, Success(T), representing success
/// and containing a value, and Failure(E), representing error and containing
/// an optional error value.
sealed class Result<T, E> {}

/// Contains the success value.
class Success<T, E> implements Result<T, E> {
  const Success(this.value);

  final T value;

  static Success<void, E> empty<E>() => Success<void, E>(null);
}

/// Optionally contains the error value.
class Failure<T, E> implements Result<T, E> {
  const Failure([this.value]);

  final E? value;
}
