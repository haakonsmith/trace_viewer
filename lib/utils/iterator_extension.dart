extension Move<T> on Iterator<T> {
  bool moveUntil(bool Function(T element) test) {
    do {
      if (test(current)) return true;
    } while (moveNext());

    return false;
  }
}
