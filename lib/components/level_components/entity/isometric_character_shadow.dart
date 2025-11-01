import 'dart:async';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:mpg_achievements_app/components/level_components/entity/player.dart';
import 'package:mpg_achievements_app/core/iso_component.dart';
import 'package:mpg_achievements_app/mpg_pixel_adventure.dart';

class ShadowComponent extends IsoPositionComponent {
  Player get owner => parent as Player;

  ShadowComponent([int priority = -1]) : super(size: defaultSize) {
    this.priority = priority;
    position = Vector3.zero();
  }

  @override
  FutureOr<void> onLoad() {
    assert(parent is Player, 'ShadowComponent must be added to an Player');
    return super.onLoad();
  }

  @override
  void update(double dt) {
    //anchor = Anchor3D(0, owner.position.z - owner.zGround, 0);
    super.update(dt);
  }

  @override
  void render(Canvas canvas, [Canvas? normalCanvas, Paint Function()? getNormalPaint]) {
    // Convert the selected tile's grid coordinates into its center position in the isometric world.

    final Vector2 shadowSize = Vector2(tilesize.x/1.2, tilesize.z/1.5);
    // Define the four points
    final rect = Rect.fromCenter(
        center: Offset(0, owner.size.y * 32 - (shadowSize.y / 2)),
        width: shadowSize.x,
        height: shadowSize.y);

    // Define a paint for the highlight.
    final highlightPaint = Paint()
      ..color = Colors.black38 // Semi-transparent black
      ..style = PaintingStyle.fill;

    // Draw the oval inside the rectangle
    canvas.drawOval(rect, highlightPaint);
    super.render(canvas);
  }

  static final Vector3 defaultSize = Vector3(1, 0.1, 1);
}
