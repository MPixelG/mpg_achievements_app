import 'package:flame/components.dart';
import 'package:mpg_achievements_app/core/physics/hitbox3d/shapes/rectangle_shape_component.dart';
import 'package:mpg_achievements_app/core/physics/hitbox3d/shapes/shape_component_3d.dart';
import 'package:vector_math/vector_math.dart';


abstract class Intersections3D<
T1 extends ShapeComponent3D,
T2 extends ShapeComponent3D
> {
  Set<Vector3> intersect(T1 shapeA, T2 shapeB);

  bool supportsShapes(ShapeComponent3D shapeA, ShapeComponent3D shapeB) {
    return shapeA is T1 && shapeB is T2 || shapeA is T2 && shapeB is T1;
  }

  Set<Vector3> unorderedIntersect(
      ShapeComponent3D shapeA,
      ShapeComponent3D shapeB,
      ) {
    if (shapeA is T1 && shapeB is T2) {
      return intersect(shapeA, shapeB);
    } else if (shapeA is T2 && shapeB is T1) {
      return intersect(shapeB, shapeA);
    } else {
      throw 'Unsupported shapes';
    }
  }
}



class RectangleIntersections
    extends Intersections3D<RectangleShapeComponent, RectangleShapeComponent> {
  /// Returns the intersection points of [polygonA] and [polygonB]
  /// The two polygons are required to be convex
  /// If they share a segment of a line, both end points and the center point of
  /// that line segment will be counted as collision points
  @override
  Set<Vector3> intersect(
      RectangleShapeComponent rect1,
      RectangleShapeComponent rect2) {
    return rect1.rectIntersections(rect2);
  }
}


final List<Intersections3D> _intersectionSystems = [
  RectangleIntersections(),
];


Set<Vector3> intersections(ShapeComponent3D shapeA, ShapeComponent3D shapeB) {
  final intersectionSystem = _intersectionSystems.firstWhere(
        (system) => system.supportsShapes(shapeA, shapeB),
    orElse: () {
      throw 'Unsupported intersection detected between: '
          '${shapeA.runtimeType} and ${shapeB.runtimeType}';
    },
  );
  return intersectionSystem.unorderedIntersect(shapeA, shapeB);
}