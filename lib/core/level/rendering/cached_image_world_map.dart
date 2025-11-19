import 'dart:ui';

import 'package:flame/components.dart';

class CachedImageWorldMap {
  Image image;
  Vector2 get capturedSize => Vector2(image.width.toDouble(), image.height.toDouble());
  double upscaleFactor;
  int extendPixels;

  Vector2 pos;
  double zoom;

  double get width => image.width.toDouble();
  double get height => image.height.toDouble();

  CachedImageWorldMap({
    required this.image,
    Vector2? camPos,
    this.zoom = 1.0,
    this.upscaleFactor = 1.0,
    this.extendPixels = 0,
  }) : pos = camPos ?? Vector2.zero();

  void dispose() {
    image.dispose();
  }
}