import 'dart:math' as math;

import 'package:mpg_achievements_app/core/math/ray3.dart';
import 'package:mpg_achievements_app/core/physics/hitbox3d/broadphase/broadphase_3d.dart';
import 'package:mpg_achievements_app/core/physics/hitbox3d/broadphase/chunking_broadphase_3d.dart';
import 'package:mpg_achievements_app/core/physics/hitbox3d/collision_detection_3d.dart';
import 'package:mpg_achievements_app/core/physics/hitbox3d/util/raycasting_3d.dart';
import 'package:mpg_achievements_app/core/physics/hitbox3d/shapes/shape_hitbox3d.dart';
import 'package:vector_math/vector_math.dart';

class ChunkingCollisionDetection3D<B extends Broadphase3D<ShapeHitbox3D>>
    extends CollisionDetection3D<ShapeHitbox3D, B> {


  ChunkingCollisionDetection3D({B? broadphase})
      : super(broadphase: broadphase ?? ChunkingBroadphase3D<ShapeHitbox3D>() as B);

  /// Calls the two colliding hitboxes every tick when they are colliding.
  /// They are called with the [intersectionPoints] and instances of each other,
  /// so that they can determine what hitbox (and what
  /// [ShapeHitbox3D.hitboxParent] that they have collided with.
  @override
  void handleCollision(
      Set<Vector3> intersectionPoints,
      ShapeHitbox3D hitboxA,
      ShapeHitbox3D hitboxB,
      ) {
    hitboxA.onCollision(intersectionPoints, hitboxB);
    hitboxB.onCollision(intersectionPoints, hitboxA);
  }


  /// Calls the two colliding hitboxes once when two hitboxes have stopped
  /// colliding.
  /// They are called with instances of each other, so that they can determine
  /// what hitbox (and what [ShapeHitbox3D.hitboxParent] that they have stopped
  /// colliding with.
  @override
  void handleCollisionEnd(ShapeHitbox3D hitboxA, ShapeHitbox3D hitboxB) {
    hitboxA.onCollisionEnd(hitboxB);
    hitboxB.onCollisionEnd(hitboxA);
  }

  /// Calls the two colliding hitboxes when they first starts to collide.
  /// They are called with the [intersectionPoints] and instances of each other,
  /// so that they can determine what hitbox (and what
  /// [ShapeHitbox3D.hitboxParent] that they have collided with.
  @override
  void handleCollisionStart(
      Set<Vector3> intersectionPoints,
      ShapeHitbox3D hitboxA,
      ShapeHitbox3D hitboxB,
      ) {
    hitboxA.onCollisionStart(intersectionPoints, hitboxB);
    hitboxB.onCollisionStart(intersectionPoints, hitboxA);
  }

  /// Check what the intersection points of two collidables are,
  /// returns an empty list if there are no intersections.
  @override
  Set<Vector3> intersections(
      ShapeHitbox3D hitboxA,
      ShapeHitbox3D hitboxB,
      ) => hitboxA.intersections(hitboxB);


  static final _temporaryRaycastResult = RaycastResult3D<ShapeHitbox3D>();

  static final _temporaryRayAabb = Aabb3();

  @override
  RaycastResult3D<ShapeHitbox3D>? raycast(
      Ray3 ray, {
        double? maxDistance,
        bool Function(ShapeHitbox3D candidate)? hitboxFilter,
        List<ShapeHitbox3D>? ignoreHitboxes,
        RaycastResult3D<ShapeHitbox3D>? out,
      }) {
    var finalResult = out?..reset();
    _updateRayAabb(ray, maxDistance);
    for (final item in items) {
      if (ignoreHitboxes?.contains(item) ?? false) {
        continue;
      }
      if (hitboxFilter != null) {
        if (!hitboxFilter(item)) {
          continue;
        }
      }
      if (!item.aabb.intersectsWithAabb3(_temporaryRayAabb)) {
        continue;
      }
      final currentResult = item.rayIntersection(
        ray,
        out: _temporaryRaycastResult,
      );
      final possiblyFirstResult = !(finalResult?.isActive ?? false);
      if (currentResult != null &&
          (possiblyFirstResult ||
              currentResult.distance! < finalResult!.distance!) &&
          currentResult.distance! <= (maxDistance ?? double.infinity)) {
        if (finalResult == null) {
          finalResult = currentResult.clone();
        } else {
          finalResult.setFrom(currentResult);
        }
      }
    }
    return (finalResult?.isActive ?? false) ? finalResult : null;
  }

  @override
  List<RaycastResult3D<ShapeHitbox3D>> raycastAll(
      Vector3 origin, {
        required int numberOfRays,
        Vector2? startAngle,
        Vector2? sweepAngle,
        double? maxDistance,
        List<Ray3>? rays,
        bool Function(ShapeHitbox3D candidate)? hitboxFilter,
        List<ShapeHitbox3D>? ignoreHitboxes,
        List<RaycastResult3D<ShapeHitbox3D>>? out,
      }) {
    throw UnimplementedError("raycastAll for 3D is not implemented yet.");
    //TODO implement raycastAll for 3D

    /*
    final isFullCircle = (sweepAngle % tau).abs() < 0.0001;
    final angle = sweepAngle / (numberOfRays + (isFullCircle ? 0 : -1));
    final results = <RaycastResult3D<ShapeHitbox3D>>[];
    final direction = Vector3(1, 0, 0);
    for (var i = 0; i < numberOfRays; i++) {
      Ray3 ray;
      if (i < (rays?.length ?? 0)) {
        ray = rays![i];
      } else {
        ray = Ray3.zero();
        rays?.add(ray);
      }
      ray.origin.setFrom(origin);
      direction
        ..setValues(0, -1, 0)
        ..rotate(startAngle - angle * i);
      ray.direction = direction;

      RaycastResult3D<ShapeHitbox3D>? result;
      if (i < (out?.length ?? 0)) {
        result = out![i];
      } else {
        result = RaycastResult3D();
        out?.add(result);
      }
      result = raycast(
        ray,
        maxDistance: maxDistance,
        hitboxFilter: hitboxFilter,
        ignoreHitboxes: ignoreHitboxes,
        out: result,
      );

      if (result != null) {
        results.add(result);
      }
    }
    return results;*/
  }

  @override
  Iterable<RaycastResult3D<ShapeHitbox3D>> raytrace(
      Ray3 ray, {
        int maxDepth = 10,
        bool Function(ShapeHitbox3D candidate)? hitboxFilter,
        List<ShapeHitbox3D>? ignoreHitboxes,
        List<RaycastResult3D<ShapeHitbox3D>>? out,
      }) sync* {
    if (out != null) {
      for (final result in out) {
        result.reset();
      }
    }
    var currentRay = ray;
    for (var i = 0; i < maxDepth; i++) {
      final hasResultObject = (out?.length ?? 0) > i;
      final storeResult = hasResultObject
          ? out![i]
          : RaycastResult3D<ShapeHitbox3D>();
      final currentResult = raycast(
        currentRay,
        hitboxFilter: hitboxFilter,
        ignoreHitboxes: ignoreHitboxes,
        out: storeResult,
      );
      if (currentResult != null) {
        currentRay = storeResult.reflectionRay!;
        if (!hasResultObject && out != null) {
          out.add(storeResult);
        }
        yield storeResult;
      } else {
        break;
      }
    }
  }

  /// Computes an axis-aligned bounding box for a [ray].
  ///
  /// When [maxDistance] is provided, this will be the bounding box around
  /// the origin of the ray and its ending point. When [maxDistance]
  /// is `null`, the bounding box will encompass the whole quadrant
  /// of space, from the ray's origin to infinity.
  void _updateRayAabb(Ray3 ray, double? maxDistance) {
    final x1 = ray.origin.x;
    final y1 = ray.origin.y;
    final z1 = ray.origin.z;
    double x2;
    double y2;
    double z2;

    if (maxDistance != null) {
      x2 = ray.origin.x + ray.direction.x * maxDistance;
      y2 = ray.origin.y + ray.direction.y * maxDistance;
      z2 = ray.origin.z + ray.direction.z * maxDistance;
    } else {
      x2 = ray.direction.x > 0 ? double.infinity : double.negativeInfinity;
      y2 = ray.direction.y > 0 ? double.infinity : double.negativeInfinity;
      z2 = ray.direction.z > 0 ? double.infinity : double.negativeInfinity;
    }

    _temporaryRayAabb
      ..min.setValues(math.min(x1, x2), math.min(y1, y2), math.min(z1, z2))
      ..max.setValues(math.max(x1, x2), math.max(y1, y2), math.max(z1, z2));
  }
}