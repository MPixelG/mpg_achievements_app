import 'package:flame/components.dart';
//A positionComponent can have an x, y , width and height
class CollisionBlock extends PositionComponent{
  //position and size is given and passed in to the PositionComponent with super
  bool isPlatform;
  CollisionBlock({position, size,
  this.isPlatform = false, }):
        super(
          position: position,
          size: size,)
  {debugMode = true;}

}