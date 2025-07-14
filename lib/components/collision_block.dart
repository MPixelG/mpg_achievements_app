import 'dart:async';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

import '../mpg_pixel_adventure.dart';

//A positionComponent can have an x, y , width and height
class CollisionBlock extends PositionComponent with CollisionCallbacks{
  //position and size is given and passed in to the PositionComponent with super
  bool isPlatform;
  CollisionBlock({position, size, this.isPlatform = false})
    : super(position: position, size: size) {
    debugMode = false;
  }

  @override
  FutureOr<void> onLoad(){
    add(RectangleHitbox(position: Vector2(0, 0) , size: size));
  }
}
