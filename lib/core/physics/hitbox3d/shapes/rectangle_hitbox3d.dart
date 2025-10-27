import 'dart:async';

import 'package:mpg_achievements_app/core/math/ray3.dart';
import 'package:mpg_achievements_app/core/physics/hitbox3d/raycasting_3d.dart';
import 'package:mpg_achievements_app/core/physics/hitbox3d/shapes/rectangle_shape_component.dart';
import 'package:mpg_achievements_app/core/physics/hitbox3d/shapes/shape_hitbox3d.dart';

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
  RaycastResult3D<ShapeHitbox3D>? rayIntersection(Ray3 ray, {RaycastResult3D<ShapeHitbox3D>? out}) {
    return null; //todo implement ray intersections of rects. see flames RectangleHitbox for example in 2d
  }

  @override
  String toString(){
    return "RH3D(${aabb.min} - ${aabb.max})";
  }
}