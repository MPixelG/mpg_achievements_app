import 'package:mpg_achievements_app/3d/src/level/tile.dart';

class TiledLayer {
  final String name; //width and height not b´necessary anymore because of infinity
  final List<TileInstance> activeTiles; // list of all active tiles

  TiledLayer({
    required this.name,
    required this.activeTiles,
  });
}