import 'package:mpg_achievements_app/components/entity/player.dart';
import 'package:vector_math/vector_math.dart';

class IsometricPlayer extends Player{
  IsometricPlayer({required super.playerCharacter});

  @override
  Vector2 get gridPos =>
      worldToTileIsometric(position);

  @override
  set gridPos(Vector2 newGridPos) {
    position = toWorldPos(newGridPos);
  }

  Vector2 worldToTileIsometric(Vector2 worldPos) {
    final tileX = (worldPos.x / (game.tilesizeOrtho.x / 2) + worldPos.y / (game.tilesizeOrtho.y / 2)) / 2;
    final tileY = (worldPos.y / (game.tilesizeOrtho.y / 2) - worldPos.x / (game.tilesizeOrtho.x / 2)) / 2;

    return Vector2(tileX, tileY);
  }

  Vector2 toWorldPos(Vector2 gridPos) {
    return Vector2(
      (gridPos.x - gridPos.y) * (game.tilesizeOrtho.x / 2),
      (gridPos.x + gridPos.y) * (game.tilesizeOrtho.y / 2),
    );
  }

}