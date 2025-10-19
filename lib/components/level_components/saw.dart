import 'dart:async' show FutureOr;

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:mpg_achievements_app/mpg_pixel_adventure.dart';
//todo convert to 3d or remove
@Deprecated("not yet converted to 3d")
class Saw extends SpriteAnimationComponent
    with HasGameReference<PixelAdventure> {
  //how often the animation is rendered
  static const sawRotationSpeed = 0.05;
  static const moveSpeed = 50;
  double moveDirection = 1;
  double rangeNeg = 0;
  double rangePos = 0;
  bool isVertical;
  double offNeg;
  double offPos;

  //constructor
  Saw({
    this.isVertical = false,
    this.offNeg = 0,
    this.offPos = 0,
    super.position,
    super.size,
  });

  @override
  FutureOr<void> onLoad() {
    //move behind the actual game objects
    priority = -1;
    //circle hitbox has the same size like our saws, do we do not need to add a CustomHitbox which correct the
    //size of the hitbox with offset-Values like in the player
    add(CircleHitbox());

    //here we calculate the range of pixels the objects can move from the upper left corner of the obstacle, so you need to
    //add(left border) or subtract(right border) one tilesize for the borders of the movement
    if (isVertical) {
      rangeNeg = position.y - offNeg * tilesize.y + height;
      rangePos = position.y + offPos * tilesize.y - height;
    } else {
      rangeNeg = position.x - offNeg * tilesize.x + width;
      rangePos = position.x + offPos * tilesize.x + width;
    }

    animation = SpriteAnimation.fromFrameData(
      game.images.fromCache('Traps/Saw/On (38x38).png'),
      SpriteAnimationData.sequenced(
        //11 image in the Idle.png
        amount: 8,
        //how ofen should it be animated -> faster because it is good to see the saw move faster
        stepTime: sawRotationSpeed,
        textureSize: Vector2.all(38),
      ),
    );

    return super.onLoad();
  }

  @override
  void update(double dt) {
    if (isVertical) {
      _moveVertical(dt);
    } else {
      _moveHorizontal(dt);
    }
    super.update(dt);
  }

  void _moveVertical(double dt) {
    if (position.y >= rangePos) {
      moveDirection = -1;
      position.y = rangePos;
    } else if (position.y <= rangeNeg) {
      moveDirection = 1;
      position.y = rangeNeg;
    }

    position.y += moveDirection * moveSpeed * dt;
  }

  void _moveHorizontal(double dt) {
    if (position.x >= rangePos) {
      moveDirection = -1;
      position.x = rangePos;
    } else if (position.x <= rangeNeg) {
      moveDirection = 1;
      position.x = rangeNeg;
    }

    position.x += moveDirection * moveSpeed * dt;
  }
}
