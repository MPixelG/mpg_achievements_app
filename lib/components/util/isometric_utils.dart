import 'package:mpg_achievements_app/components/level/rendering/chunk.dart';
import 'package:vector_math/vector_math.dart';

import '../../mpg_pixel_adventure.dart';

Vector2 toWorldPos(Vector3 gridPos, [double? levelWidth]) {
  final localPoint = Vector2(
    (gridPos.x - gridPos.y) * (tilesize.x / 2),
    (gridPos.x + gridPos.y) * (tilesize.z / 2),
  );
  // Convert local point to global world position, Add the maps's visual origin offset back to the local point
  // to get the correct world position
  final offset = Vector2(
    (levelWidth ?? Chunk.worldSize.x) / 2, //map origin
    -gridPos.z * (tilesize.z), //height offset
  );
  //apply vertical movement for different layers according to z-index
  return localPoint + offset;
}

Vector2 toGridPos(Vector2 worldPos, [double? levelWidth]) {
  return worldToTileIsometric(
    worldPos -
        Vector2((levelWidth ?? Chunk.worldSize.x) / 2, 0)
  ) +
      Vector2(1, 1);
}
// Convert world position to isometric tile coordinates used in toGridPos
Vector2 worldToTileIsometric(Vector2 worldPos) {
  final tileX =
      (worldPos.x / (tilesize.x / 2) + worldPos.y / (tilesize.z / 2)) / 2;
  final tileY =
      (worldPos.y / (tilesize.z / 2) - worldPos.x / (tilesize.x / 2)) / 2;

  return Vector2(tileX, tileY);
}

Vector2 isoToScreen(Vector2 iso) {
  return Vector2(
    (iso.x - iso.y) * tilesize.x / 2,
    (iso.x + iso.y) * tilesize.z / 2,
  );
}