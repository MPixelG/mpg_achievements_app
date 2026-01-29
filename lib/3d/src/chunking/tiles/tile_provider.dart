import 'package:mpg_achievements_app/3d/src/chunking/tiles/tile_data.dart';
import 'package:mpg_achievements_app/3d/src/game.dart';
import 'package:thermion_flutter/thermion_flutter.dart';

class TileProvider {
  static Map<TileData, ThermionAsset> cachedParentTiles = {};
  static Map<String, Geometry> shapes = {}; //todo
  static Map<String, MaterialInstance> materials = {}; //todo
  
  
  static Future<ThermionAsset> getAssetOfTileType(TileData data) async{
    final ThermionAsset? cacheResult = cachedParentTiles[data];
    if(cacheResult == null){
      if(_currentActiveProcesses.containsKey(data)) _currentActiveProcesses[data] = createAssetOfTileType(data);
      return _currentActiveProcesses[data]!;
    } else {
      return cachedParentTiles[data]!;
    }
  }

  static final Map<TileData, Future<ThermionAsset>> _currentActiveProcesses = {};
  static Future<ThermionAsset> createAssetOfTileType(TileData data) async{
    final ThermionAsset asset = await thermion!.createGeometry(shapes[data.shape]!, materialInstances: [materials[data.texture]!]); 
    cachedParentTiles[data] = asset;
    _currentActiveProcesses.remove(data);
    return asset;
  }
}