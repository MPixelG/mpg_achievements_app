T safeCast<T>(dynamic parent) {
  if (parent is T) {
    return parent;
  }
  throw StateError('Parent does not implement ${T.toString()}');
}

extension SetAddition<T> on Set<T> {
  Set<T> operator+(Set<T> other){
    return followedBy(other).toSet();
  }
}
extension ListAddition<T> on List<T> {
  List<T> operator+(List<T> other){
    return followedBy(other).toList();
  }
}
extension IterableAddition<T> on Iterable<T> {
  Iterable<T> operator+(Iterable<T> other){
    return followedBy(other);
  }
}