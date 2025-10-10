import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:flutter/material.dart';
import 'package:mpg_achievements_app/components/level_components/entity/player.dart';
import 'package:mpg_achievements_app/core/iso_component.dart';
import 'package:mpg_achievements_app/core/physics/collision_block.dart';

import '../../../core/level/isometric/isometric_renderable.dart';
import '../../../core/level/isometric/isometric_tiled_component.dart';
import '../../../mpg_pixel_adventure.dart';
import '../../../util/isometric_utils.dart';
import 'isometric_character_shadow.dart';

class IsometricPlayer extends Player {

  @override
  late ShadowComponent shadow;

  IsometricPlayer({required super.playerCharacter}) {
    setCustomAnimationName("falling", "running");
    setCustomAnimationName("jumping", "running");
  }

  @override
  Future<void> onLoad() async {
    shadow = ShadowComponent(owner: this);
    _findGroundBeneath();
    return super.onLoad();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    //save the current state of the canvas
    canvas.save();
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

@override
  Vector3 get gridFeetPos {
    Vector3 actualPos = isoPosition;
    return Vector3(
      actualPos.x + 0.8,
      actualPos.y + 0.8,
      1,
    ); //todo align correctly
  }

  @override
  RenderCategory get renderCategory => RenderCategory.entity;

  @override
  Vector3 get gridHeadPos {
    return isoPosition - Vector3(0, 0, height);
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
  void Function(Canvas canvas, Paint? overridePaint)
  get renderNormal => (Canvas canvas, Paint? overridePaint) {
    normalSprite.render(
      canvas,
      position: isoPosition.xy - Vector2(((scale.x < 0) ? 32 : 0), 0),
    );
    // canvas.drawCircle(toWorldPos(gridFeetPos).toOffset(), 3, Paint()..color = Colors.blue);
    // canvas.drawCircle(toWorldPos(gridHeadPos).toOffset(), 3, Paint()..color = Colors.blue);
  };
}
