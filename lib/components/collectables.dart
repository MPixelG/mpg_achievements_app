import 'dart:async';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:mpg_achievements_app/components/Particles.dart';
import 'package:mpg_achievements_app/components/custom_hitbox.dart';
import 'package:mpg_achievements_app/components/level.dart';
import 'package:mpg_achievements_app/components/player.dart';
import 'package:mpg_achievements_app/mpg_pixel_adventure.dart';

class Collectable extends SpriteAnimationComponent
    with HasGameReference<PixelAdventure>, CollisionCallbacks {

  //name of the collectable and tape of collect -> those will be more than fruit in the future
  final String collectable;
  final String type;
  bool _collected = false;
  final double stepTime = 0.05;
  final hitbox = CustomHitbox(offsetX: 10,
      offsetY: 10,
      width: 12,
      height: 12);

  //constructor
  Collectable({this.collectable = "Apple", this.type = 'Fruits',
    super.position,
    super.size});


  @override
  FutureOr<void> onLoad() {
    priority = -1; // Draw behind other components. default is 0

    add(
      RectangleHitbox(
        position: Vector2(hitbox.offsetX, hitbox.offsetY),
        size: Vector2(hitbox.width, hitbox.height),
        collisionType: CollisionType.passive, // Detects collisions but doesn't block.
      ),
    );
    animation = SpriteAnimation.fromFrameData(
      game.images.fromCache('Items/$type/$collectable.png'),
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
      (parent as Level).totalCollectables--;
      if((parent as Level).totalCollectables == 0) parent?.add(generateConfetti(position));
    }
    Future.delayed(const Duration(milliseconds: 400), () => removeFromParent()); // Remove after animation.
  }
}