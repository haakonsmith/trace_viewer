extension Try<T> on T? {
  K? map<K>(K Function(T value) mapper) {
    return this == null ? null : mapper(this!);
  }
}
