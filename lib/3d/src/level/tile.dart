
// concrete instance of a tile in the world with coordinates
class TileInstance {
  final int x; // Absolute X coordinate  can also be negative
  final int y; // Absolute Y coordinate
  final int gid;

  /*be aware

Tiled.X -> 3D.X

Tiled.Y -> 3D.Z

Layer Index -> 3D.Y*/

  TileInstance(
      this.x,
      this.y,
      this.gid);
}

class LevelTile {
  final int id;
  final String? modelPath;
  final Map<String, dynamic> properties;

  LevelTile({
    required this.id,
    this.modelPath,
    required this.properties});
}
