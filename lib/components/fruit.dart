import 'dart:async';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:mpg_achievements_app/components/custom_hitbox.dart';
import 'package:mpg_achievements_app/components/player.dart';

class Fruit extends SpriteAnimationComponent
    with HasGameReference, CollisionCallbacks {
  final String fruit;
  Fruit({this.fruit = "Apple", position, size})
    : super(position: position, size: size);

  bool _collected = false;
  final double stepTime = 0.05;
  final hitbox = CustomHitbox(offsetX: 10, offsetY: 10, width: 12, height: 12);

  @override
  FutureOr<void> onLoad() {
    priority = -1; // Draw behind other components.

    add(
      RectangleHitbox(
        position: Vector2(hitbox.offsetX, hitbox.offsetY),
        size: Vector2(hitbox.width, hitbox.height),
        collisionType: CollisionType.passive, // Detects collisions but doesn't block.
      ),
    );
    animation = SpriteAnimation.fromFrameData(
      game.images.fromCache('Items/Fruits/$fruit.png'),
      SpriteAnimationData.sequenced(
        amount: 17,
        stepTime: stepTime,
        textureSize: Vector2.all(32),
      ),
    );
    return super.onLoad();
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    if (other is Player) { // Check if the colliding object is the Player.
      collidedWithPlayer();
    }
  }

  void collidedWithPlayer() {
    if (!_collected) {
      animation = SpriteAnimation.fromFrameData(
        game.images.fromCache('Items/Fruits/Collected.png'),
        SpriteAnimationData.sequenced(
          amount: 17,
          stepTime: stepTime,
          textureSize: Vector2.all(32),
          loop: false, // Play collection animation once.
        ),
      );
      _collected = true;
    }
    Future.delayed(const Duration(milliseconds: 400), () => removeFromParent()); // Remove after animation.
  }
}