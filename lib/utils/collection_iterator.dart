extension IntoCollectionIterator<T> on Iterable<T> {
  CollectionIterator<T> get collectionIterator => CollectionIterator(this);
}

class CollectionIterator<T> {
  int _i = 0;

  final Iterable<T> iterable;

  CollectionIterator(this.iterable);

  T? peek() {
    return iterable.elementAtOrNull(_i + 1);
  }

  bool moveNext() {
    final element = iterable.elementAtOrNull(_i + 1);

    if (element != null) {
      _i += 1;

      return true;
    }

    return false;
  }

  T get current => iterable.elementAt(_i);
}
