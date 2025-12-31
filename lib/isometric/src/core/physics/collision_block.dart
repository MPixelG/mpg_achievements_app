import 'dart:async';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:mpg_achievements_app/isometric/src/core/iso_component.dart';
import 'package:mpg_achievements_app/isometric/src/core/math/iso_anchor.dart';
import 'package:mpg_achievements_app/isometric/src/core/physics/hitbox3d/iso_collision_callbacks.dart';
import 'package:mpg_achievements_app/isometric/src/core/physics/hitbox3d/shapes/rectangle_hitbox3d.dart';
import 'package:mpg_achievements_app/isometric/src/core/physics/hitbox3d/shapes/shape_hitbox3d.dart';
import 'package:mpg_achievements_app/isometric/src/mpg_pixel_adventure.dart';

//A positionComponent can have an x, y , width and height, zPosition and zHeight
class CollisionBlock extends IsoPositionComponent
    with IsoCollisionCallbacks, HasGameReference<PixelAdventure> {
  //position and size is given and passed in to the PositionComponent with super

  ShapeHitbox3D hitbox;

  CollisionBlock({
    super.position,
    required super.size,
    super.anchor = Anchor3D.bottomLeftLeft
  }) : hitbox = RectangleHitbox3D(size: size);


  @override
  FutureOr<void> onLoad() {
    hitbox.collisionType = CollisionType.passive;
    print("position: $position, size: $size");
    add(hitbox);
  }
}