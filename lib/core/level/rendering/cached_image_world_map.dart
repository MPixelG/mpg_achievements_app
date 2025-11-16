import 'dart:ui';

import 'package:flame/components.dart';

class CachedImageWorldMap {
  Image? image;
  Vector2 get capturedSize => Vector2(image?.width.toDouble() ?? 0, image?.height.toDouble() ?? 0);
  double upscaleFactor;
  int extendPixels;

  Vector2 camPos;
  double zoom;

  double get width => image?.width.toDouble() ?? 0;
  double get height => image?.height.toDouble() ?? 0;

  CachedImageWorldMap({
    this.image,
    Vector2? camPos,
    this.zoom = 1.0,
    this.upscaleFactor = 1.0,
    this.extendPixels = 0,
  }) : camPos = camPos ?? Vector2.zero();

  void dispose() {
    image?.dispose();
    image = null;
  }
}