import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:flutter/material.dart';
import 'package:mpg_achievements_app/components/level_components/entity/player.dart';

import '../../../core/level/isometric/isometric_renderable.dart';
import '../../../core/level/isometric/isometric_tiled_component.dart';
import '../../../mpg_pixel_adventure.dart';
import '../../../util/isometric_utils.dart';
import 'isometric_character_shadow.dart';

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
  void render(Canvas canvas){
    //save the current state of the canvas
    canvas.save();

    //only move drawing position not ground position
    canvas.translate(0, isoPosition.z);

    //call original renderer
    super.render(canvas);

    //restore canvas, important because of other components rendering. If you do not
    //restore other components will incorrectly be offset
    canvas.restore();
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
    return isoPosition;
  }

  @override
  RenderCategory get renderCategory => RenderCategory.entity;

  @override
  Vector3 get gridHeadPos {
    return isoPosition - Vector3(0,0, height);
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
        normalSprite.render(canvas, position: isoPosition.xy - Vector2(((scale.x < 0) ? 32 : 0), 0));
        // canvas.drawCircle(toWorldPos(gridFeetPos).toOffset(), 3, Paint()..color = Colors.blue);
        // canvas.drawCircle(toWorldPos(gridHeadPos).toOffset(), 3, Paint()..color = Colors.blue);
      };
}
