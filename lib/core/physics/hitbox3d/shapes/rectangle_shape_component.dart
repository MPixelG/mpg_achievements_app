import 'package:flame/components.dart';
import 'package:mpg_achievements_app/core/physics/hitbox3d/shapes/shape_component_3d.dart';

class RectangleShapeComponent extends ShapeComponent3D {
  RectangleShapeComponent({
    required super.size,
    super.position,
    super.anchor,
    super.priority,
  });


  bool containsPoint3D(Vector3 point) {
    final abs = absolutePosition;
    return point.x >= abs.x &&
        point.x <= abs.x + size.x &&
        point.y >= abs.y &&
        point.y <= abs.y + size.y &&
        point.z >= abs.z &&
        point.z <= abs.z + size.z;
  }

  bool overlaps(RectangleShapeComponent other) {
    final thisMin = absolutePosition;
    final thisMax = thisMin + size;
    final otherMin = other.absolutePosition;
    final otherMax = otherMin + other.size;

    return thisMin.x < otherMax.x &&
        thisMax.x > otherMin.x &&
        thisMin.y < otherMax.y &&
        thisMax.y > otherMin.y &&
        thisMin.z < otherMax.z &&
        thisMax.z > otherMin.z;
  }

  Set<Vector3> rectIntersections(RectangleShapeComponent other) {
    final intersectionPoints = <Vector3>{};

    if (!overlaps(other)) {
      return intersectionPoints;
    }

    final thisMin = absolutePosition;
    final thisMax = thisMin + size;
    final otherMin = other.absolutePosition;
    final otherMax = otherMin + other.size;

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
}