import 'dart:ui';

import 'package:flame/components.dart';
import 'package:mpg_achievements_app/components/entity/player.dart';
import 'package:mpg_achievements_app/components/level/isometric/isometric_renderable.dart';

import '../../mpg_pixel_adventure.dart';
import '../level/isometric/isometric_tiled_component.dart';

class IsometricPlayer extends Player with IsometricRenderable{
  IsometricPlayer({required super.playerCharacter}){
    setCustomAnimationName("falling", "running");
    setCustomAnimationName("jumping", "running");
  }

  @override
  Vector2 get gridPos =>
      worldToTileIsometric(absoluteCenter);

  @override
  set gridPos(Vector2 newGridPos) {
    position = (position - absoluteCenter) + toWorldPos(newGridPos);
  }

  Vector2 worldToTileIsometric(Vector2 worldPos) {
    final tileX = (worldPos.x / (tilesize.x / 2) + worldPos.y / (tilesize.z / 2)) / 2;
    final tileY = (worldPos.y / (tilesize.z / 2) - worldPos.x / (tilesize.x / 2)) / 2;

    return Vector2(tileX, tileY);
  }

  Vector2 toWorldPos(Vector2 gridPos) {
    return Vector2(
      (gridPos.x - gridPos.y) * (tilesize.x / 2),
      (gridPos.x + gridPos.y) * (tilesize.z / 2),
    );
  }

  @override
  Vector3 get gridFeetPos {
    Vector2 xYGridPos;
    if(hitbox != null) {
      xYGridPos = game.gameWorld.toGridPos(absoluteCenter);
    } else {
      xYGridPos = game.gameWorld.toGridPos(absoluteCenter);
      print("taking center!");
    }
    return Vector3(xYGridPos.x, xYGridPos.y, 0);
  }

  @override
  RenderCategory get renderCategory => RenderCategory.entity;

  @override
  Vector3 get gridHeadPos => gridFeetPos + Vector3(1, 1, 1);

  @override
  void Function(Canvas canvas, {Vector2 position, Vector2 size}) get renderAlbedo => (Canvas canvas, {Vector2? position, Vector2? size}) {
    Vector2 playerPos = game.gameWorld.toWorldPos(gridFeetPos.xy);
    Vector2 posOffset = (position ?? playerPos) - playerPos;
    canvas.save();
    canvas.translate(posOffset.x, posOffset.y);
    renderTree(canvas);
    canvas.restore();
  };
  @override
  void Function(Canvas canvas, {Vector2? position, Vector2? size}) get renderNormal => (Canvas canvas, {Vector2? position, Vector2? size}) {};
}