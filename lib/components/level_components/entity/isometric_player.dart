import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:flutter/material.dart';
import 'package:mpg_achievements_app/components/level_components/entity/player.dart';
import 'package:mpg_achievements_app/core/physics/collision_block.dart';

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
    _findGroundBeneath();


    return super.onLoad();
  }


  //find the highest ground block beneath the player and set the zGround to its zPosition + zHeight
  void _findGroundBeneath() {
    // the highest ground block beneath the player
    final blocks = game.gameWorld.children.whereType<CollisionBlock>();
    //print("number of blocks: ${blocks.length}");
    double highestZ = 0.0; //default floor
    //the players foot rectangle which mesn easier collision detection with the block
    final playerFootRectangle = Rect.fromCenter(
      center: absolutePositionOfAnchor(Anchor.bottomCenter).toOffset(),
      width: size.x, //maybe adjust necessary for debugging
      height: 4.0, //thin slice is sufficient
    );

    for (final block in blocks) {
      //make a rectangle from the block position and size
      final blockGroundRectangle = block.toRect();
      if (playerFootRectangle.overlaps(blockGroundRectangle)) {
        //what is it ground and what is the zHeight of the block;
        final blockCeiling = block.zPosition! + block.zHeight!;
        if (blockCeiling > highestZ) {
          highestZ = blockCeiling.toDouble();
          //print('blockceiling:$blockCeiling');
        }
      }
    }
    zGround = highestZ;
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
    Vector2 xYGridPos = toGridPos(absoluteCenter);
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
        // canvas.drawCircle(toWorldPos(gridFeetPos).toOffset(), 3, Paint()..color = Colors.blue);
        // canvas.drawCircle(toWorldPos(gridHeadPos).toOffset(), 3, Paint()..color = Colors.blue);
      };
}
