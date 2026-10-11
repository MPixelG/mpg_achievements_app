import 'dart:collection';
import 'dart:math';

import 'package:flame/collisions.dart';

/// This pool is used to not create unnecessary [CollisionProspect] objects
/// during collision detection, but to re-use the ones that have already been
/// created.
///
/// Since Flame 1.38 [CollisionProspect] is an immutable interface without a
/// public constructor, so the pool uses its own private mutable subclass and
/// only exposes the immutable interface (mirrors Flame's `ProspectPool`, which
/// is restricted to 2D `Hitbox` types).
class ProspectPool3D<T> extends IterableBase<CollisionProspect<T>> {
  ProspectPool3D({this.incrementSize = 1000});

  /// How much the pool should increase in size every time it needs to be made
  /// larger.
  final int incrementSize;
  final _storage = <_MutableCollisionProspect3D<T>>[];

  /// The number of prospects currently acquired this frame.
  @override
  int get length => _count;
  int _count = 0;

  @override
  Iterator<CollisionProspect<T>> get iterator =>
      _storage.take(_count).iterator;

  /// Returns a [CollisionProspect] populated with [a] and [b], reusing a
  /// pooled object or expanding the pool as needed.
  CollisionProspect<T> acquire(T a, T b) {
    if (_storage.length <= _count) {
      _expand(a);
    }
    final prospect = _storage[_count]..set(a, b);
    _count++;
    return prospect;
  }

  /// Copies all prospects from [source] into the pool.
  void acquireAll(Iterable<CollisionProspect<T>> source) {
    for (final prospect in source) {
      acquire(prospect.a, prospect.b);
    }
  }

  /// Resets the pool for the next frame. Previously acquired prospects should
  /// not be accessed after this call.
  void reset() {
    _count = 0;
  }

  /// Returns the [CollisionProspect] at [index] (must be < [length]).
  CollisionProspect<T> operator [](int index) => _storage[index];

  void _expand(T dummyItem) {
    final target = _storage.length + max(1, incrementSize);
    while (_storage.length < target) {
      _storage.add(_MutableCollisionProspect3D<T>(dummyItem, dummyItem));
    }
  }
}

// ignore: must_be_immutable
class _MutableCollisionProspect3D<T> extends CollisionProspect<T> {
  _MutableCollisionProspect3D(this._a, this._b);

  T _a;
  T _b;

  @override
  T get a => _a;

  @override
  T get b => _b;

  void set(T a, T b) {
    _a = a;
    _b = b;
  }
}
