
import 'package:flame/collisions.dart';

import '../hitbox3d_32.dart';

/// The [Broadphase3D] class is used to make collision detection more efficient
/// by doing a rough estimation of which hitboxes that can collide before their
/// actual intersections are calculated.
abstract class Broadphase3D<T extends Hitbox3D<T>> {
  Broadphase3D();

  /// This method can be used if there are things that needs to be prepared in
  /// each tick.
  void update() {}

  /// Returns a flat List of items regardless of what data structure is used to
  /// store collision information.
  List<T> get items;

  /// Adds an item to the broadphase. Should be called in a
  /// [CollisionDetection3D] class while adding a hitbox into its collision
  /// detection system.
  void add(T item);

  void addAll(Iterable<T> items) {
    for (final item in items) {
      add(item);
    }
  }

  /// Removes an item from the broadphase. Should be called in a
  /// [CollisionDetection3D] class while removing a hitbox from its collision
  /// detection system.
  void remove(T item);

  void removeAll(Iterable<T> items) {
    for (final item in items) {
      remove(item);
    }
  }

  /// Returns the potential hitbox collisions
  Iterable<CollisionProspect<T>> query();
}