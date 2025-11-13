import 'package:flame/components.dart';
import 'package:mpg_achievements_app/core/physics/hitbox3d/shapes/shape_component_3d.dart';

class RectangleShapeComponent extends ShapeComponent3D {
  RectangleShapeComponent({
    required super.size,
    super.position,
    super.anchor,
    super.priority,
  });
}