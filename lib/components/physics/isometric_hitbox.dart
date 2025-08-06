import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class IsometricRectangleHitbox extends RectangleHitbox {
  IsometricRectangleHitbox({
    Vector2? size,
    Vector2? position,
    double? angle,
    Anchor? anchor,
  }) : super(
    size: size,
    position: position,
    angle: angle,
    anchor: anchor,
  );

  @override
  bool containsPoint(Vector2 point) {
    Vector2 localPoint = absoluteToLocal(point);
    Vector2 center = size / 2;

    double dx = (localPoint.x - center.x).abs();
    double dy = (localPoint.y - center.y).abs();

    return (dx / center.x + dy / center.y) <= 1.0;
  }

  bool intersectsWithDiamond(IsometricRectangleHitbox other) {
    List<Vector2> axesThis = _getDiamondAxes();
    List<Vector2> axesOther = other._getDiamondAxes();

    List<Vector2> verticesThis = getDiamondVertices();
    List<Vector2> verticesOther = other.getDiamondVertices();

    for (Vector2 axis in [...axesThis, ...axesOther]) {
      if (_separatingAxisTest(axis, verticesThis, verticesOther)) {
        return false; // Separating axis found
      }
    }

    return true; // No separating axis found, they intersect
  }

  List<Vector2> getDiamondVertices() {
    Vector2 center = absoluteCenter;
    double halfWidth = size.x / 2;
    double halfHeight = size.y / 2;

    return [
      Vector2(center.x, center.y - halfHeight),
      Vector2(center.x + halfWidth, center.y),
      Vector2(center.x, center.y + halfHeight),
      Vector2(center.x - halfWidth, center.y),
    ];
  }

  List<Vector2> _getDiamondAxes() {
    return [
      Vector2(1, 1).normalized(),
      Vector2(1, -1).normalized(),
    ];
  }

  bool _separatingAxisTest(Vector2 axis, List<Vector2> vertices1, List<Vector2> vertices2) {
    List<double> proj1 = vertices1.map((v) => v.dot(axis)).toList();
    List<double> proj2 = vertices2.map((v) => v.dot(axis)).toList();

    double min1 = proj1.reduce((a, b) => a < b ? a : b);
    double max1 = proj1.reduce((a, b) => a > b ? a : b);
    double min2 = proj2.reduce((a, b) => a < b ? a : b);
    double max2 = proj2.reduce((a, b) => a > b ? a : b);

    return max1 < min2 || max2 < min1;
  }

  Path asPath() {
    return Path()
      ..moveTo(0, 0)
      ..lineTo(size.x, center.y)
      ..lineTo(center.x, size.y)
      ..lineTo(0, center.y)
      ..close();
  }

  @override
  void renderDebugMode(Canvas canvas) {
    canvas.drawPath(asPath(), paint);
    canvas.drawCircle(position.toOffset(), 5, paint);
  }

  static bool pointInDiamond(Vector2 point, Vector2 center, Vector2 size) {
    double dx = (point.x - center.x).abs();
    double dy = (point.y - center.y).abs();
    return (dx / (size.x/2) + dy / (size.y/2)) <= 1.0;
  }
}