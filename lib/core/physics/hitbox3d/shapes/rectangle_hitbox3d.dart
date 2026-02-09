import 'package:mpg_achievements_app/3d/src/components/position_component_3d.dart';
import 'package:mpg_achievements_app/core/physics/hitbox3d/shapes/shape_hitbox3d.dart';
import 'package:mpg_achievements_app/isometric/src/core/math/ray3.dart';
import 'package:vector_math/vector_math_64.dart';

import '../util/raycasting_3d.dart';
import 'rectangle_shape_component.dart';

class RectangleHitbox3D extends RectangleShapeComponent with ShapeHitbox3D {
  RectangleHitbox3D({
    required super.size,
    super.position,
    super.anchor,
    super.priority,
  });

  @override
  void fillParent() {
    //if no parent available return
      if (parent is! PositionComponent3d) {

      return;
    }
    final parentComponent = parent as PositionComponent3d;
    //set size of parent component
    size.setFrom(parentComponent.size);
    //set position of hitbox relative to parent
    position.setZero();
    //set anchor ot parent anchor
    anchor = parentComponent.anchor;
    }

  @override
  RaycastResult3D<ShapeHitbox3D>? rayIntersection(Ray3 ray, {RaycastResult3D<ShapeHitbox3D>? out}) =>
    null; //todo implement ray intersections of rects. see flames RectangleHitbox for example in 2d

  @override
  String toString()=> "RH3D(${aabb.min} - ${aabb.max})";


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

  @override
  void onMount() {
    super.onMount();
    if (size.length == 0 || size == Vector3.zero()) {
      fillParent();
    }
  }
}