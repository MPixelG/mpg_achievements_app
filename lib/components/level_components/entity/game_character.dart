import 'dart:math';

import 'package:flame/components.dart';
import 'package:mpg_achievements_app/core/iso_component.dart';
import 'package:mpg_achievements_app/mpg_pixel_adventure.dart';


abstract class GameCharacter extends IsoPositionComponent
    with HasGameReference<PixelAdventure> {

  GameCharacter({
    super.position,
    super.size,
    super.scale,
    super.angle,
    super.nativeAngle,
    super.anchor,
    super.children,
    super.priority,
    super.key,
  });
  Vector2 get gridPos =>
      Vector2(isoPosition.x / tilesize.x, isoPosition.y / tilesize.y);

  set gridPos(Vector2 newGridPos) {
    isoPosition.xy = newGridPos * tilesize.x;
  }

  Vector3 velocity = Vector3.zero();
  bool updateMovement = true;
  static const double movementSpeed = 0.3;


  @override
  void update(double dt){
    if(updateMovement) {
      velocity *= pow(0.05, dt).toDouble();
      velocity.xy.normalized();
      isoPosition += velocity * dt * movementSpeed;
    }
    super.update(dt);
  }

}