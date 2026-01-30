import 'package:mpg_achievements_app/3d/src/chunking/tiles/tile_data.dart';
import 'package:mpg_achievements_app/3d/src/chunking/tiles/tile_provider.dart';
import 'package:thermion_flutter/thermion_flutter.dart';

class Tile {
  late ThermionAsset asset;
  Vector3 position;
  
  Tile(String shape, String texture, this.position) {
    initAsset(shape, texture); //todo add check until asset isnt null anymore
  }
  
  
  void initAsset(String shape, String texture) async {
    asset = await (await TileProvider.getParentAssetOfTileType(TileData(shape, texture))).provideTileAsset();
  }
}