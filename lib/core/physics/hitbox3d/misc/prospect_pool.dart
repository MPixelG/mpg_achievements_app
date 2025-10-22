import 'package:flame/collisions.dart';
import 'package:mpg_achievements_app/core/physics/hitbox3d/hitbox3d.dart';

/// This pool is used to not create unnecessary [CollisionProspect] objects
/// during collision detection, but to re-use the ones that have already been
/// created.
class ProspectPool3D<T extends Hitbox3D<T>> {
  ProspectPool3D({this.incrementSize = 1000});

  /// How much the pool should increase in size every time it needs to be made
  /// larger.
  final int incrementSize;
  final _storage = <CollisionProspect<T>>[];
  int get length => _storage.length;

  /// The size of the pool will expand with [incrementSize] amount of
  /// [CollisionProspect]s that are initially populated with two [dummyItem]s.
  void expand(T dummyItem) {
    for (var i = 0; i < incrementSize; i++) {
      _storage.add(CollisionProspect<T>(dummyItem, dummyItem));
    }
  }

  CollisionProspect<T> operator [](int index) => _storage[index];
}
