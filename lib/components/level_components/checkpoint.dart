import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:mpg_achievements_app/components/player.dart';
import 'package:mpg_achievements_app/mpg_pixel_adventure.dart';

class Checkpoint extends SpriteComponent
    with HasGameReference<PixelAdventure>, CollisionCallbacks {
  final int id;
  bool isActivated;

  Checkpoint({required this.id, this.isActivated = false, super.position});

  @override
  Future<void> onLoad() async {
    sprite = await game.loadSprite('objects/Flag.png');
    size = Vector2(32, 64);
    anchor = Anchor.center;

    add(RectangleHitbox()..collisionType = CollisionType.passive);

    return super.onLoad();
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);

    if (!isActivated && other is Player) {
      if (other.lastCheckpoint.id < id) {
        isActivated = true;
        other.lastCheckpoint = this;

        print('Checkpoint $id aktiviert!');
      }
    }
  }
}
