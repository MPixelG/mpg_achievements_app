
T safeCast<T>(dynamic parent) {
  if (parent is T) {
    return parent;
  }
  throw StateError('Parent does not implement ${T.toString()}');
}