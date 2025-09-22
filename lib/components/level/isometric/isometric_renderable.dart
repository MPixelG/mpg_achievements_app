import 'dart:ui';

import 'package:flame/components.dart';
import 'package:mpg_achievements_app/components/level/isometric/isometric_tiled_component.dart';

/// A mixin for components that can be rendered in an isometric view.
mixin IsometricRenderable{
  Vector3 get gridFeetPos;
  Vector3 get gridHeadPos;
  RenderCategory get renderCategory;
  bool _dirty = true;
  bool updatesNextFrame = false;

  void Function(Canvas canvas, {Vector2 position, Vector2 size}) get renderAlbedo;
  void Function(Canvas canvas, {Vector2 position, Vector2 size})? get renderNormal;

  void setDirty([bool value = true]){
    _dirty = value;
  }

  bool get dirty => _dirty;

  @override
  int get hashCode => Object.hashAll([gridFeetPos, renderCategory]);
}