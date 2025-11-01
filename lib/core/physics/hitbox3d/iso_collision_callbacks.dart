
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/cupertino.dart';
import 'package:mpg_achievements_app/core/iso_component.dart';

/// The [GenericIsoCollisionCallbacks] mixin can be used to get callbacks from the
/// collision detection system, potentially without using the Flame component
/// system.
mixin GenericIsoCollisionCallbacks<T> {
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
  bool onComponentTypeCheck(IsoPositionComponent other);

  /// Assign your own [IsoCollisionCallbacks] if you want a callback when this
  /// shape collides with another [T].
  IsoCollisionCallback<T>? onCollisionCallback;

  /// Assign your own [IsoCollisionCallbacks] if you want a callback when this
  /// shape starts to collide with another [T].
  IsoCollisionCallback<T>? onCollisionStartCallback;

  /// Assign your own [IsoCollisionEndCallback] if you want a callback when this
  /// shape stops colliding with another [T].
  IsoCollisionEndCallback<T>? onCollisionEndCallback;
}

mixin IsoCollisionCallbacks on Component
implements GenericIsoCollisionCallbacks<IsoPositionComponent> {
  @override
  Set<IsoPositionComponent>? _activeCollisions;
  @override
  Set<IsoPositionComponent> get activeCollisions => _activeCollisions ??= {};

  @override
  bool get isColliding => _activeCollisions != null && _activeCollisions!.isNotEmpty;

  @override
  bool collidingWith(IsoPositionComponent other) => _activeCollisions != null && activeCollisions.contains(other);

  @override
  @mustCallSuper
  void onCollision(Set<Vector3> intersectionPoints, IsoPositionComponent other) {
    onCollisionCallback?.call(intersectionPoints, other);
  }

  @override
  @mustCallSuper
  void onCollisionStart(
      Set<Vector3> intersectionPoints,
      IsoPositionComponent other,
      ) {
    activeCollisions.add(other);
    onCollisionStartCallback?.call(intersectionPoints, other);
  }

  @override
  @mustCallSuper
  void onCollisionEnd(IsoPositionComponent other) {
    activeCollisions.remove(other);
    onCollisionEndCallback?.call(other);
  }

  @override
  bool onComponentTypeCheck(IsoPositionComponent other) {
    final myParent = parent;
    final otherParent = other.parent;
    if (myParent is IsoCollisionCallbacks && otherParent is IsoPositionComponent) {
      return myParent.onComponentTypeCheck(otherParent);
    }

    return true;
  }

  /// Assign your own [IsoCollisionCallbacks] if you want a callback when this
  /// shape collides with another [IsoPositionComponent].
  @override
  IsoCollisionCallback<IsoPositionComponent>? onCollisionCallback;

  /// Assign your own [IsoCollisionCallbacks] if you want a callback when this
  /// shape starts to collide with another [IsoPositionComponent].
  @override
  IsoCollisionCallback<IsoPositionComponent>? onCollisionStartCallback;

  /// Assign your own [CollisionEndCallback] if you want a callback when this
  /// shape stops colliding with another [IsoPositionComponent].
  @override
  IsoCollisionEndCallback<IsoPositionComponent>? onCollisionEndCallback;
}

/// Can be used used to implement an `onIsoCollisionCallbacks` or an
/// `onCollisionStartCallback`.
typedef IsoCollisionCallback<T> =
void Function(
    Set<Vector3> intersectionPoints,
    T other,
    );

/// Can be used used to implement an `onCollisionEndCallback`.
typedef IsoCollisionEndCallback<T> = void Function(T other);