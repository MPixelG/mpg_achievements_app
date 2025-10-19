import 'dart:async';
import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart' hide Vector3;
import 'package:mpg_achievements_app/core/iso_component.dart';
import 'package:mpg_achievements_app/mpg_pixel_adventure.dart';
import 'package:mpg_achievements_app/util/render_utils.dart';
import 'package:vector_math/vector_math.dart' show Vector3;

class Hitbox3D extends Component with CollisionCallbacks{
  Vector3 get position => parentPosition + offset;
  Vector3 get secondPosition => position + size;

  Vector3 offset;
  late Vector3 size;

  Vector3 get parentPosition {
    if(parent is IsoPositionComponent) return (parent as IsoPositionComponent).position;
    return Vector3.zero();
  }

  Hitbox3D({Vector3? relativePosition, Vector3? size}) : offset = relativePosition ?? Vector3.zero(), size = size ?? Vector3.all(1);

  @override
  FutureOr<void> onLoad() {
    (findGame() as PixelAdventure).hitboxGrid.addHitbox(this);
  }


  bool intersects(Hitbox3D other) {
    return (position.x < other.secondPosition.x &&
        secondPosition.x > other.position.x &&
        position.y < other.secondPosition.y &&
        secondPosition.y > other.position.y &&
        position.z < other.secondPosition.z &&
        secondPosition.z > other.position.z);
  }

  @override
  void render(Canvas canvas) {
    renderIsoBox(canvas: canvas, start: offset, end: offset + size, originOffset: Offset(size.x / 2, 0));
  }

  @override
  void onRemove() {
    (findGame() as PixelAdventure).hitboxGrid.removeHitbox(this);
    super.onRemove();
  }
}