import 'dart:math';

import 'package:vector_math/vector_math.dart';

import '../../core/level/rendering/chunk.dart';
import '../../mpg_pixel_adventure.dart';

Vector2 toWorldPos(Vector3 gridPos, [double? levelWidth, Vector3? tileSizeOverride]) {
  final localPoint = Vector2(
    (gridPos.x - gridPos.y) * ((tileSizeOverride ?? tilesize).x / 2),
    (gridPos.x + gridPos.y) * ((tileSizeOverride ?? tilesize).z / 2),
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
Vector2 toWorldPos2D(Vector2 gridPos, [double? levelWidth]) {
  final localPoint = Vector2(
    (gridPos.x - gridPos.y) * (tilesize.x / 2),
    (gridPos.x + gridPos.y) * (tilesize.z / 2),
  );
  // Convert local point to global world position, Add the maps's visual origin offset back to the local point
  // to get the correct world position
  final offset = Vector2(
    (levelWidth ?? Chunk.worldSize.x) / 2, //map origin
    0, //height offset
  );
  //apply vertical movement for different layers according to z-index
  return localPoint + offset;
}

Vector2 toGridPos(Vector2 worldPos, [double? levelWidth]) {
  return worldToTileIsometric(
        worldPos - Vector2((levelWidth ?? Chunk.worldSize.x) / 2, 0),
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

Vector2 isoToScreen(Vector3 iso) {
  return Vector2(
    (iso.x - iso.y) / 2,
    (iso.x + iso.y) / 4,
  );
}

@pragma('vm:prefer-inline')
Vector2 quickConvertSize3dTo2d(Vector3 size) {
  return Vector2(
      (size.x + size.z) * 0.866025403784*0.5,
      size.y + (size.x + size.z) * 0.25
  );
}

Vector2 project(Vector3 p, double scaleX, double scaleY, double zScale) {
  double sx = (p.x - p.y) * scaleX;
  double sy = (p.x + p.y) * scaleY - p.z * zScale;
  return Vector2(sx, sy);
}

Vector2 projectedBounds(Vector3 size, double scaleX, double scaleY, double zScale) {
  List<Vector3> corners = [
    Vector3(-size.x/2, -size.y/2, 0),
    Vector3(size.x/2, -size.y/2, 0),
    Vector3(-size.x/2, size.y/2, 0),
    Vector3(size.x/2, size.y/2, 0),
    Vector3(-size.x/2, -size.y/2, size.z),
    Vector3(size.x/2, -size.y/2, size.z),
    Vector3(-size.x/2, size.y/2, size.z),
    Vector3(size.x/2, size.y/2, size.z),
  ];
  double minX = double.infinity, minY = double.infinity;
  double maxX = double.negativeInfinity, maxY = double.negativeInfinity;
  for (var c in corners) {
    var s = project(c, scaleX, scaleY, zScale);
    minX = min(minX, s.x); minY = min(minY, s.y);
    maxX = max(maxX, s.x); maxY = max(maxY, s.y);
  }
  return Vector2(maxX - minX, maxY - minY);
}