import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:flutter/material.dart';
import 'package:mpg_achievements_app/components/entity/isometric_character_shadow.dart';
import 'package:mpg_achievements_app/components/entity/player.dart';

import '../../core/level/isometric/isometric_renderable.dart';
import '../../core/level/isometric/isometric_tiled_component.dart';
import '../../mpg_pixel_adventure.dart';
import '../util/isometric_utils.dart';

class IsometricPlayer extends Player with IsometricRenderable {
  late PositionComponent shadowAnchor;

  IsometricPlayer({required super.playerCharacter}) {
    setCustomAnimationName("falling", "running");
    setCustomAnimationName("jumping", "running");
  }

  @override
  Future<void> onLoad() async {
    shadowAnchor = PositionComponent(position: Vector2(0, height / 2));
    add(shadowAnchor);
    shadow = ShadowComponent(
      owner: this,
    ); //removable when positioning is correct
    shadow.anchor = Anchor.center;
    return super.onLoad();
  }

  @override
  Vector2 get gridPos => worldToTileIsometric(absoluteCenter);

  @override
  set gridPos(Vector2 newGridPos) {
    position = (position - absoluteCenter) + toWorldPos2D(newGridPos, 0);
  }

  Vector2 worldToTileIsometric(Vector2 worldPos) {
    final tileX =
        (worldPos.x / (tilesize.x / 2) + worldPos.y / (tilesize.z / 2)) / 2;
    final tileY =
        (worldPos.y / (tilesize.z / 2) - worldPos.x / (tilesize.x / 2)) / 2;

    return Vector2(tileX, tileY);
  }

  @override
  Vector3 get gridFeetPos {
    Vector2 xYGridPos;
    if (hitbox != null) {
      xYGridPos = toGridPos(absoluteCenter);
    } else {
      xYGridPos = toGridPos(absoluteCenter);
    }
    return Vector3(xYGridPos.x, xYGridPos.y, 1);
  }

  @override
  RenderCategory get renderCategory => RenderCategory.entity;

  @override
  Vector3 get gridHeadPos {
    return gridFeetPos + Vector3(0.8, 0.8, 1);
  }

  @override
  void Function(Canvas canvas) get renderAlbedo => (Canvas canvas) {
    renderTree(canvas);
    //canvas.drawCircle(toWorldPos(gridHeadPos).toOffset(), 4, Paint()..color = Colors.red);
    //canvas.drawCircle(toWorldPos(gridFeetPos).toOffset(), 2, Paint()..color = Colors.yellow);
  };
  Sprite normalSprite = Sprite(
    Flame.images.fromCache("playerNormal.png"),
    srcSize: tilesize.xy,
    srcPosition: Vector2.zero(),
  );
  @override
  void Function(Canvas canvas, Paint? overridePaint) get renderNormal =>
      (Canvas canvas, Paint? overridePaint) {
        normalSprite.render(canvas, position: position - Vector2(((scale.x < 0) ? 32 : 0), 0));
        canvas.drawCircle(toWorldPos(gridFeetPos).toOffset(), 3, Paint()..color = Colors.blue);
        canvas.drawCircle(toWorldPos(gridHeadPos).toOffset(), 3, Paint()..color = Colors.blue);
      };
}
