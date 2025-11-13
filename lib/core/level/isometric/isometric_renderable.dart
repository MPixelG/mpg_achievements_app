import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';

// A mixin for components that can be rendered in an isometric view.
mixin IsometricRenderable {
  Vector3 get gridFeetPos;
  Vector3 get gridHeadPos;

  bool _dirty = true;
  bool updatesNextFrame = false;

  void renderTree(Canvas albedoCanvas, [Canvas? normalCanvas, Paint Function()? getNormalPaint]);

  void setDirty([bool value = true]) {
    _dirty = value;
  }

  bool get dirty => _dirty;

  @override
  int get hashCode => Object.hashAll([gridFeetPos]);
}

double depth(IsometricRenderable? renderable){
  if(renderable == null) return 0;
  final double feetLength = Vector3.copy(renderable.gridFeetPos).length;
  final double headLength = Vector3.copy(renderable.gridHeadPos).length;

  return min(feetLength, headLength);
}