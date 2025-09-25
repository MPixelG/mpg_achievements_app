import 'package:flame/components.dart';
import 'package:mpg_achievements_app/components/entity/isometric_character_shadow.dart';
import 'package:mpg_achievements_app/components/entity/player.dart';
import 'package:mpg_achievements_app/components/level/isometric/isometric_renderable.dart';

import '../../mpg_pixel_adventure.dart';
import '../level/isometric/isometric_tiled_component.dart';

class IsometricPlayer extends Player with IsometricRenderable{

  late ShadowComponent shadow;

  IsometricPlayer({required super.playerCharacter}){
    setCustomAnimationName("falling", "running");
    setCustomAnimationName("jumping", "running");
  }

  @override
  Future<void> onLoad() async {
    shadow = ShadowComponent(owner: this);
    add(shadow);
    return super.onLoad();
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
    Vector2 xYGridPos = game.gameWorld.toGridPos(absolutePositionOfAnchor(Anchor.topCenter));
    return Vector3(xYGridPos.x, xYGridPos.y, 1);
  }

  @override
  RenderCategory get renderCategory => RenderCategory.entity;


}