class SortedList<T> {
  final List<T> _data = [];

  final double Function(T t) score;

  SortedList(this.score);

  void add(T element) {
    if (_data.isEmpty) {
      _data.add(element);
      return;
    }

    final elementScore = score(element);
    final index = _binarySearchInsertIndex(elementScore);
    _data.insert(index, element);
  }

  bool remove(T element) {
    return _data.remove(element);
  }

  T removeAt(int index) {
    return _data.removeAt(index);
  }

  void addAll(Iterable<T> elements) {
    for (var e in elements) {
      add(e);
    }
  }

  void update(T element) {
    if (_data.remove(element)) {
      add(element);
    }
  }

  int _binarySearchInsertIndex(double elementScore) {
    int low = 0;
    int high = _data.length;

    while (low < high) {
      final mid = (low + high) >> 1;
      final midScore = score(_data[mid]);

      if (elementScore < midScore) {
        high = mid;
      } else {
        low = mid + 1;
      }
    }
    return low;
  }

  T operator [](int index) => _data[index];
  void operator []=(int index, T val) {
    _data.removeAt(index);
    add(val);
  }

  int get length => _data.length;
  List<T> get data => List.unmodifiable(_data);

  @override
  String toString() => _data.toString();
}