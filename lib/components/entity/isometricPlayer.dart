import 'package:mpg_achievements_app/components/entity/player.dart';
import 'package:vector_math/vector_math.dart';

import '../../mpg_pixel_adventure.dart';

class IsometricPlayer extends Player{
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

}