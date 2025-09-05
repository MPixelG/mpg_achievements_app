import 'package:flame/components.dart';

/// A mixin for components that can be rendered in an isometric view.
mixin IsometricRenderable on PositionComponent{
  int get renderPriority;
  Vector2 get gridFeetPos;
}