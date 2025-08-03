import 'dart:async';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:mpg_achievements_app/components/particles/Particles.dart';
import 'package:mpg_achievements_app/components/level.dart';
import 'package:mpg_achievements_app/components/player.dart';
import 'package:mpg_achievements_app/mpg_pixel_adventure.dart';

class Collectable extends SpriteAnimationComponent
    with HasGameReference<PixelAdventure>, CollisionCallbacks {
  //name of the collectable and tape of collect -> those will be more than fruit in the future
  late String collectable;
  bool _collected = false;
  final bool animated;
  late final int amount;
  final bool interactiveTask;
  String collectablePath;
  final double stepTime = 0.05;
  final hitbox = RectangleHitbox(
    position: Vector2(10, 10),
    size: Vector2(12, 12),
    collisionType:
        CollisionType.passive, // Detects collisions but doesn't block.
  );

  //constructor
  Collectable({
    required this.collectable,
    required this.interactiveTask,
    required this.collectablePath,
    required this.animated,
    super.position,
    super.size,
  });

  static final List<String> collectableNames = [
    "Apple",
    "Bananas",
    "Cherries",
    "Kiwi",
    "Melon",
    "Orange",
    "Pineapple",
    "Strawberry",
  ];

  @override
  FutureOr<void> onLoad() {
    priority = 1; // Draw behind other components. default is 0
    if (animated) {
      amount = 17;
    } else {
      amount = 1;
    }

    if (collectable == "") {
      collectable = collectableNames.random();
    }

    add(hitbox);
    animation = SpriteAnimation.fromFrameData(
      game.images.fromCache('$collectablePath/$collectable.png'),
      SpriteAnimationData.sequenced(
        amount: amount,
        stepTime: stepTime,
        textureSize: Vector2.all(32),
        loop: animated,
      ),
    );
    return super.onLoad();
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);
    if (other is Player && !interactiveTask) {
      // Check if the colliding object is the Player.
      collidedWithPlayer();
    }
  }

  void collidedWithPlayer() {
    if (!_collected && !interactiveTask) {
      animation = SpriteAnimation.fromFrameData(
        game.images.fromCache('Items/Fruits/Collected.png'),
        SpriteAnimationData.sequenced(
          amount: 5,
          stepTime: stepTime,
          textureSize: Vector2.all(32),
          loop: false, // Play collection animation once.
        ),
      );
      _collected = true;
      (parent as Level).totalCollectables--;
      if ((parent as Level).totalCollectables == 0) {
        parent?.add(generateConfetti(position));
      }
      Future.delayed(
        const Duration(milliseconds: 400),
        () => removeFromParent(),
      ); // Remove after animation.
    } else if(interactiveTask && !_collected) {
      (parent as Level).totalCollectables--;
      _collected = true;
      if ((parent as Level).totalCollectables == 0) {
        parent?.add(generateConfetti(position));
      }
    }
  }
}
