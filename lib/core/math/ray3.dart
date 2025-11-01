import 'dart:math';

import 'package:flame/extensions.dart';
import 'package:flame/geometry.dart';
import 'package:flutter/cupertino.dart';
import 'package:mpg_achievements_app/core/math/line_segment_3d.dart';

/// A ray in 3D space.
///
/// The [direction] should be normalized.
class Ray3 {
  Ray3({required this.origin, required Vector3 direction}) {
    this.direction = direction;
  }

  Ray3.zero() : this(origin: Vector3.zero(), direction: Vector3(1, 0, 0));

  /// The point where the ray originates from.
  Vector3 origin;

  /// The normalized direction of the ray.
  ///
  /// The values within the direction object should not be updated manually, use
  /// the setter instead.
  Vector3 get direction => _direction;
  set direction(Vector3 direction) {
    _direction.setFrom(direction);
    _updateInverses();
  }

  final Vector3 _direction = Vector3.zero();

  /// Should be called if the [direction] values are updated within the object
  /// instead of by the setter.
  void _updateInverses() {
    assert(
    (direction.length2 - 1).abs() < 0.000001,
    'direction must be normalized',
    );
    directionInvX = (1 / direction.x).toFinite();
    directionInvY = (1 / direction.y).toFinite();
    directionInvZ = (1 / direction.z).toFinite();
  }

  // These are the inverse of the direction (the normal), they are used to avoid
  // a division in [intersectsWithAabb3], since a ray will usually be tried
  // against many bounding boxes it's good to pre-calculate it, which is done
  // in the direction setter.
  @visibleForTesting
  late double directionInvX;
  @visibleForTesting
  late double directionInvY;
  @visibleForTesting
  late double directionInvZ;

  /// Whether the ray intersects the [box] or not.
  ///
  /// Rays that originate on the edge of the [box] are considered to be
  /// intersecting with the box no matter what direction they have.
  // This uses the Branchless Ray/Bounding box intersection method by Tavian,
  // but since +-infinity is replaced by +-maxFinite for directionInvX,
  // directionInvY, and directionInvZ, rays that originate on an edge will
  // always be considered to intersect with the aabb, no matter what direction
  // they have.
  // https://tavianator.com/2011/ray_box.html
  // https://tavianator.com/2015/ray_box_nan.html
  bool intersectsWithAabb3(Aabb3 box) {
    final tx1 = (box.min.x - origin.x) * directionInvX;
    final tx2 = (box.max.x - origin.x) * directionInvX;

    final ty1 = (box.min.y - origin.y) * directionInvY;
    final ty2 = (box.max.y - origin.y) * directionInvY;

    final tz1 = (box.min.z - origin.z) * directionInvZ;
    final tz2 = (box.max.z - origin.z) * directionInvZ;

    final tMin = max(max(min(tx1, tx2), min(ty1, ty2)), min(tz1, tz2));
    final tMax = min(min(max(tx1, tx2), max(ty1, ty2)), max(tz1, tz2));

    return tMax >= max(tMin, 0.0);
  }

  /// Backward compatibility alias for [intersectsWithAabb3].
  @Deprecated('Use intersectsWithAabb3 instead')
  bool intersectsWithAabb2(Aabb3 box) => intersectsWithAabb3(box);

  /// Gives the point at a certain length along the ray.
  Vector3 point(double length, {Vector3? out}) => ((out?..setFrom(origin)) ?? origin.clone())
      ..addScaled(direction, length);

  static final Vector3 _edge1 = Vector3.zero();
  static final Vector3 _edge2 = Vector3.zero();
  static final Vector3 _h = Vector3.zero();
  static final Vector3 _s = Vector3.zero();
  static final Vector3 _q = Vector3.zero();

  /// Returns where (length wise) on the ray that the ray intersects the
  /// [segment] or null if there is no intersection.
  ///
  /// Uses the Möller-Trumbore algorithm adapted for line segments in 3D space.
  /// A ray that is parallel and overlapping with the [segment] is considered to
  /// not intersect. This is due to that a single intersection point can't be
  /// determined and that a [LineSegment] is almost always connected to another
  /// line segment which will get the intersection on one of its ends instead.
  double? lineSegmentIntersection(LineSegment3D segment) {
    const epsilon = 0.0000001;

    // Treat the line segment as a degenerate triangle
    // We use the segment as one edge and a perpendicular vector as the other
    _edge1
      ..setFrom(segment.to)
      ..sub(segment.from);

    // Create a perpendicular edge for the degenerate triangle test
    // This creates a thin triangular region around the line segment
    _edge2.setValues(
      _edge1.y != 0 || _edge1.z != 0 ? 1.0 : 0.0,
      _edge1.x != 0 ? -1.0 : 0.0,
      0.0,
    );

    (_h..setFrom(direction)).crossInto(_edge2, _h);
    final a = _edge1.dot(_h);

    if (a.abs() < epsilon) {
      // Ray is parallel to line segment
      return null;
    }

    final f = 1.0 / a;
    _s
      ..setFrom(origin)
      ..sub(segment.from);
    final u = f * _s.dot(_h);

    if (u < 0.0 || u > 1.0) {
      return null;
    }

    (_q..setFrom(_s)).crossInto(_edge1, _q);
    final t = f * direction.dot(_q);

    if (t > epsilon) {
      // Check if intersection point is actually on the line segment
      final intersectionPoint = point(t);
      final toIntersection = intersectionPoint..sub(segment.from);
      final projectionLength = toIntersection.dot(_edge1) / _edge1.length2;

      if (projectionLength >= 0.0 && projectionLength <= 1.0) {
        return t;
      }
    }

    return null;
  }

  /// Deep clones the object, i.e. both [origin] and [direction] are cloned into
  /// a new [Ray3] object.
  Ray3 clone() => Ray3(origin: origin.clone(), direction: direction.clone());

  /// Sets the values by copying them from [other].
  void setFrom(Ray3 other) {
    setWith(origin: other.origin, direction: other.direction);
  }

  void setWith({required Vector3 origin, required Vector3 direction}) {
    this.origin.setFrom(origin);
    this.direction = direction;
  }

  @override
  String toString() => 'Ray3(origin: $origin, direction: $direction)';
}