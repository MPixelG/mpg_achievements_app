import 'package:flame/components.dart' show PositionComponent, Vector2;
import 'package:mpg_achievements_app/components/level/isometric/isometric_tiled_component.dart';

/// A mixin for components that can be rendered in an isometric view.
mixin IsometricRenderable on PositionComponent{
  int get renderPriority;
  Vector2 get gridFeetPos;
  RenderCategory get renderCategory;
}