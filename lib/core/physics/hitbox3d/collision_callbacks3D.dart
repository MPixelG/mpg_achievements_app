import 'package:flame/components.dart' hide Vector3;
import 'package:flutter/material.dart';
import 'package:mpg_achievements_app/3d/src/components/position_component_3d.dart';
import 'package:vector_math/vector_math_64.dart';

/// The [GenericCollisionCallbacks3D] mixin can be used to get callbacks from the
/// collision detection system, potentially without using the Flame component
/// system.
mixin GenericCollisionCallbacks3D<T> {
  Set<T>? _activeCollisions;

  /// The objects that the object is currently colliding with.
  Set<T> get activeCollisions => _activeCollisions ??= {};

  /// Whether the object is currently colliding or not.
  bool get isColliding => _activeCollisions?.isNotEmpty ?? false;

  /// Whether the object is colliding with [other] or not.
  bool collidingWith(T other) => _activeCollisions?.contains(other) ?? false;

  /// [onCollision] is called in every tick when this object is colliding with
  /// [other].
  @mustCallSuper
  void onCollision(Set<Vector3> intersectionPoints, T other) {
    onCollisionCallback?.call(intersectionPoints, other);
  }

  /// [onCollisionStart] is called in the first tick when this object starts
  /// colliding with [other].
  @mustCallSuper
  void onCollisionStart(Set<Vector3> intersectionPoints, T other) {
    activeCollisions.add(other);
    onCollisionStartCallback?.call(intersectionPoints, other);
  }

  /// [onCollisionEnd] is called once when this object has stopped colliding
  /// with [other].
  @mustCallSuper
  void onCollisionEnd(T other) {
    activeCollisions.remove(other);
    onCollisionEndCallback?.call(other);
  }

  /// Works only for the QuadTree collision detection.
  /// If you need to prevent collision of items of different types -
  /// reimplement [onComponentTypeCheck]. The result of calculation is cached
  /// so you should not check any dynamical parameters here, the function
  /// intended to be used as pure type checker.
  /// Call super.onComponentTypeCheck to get the parent's result of the
  /// type check if needed. In other causes this call is redundant in game code.
  bool onComponentTypeCheck(PositionComponent3d other);

  /// Assign your own [CollisionCallbacks3D] if you want a callback when this
  /// shape collides with another [T].
  CollisionCallback3D<T>? onCollisionCallback;

  /// Assign your own [CollisionCallbacks3D] if you want a callback when this
  /// shape starts to collide with another [T].
  CollisionCallback3D<T>? onCollisionStartCallback;

  /// Assign your own [CollisionEndCallback3D] if you want a callback when this
  /// shape stops colliding with another [T].
  CollisionEndCallback3D<T>? onCollisionEndCallback;
}

mixin CollisionCallbacks3D on Component
implements GenericCollisionCallbacks3D<PositionComponent3d> {
  @override
  Set<PositionComponent3d>? _activeCollisions;
  @override
  Set<PositionComponent3d> get activeCollisions => _activeCollisions ??= {};

  @override
  bool get isColliding => _activeCollisions != null && _activeCollisions!.isNotEmpty;

  @override
  bool collidingWith(PositionComponent3d other) => _activeCollisions != null && activeCollisions.contains(other);

  @override
  @mustCallSuper
  void onCollision(Set<Vector3> intersectionPoints, PositionComponent3d other) {
    onCollisionCallback?.call(intersectionPoints, other);
  }

  @override
  @mustCallSuper
  void onCollisionStart(
      Set<Vector3> intersectionPoints,
      PositionComponent3d other,
      ) {
    activeCollisions.add(other);
    onCollisionStartCallback?.call(intersectionPoints, other);
  }

  @override
  @mustCallSuper
  void onCollisionEnd(PositionComponent3d other) {
    activeCollisions.remove(other);
    onCollisionEndCallback?.call(other);
  }

  @override
  bool onComponentTypeCheck(PositionComponent3d other) {
    final myParent = parent;
    final otherParent = other.parent;
    if (myParent is CollisionCallbacks3D && otherParent is PositionComponent3d) {
      return myParent.onComponentTypeCheck(otherParent);
    }

    return true;
  }

  /// Assign your own [CollisionCallbacks3D] if you want a callback when this
  /// shape collides with another [PositionComponent3D].
  @override
  CollisionCallback3D<PositionComponent3d>? onCollisionCallback;

  /// Assign your own [CollisionCallbacks3D] if you want a callback when this
  /// shape starts to collide with another [IsoPositionComponent].
  @override
  CollisionCallback3D<PositionComponent3d>? onCollisionStartCallback;

  /// Assign your own [CollisionEndCallback3D] if you want a callback when this
  /// shape stops colliding with another [PositionComponent3D].
  @override
  CollisionEndCallback3D<PositionComponent3d>? onCollisionEndCallback;
}

/// Can be used used to implement an `onIsoCollisionCallbacks` or an
/// `onCollisionStartCallback`.
typedef CollisionCallback3D<T> =
void Function(
    Set<Vector3> intersectionPoints,
    T other,
    );

/// Can be used used to implement an `onCollisionEndCallback`.
typedef CollisionEndCallback3D<T> = void Function(T other);