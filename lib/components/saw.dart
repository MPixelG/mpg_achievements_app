import 'dart:async' show FutureOr;
import 'package:flame/components.dart';
import 'package:mpg_achievements_app/mpg_pixel_adventure.dart';

class Saw extends SpriteAnimationComponent with HasGameReference<PixelAdventure>{

  //how often the animation is rendered
  static const sawRotationSpeed = 0.05;
  static const moveSpeed = 50;
  static const tileSize = 16;
  double moveDirection = 1;
  double rangeNeg = 0;
  double rangePos = 0;
    bool isVertical;
  double offNeg;
  double offPos;

  //constructor
  Saw({this.isVertical =false, this.offNeg = 0,this.offPos = 0, super.position, super.size});


@override
  FutureOr<void> onLoad() {
//move behind the actual game objects
    priority = -1;

    //here we calculate the range of pixels the objects can move from the upper left corner of the obstacle, so you need to
    //add(move left) or subtract(move right) one tilesize for the borders of the movement
    if(isVertical){
      rangeNeg = position.y - offNeg * tileSize;
      rangePos = position.y + offPos * tileSize;
    } else
    {rangeNeg = position.x - offNeg * tileSize;
    rangePos = position.x + offNeg * tileSize;}


    animation = SpriteAnimation.fromFrameData(game.images.fromCache('Traps/Saw/On (38x38).png'), SpriteAnimationData.sequenced(
      //11 image in the Idle.png
      amount: 8,
      //how ofen should it be animated -> faster because it is good to see the saw move faster
      stepTime: sawRotationSpeed,
      textureSize: Vector2.all(38),
    ));

    return super.onLoad();
  }

  }







