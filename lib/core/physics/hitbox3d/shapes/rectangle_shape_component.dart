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
    return position.x < other.position.x + other.size.x &&
        position.x + size.x > other.position.x &&
        position.y < other.position.y + other.size.y &&
        position.y + size.y > other.position.y &&
        position.z < other.position.z + other.size.z &&
        position.z + size.z > other.position.z;
  }

  Set<Vector3> rectIntersections(RectangleShapeComponent other) {
    final intersectionPoints = <Vector3>{};

    if (!overlaps(other)) {
      return intersectionPoints;
    }

    final xMin = position.x > other.position.x ? position.x : other.position.x;
    final xMax = (position.x + size.x) < (other.position.x + other.size.x)
        ? (position.x + size.x)
        : (other.position.x + other.size.x);
    final yMin = position.y > other.position.y ? position.y : other.position.y;
    final yMax = (position.y + size.y) < (other.position.y + other.size.y)
        ? (position.y + size.y)
        : (other.position.y + other.size.y);
    final zMin = position.z > other.position.z ? position.z : other.position.z;
    final zMax = (position.z + size.z) < (other.position.z + other.size.z)
        ? (position.z + size.z)
        : (other.position.z + other.size.z);

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