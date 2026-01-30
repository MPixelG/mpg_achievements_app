import 'package:mpg_achievements_app/3d/src/chunking/chunk/tile_grid.dart';
import 'package:thermion_flutter/thermion_flutter.dart';

class Chunk {
  TileGrid tileGrid = TileGrid();
  
  int lod;
  Vector2 position;
  
  Chunk(this.lod, this.position);
}