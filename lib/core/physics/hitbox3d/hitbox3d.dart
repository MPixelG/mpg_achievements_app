import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart' hide Vector3;
import 'package:flutter/cupertino.dart';
import 'package:vector_math/vector_math_64.dart' show Vector3;

import 'iso_collision_callbacks.dart';
import 'misc/aabb_listener.dart';

abstract class Hitbox3D<T extends Hitbox3D<T>> implements GenericIsoCollisionCallbacks<T> {

  /// Whether the hitbox should:
  ///   * [CollisionType.active] - actively collide with other hitboxes.
  ///   * [CollisionType.passive] - passively collide with other hitboxes (only
  ///   collide with hitboxes that are active, but not other passive ones).
  ///   * [CollisionType.inactive] - not collide with any other hitboxes.
  CollisionType get collisionType;

  /// The axis-aligned bounding box of the [Hitbox3D], this is used to make a
  /// rough estimation of whether two hitboxes can possibly collide or not.
  Aabb3 get aabb;


  int get id;
  /// Whether the hitbox is solid or hollow.
  ///
  /// If it is solid, intersections will occur even if the other component is
  /// fully enclosed by the other hitbox. The intersection point in such cases
  /// will be the center of the enclosed [Hitbox3D].
  /// A hollow shape that is fully enclosed by a solid hitbox will cause an
  /// intersection result, but not the other way around.
  bool get isSolid;

  void addAabbListener(HitboxAabb3Listener<T> listener);
  void removeAabbListener(HitboxAabb3Listener<T> listener);


  /// Checks whether the [Hitbox3D] contains the [point].
  bool containsPoint3D(Vector3 point);

  /// Where this [Hitbox3D] has intersection points with another [Hitbox3D].
  Set<Vector3> intersections(T other);


  /// This should be a cheaper calculation than comparing the exact boundaries
  /// if the exact calculation is expensive.
  /// This method could for example check two [Rect]s or [Aabb2]s against each
  /// other.
  bool possiblyIntersects(T other);
}