import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:mpg_achievements_app/mpg_pixel_adventure.dart';

import 'isometric_tiled_component.dart';

/// A mixin for components that can be rendered in an isometric view.
mixin IsometricRenderable {
  Vector3 get gridFeetPos;
  Vector3 get gridHeadPos;

  RenderCategory get renderCategory;
  bool _dirty = true;
  bool updatesNextFrame = false;

  void Function(Canvas canvas) get renderAlbedo;
  void Function(Canvas canvas, Paint? overridePaint)? get renderNormal;

  void setDirty([bool value = true]) {
    _dirty = value;
  }

  bool get dirty => _dirty;

  @override
  int get hashCode => Object.hashAll([gridFeetPos, renderCategory]);
}

double depth(IsometricRenderable? renderable){
  if(renderable == null) return 0;
  double feetLength = Vector3(renderable.gridFeetPos.x, renderable.gridFeetPos.y, renderable.gridFeetPos.z).length;
  double headLength = Vector3(renderable.gridHeadPos.x, renderable.gridHeadPos.y, renderable.gridHeadPos.z).length;

  return max(feetLength, headLength);
}