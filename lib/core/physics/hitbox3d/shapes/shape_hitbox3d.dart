
import 'package:flame/collisions.dart';
import 'package:flame/components.dart' hide Vector3, Aabb3;
import 'package:flutter/cupertino.dart' hide Matrix4;
import 'package:mpg_achievements_app/3d/src/components/position_component_3d.dart';
import 'package:mpg_achievements_app/core/physics/hitbox3d/shapes/rectangle_hitbox3d.dart';
import 'package:mpg_achievements_app/core/physics/hitbox3d/shapes/shape_component_3d.dart';
import 'package:mpg_achievements_app/isometric/src/core/math/ray3.dart';
import 'package:mpg_achievements_app/isometric/src/core/math/transform3d.dart';
import 'package:vector_math/vector_math_64.dart' show Vector3, Aabb3;

import '../collision_callbacks3D.dart';
import '../collision_detection_3d.dart';
import '../has_collision_detection.dart';
import '../hitbox3d.dart';
import '../misc/aabb_listener.dart';
import '../util/composite_hitbox_3d.dart';
import '../util/intersection_systems_3d.dart' as intersection_system;
import '../util/raycasting_3d.dart';

/// A [ShapeHitbox3D] turns a [ShapeComponent3D] into a [Hitbox3D].
mixin ShapeHitbox3D on ShapeComponent3D implements Hitbox3D<ShapeHitbox3D> {
  final collisionTypeNotifier = CollisionTypeNotifier(CollisionType.active);

  set collisionType(CollisionType type) {
    if (collisionTypeNotifier.value == type) {
      return;
    }
    collisionTypeNotifier.value = type;
  }

  @override
  Color debugColor = const Color(0xFFFFFF00);


  @override
  CollisionType get collisionType => collisionTypeNotifier.value;


  /// Whether the hitbox is allowed to collide with another hitbox that is
  /// added to the same parent.
  bool allowSiblingCollision = false;

  /// Whether hitbox collisions with other hitboxes should trigger the
  /// "onCollision" functions for the hitbox's parent component.
  bool triggersParentCollision = true;

  @override
  Aabb3 get aabb => _validAabb ? _aabb : _recalculateAabb();
  final Aabb3 _aabb = Aabb3();
  bool _validAabb = false;

  @override
  Set<ShapeHitbox3D> get activeCollisions => _activeCollisions ??= {};
  Set<ShapeHitbox3D>? _activeCollisions;

  @override
  bool get isColliding => _activeCollisions != null && _activeCollisions!.isNotEmpty;

  @override
  bool collidingWith(Hitbox3D other) => _activeCollisions != null && activeCollisions.contains(other);

  CollisionDetection3D? _collisionDetection;
  final List<Transform3D> _transformAncestors = [];
  late Function() _transformListener;


  void onAabbChanged(){
    for (var element in _listeners) {
      element.onAabbChange(this);
    }
  }

  final List<HitboxAabb3Listener<ShapeHitbox3D>> _listeners = [];
  @override
  void addAabbListener(HitboxAabb3Listener<ShapeHitbox3D> listener){
    _listeners.add(listener);
  }
  @override
  void removeAabbListener(HitboxAabb3Listener<ShapeHitbox3D> listener){
    _listeners.remove(listener);
  }

  final Vector3 _halfExtents = Vector3.zero();
  static const double _extentEpsilon = 0.000000000000001;


  @override
  bool renderShape = false;

  late PositionComponent3d _hitboxParent;


  PositionComponent3d get hitboxParent => _hitboxParent;
  void Function()? _parentSizeListener;
  @protected
  bool shouldFillParent = false;

  @override
  void onMount() {
    super.onMount();
    final ancestor = ancestors()
        .whereType<PositionComponent3d>()
        .firstWhere(
          (c) => c is! CompositeHitbox3D,
      orElse: () => throw StateError(
        'A ShapeHitbox needs an IsoPositionComponent ancestor',
      ),
    );
    _hitboxParent = ancestor;

    _transformListener = () {
      _validAabb = false;
      onAabbChanged();
    };
    final positionComponents = ancestors().whereType<PositionComponent3d>();

    for (final ancestor in positionComponents) {
      _transformAncestors.add(ancestor.transform);
      ancestor.transform.addListener(_transformListener);
    }

    if (shouldFillParent) {
      _parentSizeListener = () {
        size = hitboxParent.size;
        fillParent();
      };
      _parentSizeListener?.call();
      hitboxParent.size.addListener(_parentSizeListener!);
    }

    // This should be placed after the hitbox parent listener
    // since the correct hitbox size is required by the QuadTree.
    final parent = findParent<HasCollisionDetection3D>();
    if (parent is HasCollisionDetection3D) {
      _collisionDetection = parent.collisionDetection;
      _collisionDetection?.add(this);
      if(_collisionDetection != null) print("added hitbox!");
    }

    onAabbChanged();
  }


  @override
  void onRemove() {
    if (_parentSizeListener != null) {
      hitboxParent.size.removeListener(_parentSizeListener!);
    }
    for (var t in _transformAncestors) {
      t.removeListener(_transformListener);
    }
    _collisionDetection?.remove(this);
    super.onRemove();
  }

  /// Checks whether the [ShapeHitbox] contains the [point], where [point] is
  /// a position in the global coordinate system of your game.
  @override
  @mustCallSuper
  bool containsPoint3D(Vector3 point) => _possiblyContainsPoint(point);

  /// Since this is a cheaper calculation than checking towards all shapes this
  /// check can be done first to see if it even is possible that the shapes can
  /// contain the point, since the shapes have to be within the size of the
  /// component.
  bool _possiblyContainsPoint(Vector3 point) => aabb.containsVector3(point);

  /// Where this [ShapeComponent] has intersection points with another shape
  @override
  Set<Vector3> intersections(Hitbox3D other) {
    assert(
    this is RectangleHitbox3D &&
    other is RectangleHitbox3D,
    'The intersection can only be performed between rect shapes',  //todo add support for more shapes
    );
    return intersection_system.intersections(this, other as RectangleHitbox3D);
  }


  /// Since this is a cheaper calculation than checking towards all shapes, this
  /// check can be done first to see if it even is possible that the shapes can
  /// overlap, since the shapes have to be within the size of the component.
  @override
  bool possiblyIntersects(ShapeHitbox3D other) {
    final collisionAllowed = allowSiblingCollision || hitboxParent != other.hitboxParent;
    return collisionAllowed && aabb.intersectsWithAabb3(other.aabb);
  }


  /// Returns information about how the ray intersects the shape.
  ///
  /// If you are only interested in the intersection point use
  /// [RaycastResult3D.intersectionPoint] of the result.
  RaycastResult3D<ShapeHitbox3D>? rayIntersection(
      Ray3 ray, {
        RaycastResult3D<ShapeHitbox3D>? out,
      });


  /// This determines how the shape should scale if it should try to fill its
  /// parents boundaries.
  void fillParent();


  Aabb3 _recalculateAabb() {
    _halfExtents.setValues(
      scaledSize.x / 2 + _extentEpsilon,
      scaledSize.y / 2 + _extentEpsilon,
      scaledSize.z / 2 + _extentEpsilon,
    );

    final Vector3 hitboxMin = absolutePosition;
    final Vector3 hitboxCenter = hitboxMin + Vector3(
      scaledSize.x / 2,
      scaledSize.y / 2,
      scaledSize.z / 2,
    );

    _validAabb = true;
    _aabb.setCenterAndHalfExtents(hitboxCenter, _halfExtents);


    return _aabb;
  }


  //#region CollisionCallbacks methods

  @override
  @mustCallSuper
  void onCollision(Set<Vector3> intersectionPoints, ShapeHitbox3D other) {
    onCollisionCallback?.call(intersectionPoints, other);
    if (hitboxParent is IsoCollisionCallbacks &&
        triggersParentCollision &&
        other.triggersParentCollision) {
      (hitboxParent as IsoCollisionCallbacks).onCollision(
        intersectionPoints,
        other.hitboxParent,
      );
    }
  }


  @override
  @mustCallSuper
  void onCollisionStart(Set<Vector3> intersectionPoints, ShapeHitbox3D other) {
    activeCollisions.add(other);
    onCollisionStartCallback?.call(intersectionPoints, other);
    if (hitboxParent is IsoCollisionCallbacks &&
        triggersParentCollision &&
        other.triggersParentCollision) {
      (hitboxParent as IsoCollisionCallbacks).onCollisionStart(
        intersectionPoints,
        other.hitboxParent,
      );
    }
  }
  
  

  @override
  @mustCallSuper
  void onCollisionEnd(ShapeHitbox3D other) {
    activeCollisions.remove(other);
    onCollisionEndCallback?.call(other);
    if (hitboxParent is IsoCollisionCallbacks &&
        triggersParentCollision &&
        other.triggersParentCollision) {
      (hitboxParent as IsoCollisionCallbacks).onCollisionEnd(other.hitboxParent);
    }
  }


  /// Defines whether the [other] component should be able to collide with
  /// this component.
  ///
  /// If the [hitboxParent] is not `IsoCollisionCallbacks` but `IsoPositionComponent`,
  /// there is no [CollisionCallbacks.onComponentTypeCheck] in that component.
  /// As a result, it will always be able to collide with all other types.
  @override
  @mustCallSuper
  bool onComponentTypeCheck(PositionComponent3d other) {
    final otherHitboxParent = (other as ShapeHitbox3D).hitboxParent;

    final thisCanCollideWithOther =
        (hitboxParent is! IsoCollisionCallbacks) ||
            (hitboxParent as IsoCollisionCallbacks).onComponentTypeCheck(
              otherHitboxParent,
            );

    final otherCanCollideWithThis =
        (otherHitboxParent is! IsoCollisionCallbacks) ||
            (otherHitboxParent as IsoCollisionCallbacks).onComponentTypeCheck(
              hitboxParent,
            );

    return thisCanCollideWithOther && otherCanCollideWithThis;
  }

  @override
  IsoCollisionCallback<ShapeHitbox3D>? onCollisionCallback;

  @override
  IsoCollisionCallback<ShapeHitbox3D>? onCollisionStartCallback;

  @override
  IsoCollisionEndCallback<ShapeHitbox3D>? onCollisionEndCallback;

  /// A unique ID for this [Hitbox3D].
  @override
  int id = _getNextId();

  static int _currentId = 0;
  static int _getNextId() {
    _currentId += 1;
    return _currentId;
  }

  //#endregion
}