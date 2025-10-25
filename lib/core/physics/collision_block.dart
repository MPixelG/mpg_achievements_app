import 'dart:async';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:mpg_achievements_app/core/iso_component.dart';
import 'package:mpg_achievements_app/core/physics/hitbox3d/isoCollisionCallbacks.dart';
import 'package:mpg_achievements_app/core/physics/hitbox3d/shapes/rectangle_hitbox3d.dart';
import 'package:mpg_achievements_app/core/physics/hitbox3d/shapes/shape_hitbox3d.dart';
import 'package:mpg_achievements_app/core/physics/isometric_hitbox.dart';
import 'package:mpg_achievements_app/mpg_pixel_adventure.dart';

//A positionComponent can have an x, y , width and height, zPosition and zHeight
class CollisionBlock extends IsoPositionComponent
    with IsoCollisionCallbacks, HasGameReference<PixelAdventure> {
  //position and size is given and passed in to the PositionComponent with super

  ShapeHitbox3D hitbox;

  CollisionBlock({
    super.position,
    required super.size,
  }) : hitbox = RectangleHitbox3D(size: size);


  @override
  FutureOr<void> onLoad() {
    //hitbox.collisionType = CollisionType.active;
    add(hitbox);
  }
}
