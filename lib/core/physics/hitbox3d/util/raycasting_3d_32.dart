
import 'package:flame/components.dart';
import 'package:mpg_achievements_app/isometric/src/core/math/ray3.dart';

import '../hitbox3d_32.dart';

/// The result of a raycasting operation.
///
/// Note that the members of this class is heavily re-used. If you want to
/// keep the result in an object, clone the parts you want, or the whole
/// [RaycastResult] with [clone].
///
/// NOTE: This class might be subject to breaking changes in an upcoming
/// version, to make it possible to calculate the values lazily.
class RaycastResult3D<T extends Hitbox3D<T>> {
  RaycastResult3D({
    T? hitbox,
    Ray3? reflectionRay,
    Vector3? normal,
    double? distance,
    bool isInsideHitbox = false,
  }) : _isInsideHitbox = isInsideHitbox,
        _hitbox = hitbox,
        _reflectionRay = reflectionRay ?? Ray3.zero(),
        _normal = normal ?? Vector3.zero(),
        _distance = distance ?? double.maxFinite;

  /// Whether this result has active results in it.
  ///
  /// This is used so that the objects in there can continue to live even when
  /// there is no result from a ray cast.
  bool get isActive => _hitbox != null;

  /// Whether the origin of the ray was inside the hitbox.
  bool get isInsideHitbox => _isInsideHitbox;
  bool _isInsideHitbox;

  T? _hitbox;
  T? get hitbox => isActive ? _hitbox : null;

  final Ray3 _reflectionRay;
  Ray3? get reflectionRay => isActive ? _reflectionRay : null;

  Vector3? get intersectionPoint => reflectionRay?.origin;

  double _distance;
  double? get distance => isActive ? _distance : null;

  final Vector3 _normal;
  Vector3? get normal => isActive ? _normal : null;

  void reset() => _hitbox = null;

  /// Sets this [RaycastResult3D]'s objects to the values stored in [other].
  void setFrom(RaycastResult3D<T> other) {
    setWith(
      hitbox: other.hitbox,
      reflectionRay: other.reflectionRay,
      normal: other.normal,
      distance: other.distance,
      isInsideHitbox: other.isInsideHitbox,
    );
  }

  /// Sets the values of the result from the specified arguments.
  void setWith({
    T? hitbox,
    Ray3? reflectionRay,
    Vector3? normal,
    double? distance,
    bool isInsideHitbox = false,
  }) {
    _hitbox = hitbox;
    if (reflectionRay != null) {
      _reflectionRay.setFrom(reflectionRay);
    }
    if (normal != null) {
      _normal.setFrom(normal);
    }
    _distance = distance ?? double.maxFinite;
    _isInsideHitbox = isInsideHitbox;
  }

  RaycastResult3D<T> clone() => RaycastResult3D(
      hitbox: hitbox,
      reflectionRay: _reflectionRay.clone(),
      normal: _normal.clone(),
      distance: distance,
      isInsideHitbox: isInsideHitbox,
    );
}