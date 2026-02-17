import 'dart:async';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:mpg_achievements_app/3d/src/components/position_component_3d.dart';
import 'package:mpg_achievements_app/3d/src/game.dart';
import 'package:mpg_achievements_app/core/physics/hitbox3d/util/viewer_debug_capabilities.dart';
import 'package:mpg_achievements_app/isometric/src/core/math/iso_anchor.dart';
import 'hitbox3d/collision_callbacks3D.dart';
import 'hitbox3d/shapes/rectangle_hitbox3d.dart';
import 'hitbox3d/shapes/shape_hitbox3d.dart';

//A positionComponent can have an x, y , width and height, zPosition and zHeight
class CollisionBlock3D extends PositionComponent3d
    with CollisionCallbacks3D, ThermionDebugVisual {

  //position and size is given and passed in to the PositionComponent with super
  ShapeHitbox3D hitbox;

  CollisionBlock3D({
    super.position,
    required super.size,
    super.anchor = Anchor3D.bottomCenter,
  }) : hitbox = RectangleHitbox3D(size: size);


  @override
  FutureOr<void> onLoad() async  {
    await super.onLoad();
    hitbox.collisionType = CollisionType.passive;
    print("position: $position, size: $size");
    add(hitbox);
    await enableDebugVisual(thermion!);
    }

 }