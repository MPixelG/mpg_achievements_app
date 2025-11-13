import 'dart:async';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:mpg_achievements_app/core/math/ray3.dart';
import 'package:mpg_achievements_app/core/physics/hitbox3d/util/raycasting_3d.dart';
import 'package:mpg_achievements_app/core/physics/hitbox3d/shapes/rectangle_shape_component.dart';
import 'package:mpg_achievements_app/core/physics/hitbox3d/shapes/shape_hitbox3d.dart';
import 'package:mpg_achievements_app/util/render_utils.dart';

class RectangleHitbox3D extends RectangleShapeComponent with ShapeHitbox3D {
  RectangleHitbox3D({
    required super.size,
    super.position,
    super.anchor,
    super.priority,
  });

  @override
  void fillParent() {
    //todo create fill parent function
  }

  @override
  FutureOr<void> onLoad() {
    print("onLoad RectHitbox with position $position and size $size");
    return super.onLoad();
  }

  @override
  RaycastResult3D<ShapeHitbox3D>? rayIntersection(Ray3 ray, {RaycastResult3D<ShapeHitbox3D>? out}) =>
    null; //todo implement ray intersections of rects. see flames RectangleHitbox for example in 2d

  @override
  String toString()=> "RH3D(${aabb.min} - ${aabb.max})";

  @override
  void renderDebugMode(Canvas canvas, [Canvas? normalCanvas, Paint Function()? getNormalPaint]) {
    super.render(canvas);

    final Vector3 size = aabb.max - aabb.min;
    drawIsometricBox(canvas, Vector3.zero(), Vector3(size.x, size.y, size.z));
  }

  @override
  void renderTree(Canvas canvas, [Canvas? normalCanvas, Paint Function()? getNormalPaint]){
    super.renderTree(canvas, normalCanvas, getNormalPaint);

    canvas.drawCircle(Offset.zero, 3, Paint()..color=Colors.deepPurple);
  }


  Set<Vector3> rectIntersections(RectangleHitbox3D other) {
    final intersectionPoints = <Vector3>{};

    if (!overlaps(other)) {
      return intersectionPoints;
    }

    final thisMin = aabb.min;
    final thisMax = aabb.max;
    final otherMin = other.aabb.min;
    final otherMax = other.aabb.max;

    final xMin = thisMin.x > otherMin.x ? thisMin.x : otherMin.x;
    final xMax = thisMax.x < otherMax.x ? thisMax.x : otherMax.x;
    final yMin = thisMin.y > otherMin.y ? thisMin.y : otherMin.y;
    final yMax = thisMax.y < otherMax.y ? thisMax.y : otherMax.y;
    final zMin = thisMin.z > otherMin.z ? thisMin.z : otherMin.z;
    final zMax = thisMax.z < otherMax.z ? thisMax.z : otherMax.z;

    if (xMin >= xMax || yMin >= yMax || zMin >= zMax) {
      return intersectionPoints;
    }

    intersectionPoints.add(Vector3(xMin, yMin, zMin));
    intersectionPoints.add(Vector3(xMax, yMin, zMin));
    intersectionPoints.add(Vector3(xMin, yMax, zMin));
    intersectionPoints.add(Vector3(xMax, yMax, zMin));
    intersectionPoints.add(Vector3(xMin, yMin, zMax));
    intersectionPoints.add(Vector3(xMax, yMin, zMax));
    intersectionPoints.add(Vector3(xMin, yMax, zMax));
    intersectionPoints.add(Vector3(xMax, yMax, zMax));

    return intersectionPoints;
  }

  bool overlaps(RectangleHitbox3D other) {
    final thisMin = aabb.min;
    final thisMax = aabb.max;
    final otherMin = other.aabb.min;
    final otherMax = other.aabb.max;


    return thisMin.x < otherMax.x &&
        thisMax.x > otherMin.x &&
        thisMin.y < otherMax.y &&
        thisMax.y > otherMin.y &&
        thisMin.z < otherMax.z &&
        thisMax.z > otherMin.z;
  }
}