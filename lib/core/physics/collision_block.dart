import 'dart:async';
import 'dart:ui';


import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:mpg_achievements_app/core/iso_component.dart';
import 'package:mpg_achievements_app/core/math/iso_anchor.dart';
import 'package:mpg_achievements_app/core/physics/hitbox3d/iso_collision_callbacks.dart';
import 'package:mpg_achievements_app/core/physics/hitbox3d/shapes/rectangle_hitbox3d.dart';
import 'package:mpg_achievements_app/core/physics/hitbox3d/shapes/shape_hitbox3d.dart';
import 'package:mpg_achievements_app/mpg_pixel_adventure.dart';
import 'package:mpg_achievements_app/util/render_utils.dart';

import '../../util/isometric_utils.dart';

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
    add(hitbox);
  }

  @override
  void render(Canvas canvas, [Canvas? normalCanvas, Paint Function()? getNormalPaint]) {
    super.render(canvas);

    final aabbMin = hitbox.aabb.min;
    final aabbMax = hitbox.aabb.max;
    final aabbSize = aabbMax - aabbMin;

    // print('=== CollisionBlock Debug ===');
    // print('Position: $position');
    // print('Size: $size');
    // print('Anchor: $anchor');
    // print('Hitbox Anchor: ${hitbox.anchor}');
    // print('Absolute Position: $absolutePosition');
    // print('Hitbox absolutePosition: ${hitbox.absolutePosition}');
    // print('Hitbox absoluteBottomLeftLeft: ${hitbox.absolutePositionOfAnchor(Anchor3D.bottomLeftLeft)}');
    // print('AABB Min: $aabbMin');
    // print('AABB Max: $aabbMax');
    // print('Transform offset: ${transform.offset}');
    drawIsometricBox(
        canvas,
        aabbMin - absolutePosition,
        aabbSize,
        edgePaint: Paint()..color = Colors.red..strokeWidth = 2.0
    );

    final screenPos = toWorldPos(absolutePosition);
    canvas.drawCircle(
        Offset(screenPos.x, screenPos.y),
        5,
        Paint()..color = Colors.yellow
    );
  }
}