import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:mpg_achievements_app/components/entity/isometric_character_shadow.dart';
import 'package:mpg_achievements_app/components/entity/player.dart';

import '../../core/level/isometric/isometric_renderable.dart';
import '../../core/level/isometric/isometric_tiled_component.dart';
import '../../mpg_pixel_adventure.dart';
import '../util/isometric_utils.dart';

class IsometricPlayer extends Player with IsometricRenderable{

  late PositionComponent shadowAnchor;

  IsometricPlayer({required super.playerCharacter}){
    setCustomAnimationName("falling", "running");
    setCustomAnimationName("jumping", "running");
  }

  @override
  Future<void> onLoad() async {
    shadowAnchor = PositionComponent(position:  Vector2(0,height/2));
    add(shadowAnchor);
    shadow = ShadowComponent(owner: this); //removable when positioning is correct
    shadow.anchor = Anchor.center;
    return super.onLoad();
  }

  @override
  Vector2 get gridPos => worldToTileIsometric(absoluteCenter);

  @override
  set gridPos(Vector2 newGridPos) {
    position = (position - absoluteCenter) + toWorldPos(newGridPos);
  }

  Vector2 worldToTileIsometric(Vector2 worldPos) {
    final tileX =
        (worldPos.x / (tilesize.x / 2) + worldPos.y / (tilesize.z / 2)) / 2;
    final tileY =
        (worldPos.y / (tilesize.z / 2) - worldPos.x / (tilesize.x / 2)) / 2;

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
    if (hitbox != null) {
      xYGridPos = toGridPos(absoluteCenter) - Vector2(1, 1);
    } else {
      xYGridPos = toGridPos(absoluteCenter);
    }
    return Vector3(xYGridPos.x, xYGridPos.y, 1);
  }

  @override
  RenderCategory get renderCategory => RenderCategory.entity;

  @override
  Vector3 get gridHeadPos => gridFeetPos + Vector3(1, 1, 1);

  @override
  void Function(Canvas canvas) get renderAlbedo => (Canvas canvas) {
    renderTree(canvas);
  };
  Sprite normalSprite = Sprite(Flame.images.fromCache("playerNormal.png"), srcSize: tilesize.xy, srcPosition: Vector2.zero());
  @override
  void Function(Canvas canvas, Paint? overridePaint) get renderNormal =>
      (Canvas canvas, Paint? overridePaint) {
        normalSprite.render(canvas, position: position - Vector2(((scale.x < 0) ? 32 : 0), 0));
      };
}
