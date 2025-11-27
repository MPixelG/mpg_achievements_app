import 'dart:async';
import 'dart:math';

import 'package:flame/components.dart';
import 'package:mpg_achievements_app/core/iso_component.dart';
import 'package:mpg_achievements_app/core/physics/hitbox3d/shapes/rectangle_hitbox3d.dart';
import 'package:mpg_achievements_app/core/physics/hitbox3d/shapes/shape_hitbox3d.dart';
import 'package:mpg_achievements_app/mpg_pixel_adventure.dart';


abstract class GameCharacter extends IsoPositionComponent
    with HasGameReference<PixelAdventure> {

  late ShapeHitbox3D hitbox;

  GameCharacter({
    super.position,
    required super.size,
    super.scale,
    super.anchor,
    super.children,
    super.priority,
    super.key,
  });

  Vector3 characterVelocity = Vector3.zero();
  Vector3 get velocity => characterVelocity;
  set velocity(Vector3 val) => characterVelocity = val;
  bool updateMovement = true;
  static const double movementSpeed = 0.3;
  static const double jumpSpeed = 3;

  @override
  FutureOr<void> onLoad() {
    hitbox = RectangleHitbox3D(size: size);
    add(hitbox);
    return super.onLoad();
  }

  @override
  void update(double dt){
    //position is updated here and character(Player) moves in the direction assigned by the variables in the player at the moment
    super.update(dt);
    if(updateMovement) {
      velocity.y -= 0.4;
      velocity.xz *= pow(0.05, dt).toDouble();
      position += velocity * dt * movementSpeed;
    }

  }
}