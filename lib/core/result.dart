sealed class Option<T> {}

class Some<T> implements Option<T> {
  const Some(this.value);

  final T value;
}

class None<T> implements Option<T> {
  const None();
}
