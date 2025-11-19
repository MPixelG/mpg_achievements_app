import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';

// A mixin for components that can be rendered in an isometric view.
mixin IsometricRenderable {
  Vector3 get gridFeetPos;
  Vector3 get gridHeadPos;

  Vector3 get size => gridHeadPos - gridFeetPos;

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
  final Vector3 feet = renderable.gridFeetPos;
  final Vector3 head = renderable.gridHeadPos;
  final double feetLength = Vector3.copy(renderable.gridFeetPos).length;
  final double feetLength2 = Vector3(head.x, feet.y, head.z).length;
  final double headLength = Vector3.copy(renderable.gridHeadPos).length;
  final double headLength2 = Vector3(feet.x, head.y, feet.z).length;


  return min(min(feetLength, feetLength2), min(headLength, headLength2));
}