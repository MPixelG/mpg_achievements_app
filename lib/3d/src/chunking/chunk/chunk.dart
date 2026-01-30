import 'package:mpg_achievements_app/3d/src/chunking/tiles/tile.dart';
import 'package:thermion_flutter/thermion_flutter.dart';

class Chunk {
  List<Tile> tiles = [];
  
  int lod;
  Vector2 position;
  
  Chunk(this.lod, this.position);
  
  static Future<void> onLoad() async {
    
  }
  
  
}