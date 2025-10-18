import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

import '../../util/isometric_utils.dart';

class IsometricHitbox extends PolygonHitbox {
  IsometricHitbox(Vector2 size, Vector3 offset)
    : super(
        [
          toWorldPos(offset, 0),
          toWorldPos(Vector3(size.x, 0, 0) + offset, 0),
          toWorldPos(Vector3(size.x, size.y, 0) + offset, 0),
          toWorldPos(Vector3(0, size.y, 0) + offset, 0),
        ],
        anchor: Anchor.topLeft,
        isSolid: true,
      );
}