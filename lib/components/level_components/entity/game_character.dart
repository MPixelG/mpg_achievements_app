import 'dart:math';

import 'package:flame/components.dart';
import 'package:mpg_achievements_app/core/iso_component.dart';
import 'package:mpg_achievements_app/core/physics/hitbox3d.dart';
import 'package:mpg_achievements_app/mpg_pixel_adventure.dart';


abstract class GameCharacter extends IsoPositionComponent
    with HasGameReference<PixelAdventure> {

  Hitbox3D hitbox;

  GameCharacter({
    super.position,
    required super.size,
    super.scale,
    super.anchor,
    super.children,
    super.priority,
    super.key,
  }) : hitbox = Hitbox3D(
          size: Vector3(
            size.x * 0.5,
            size.y * 0.5,
            size.z,
          ),
        ) {
    add(hitbox);
  }
  Vector2 get gridPos =>
      Vector2(position.x / tilesize.x, position.y / tilesize.y);

  set gridPos(Vector2 newGridPos) {
    position.xy = newGridPos * tilesize.x;
  }

  Vector3 velocity = Vector3.zero();
  bool updateMovement = true;
  static const double movementSpeed = 0.3;


  @override
  void update(double dt){
    //position is updated here and character(Player) moves in the direction assigned by the variables in the player at the moment
    if(updateMovement) {
      velocity *= pow(0.05, dt).toDouble();
      velocity.xy.normalized();
      position += velocity * dt * movementSpeed;
    }
    super.update(dt);
  }
}