import 'dart:developer';

import 'package:flame/flame.dart';
import 'package:mpg_achievements_app/3d/src/chunking/tiles/parent_tile.dart';
import 'package:mpg_achievements_app/3d/src/chunking/tiles/tile_data.dart';
import 'package:mpg_achievements_app/3d/src/game.dart';
import 'package:thermion_flutter/thermion_flutter.dart';

class TileProvider {
  static Map<TileData, ParentTile> cachedParentTiles = {};
  static Map<String, Geometry> shapes = {};
  static Map<String, MaterialInstance> materials = {}; //todo
  
  
  static Future<ParentTile> getParentAssetOfTileType(TileData data) async {
    final ParentTile? cacheResult = cachedParentTiles[data];
    if(cacheResult == null){
      if(_currentActiveTileProcesses.containsKey(data)) _currentActiveTileProcesses[data] = createParentAssetOfTileType(data);
      return _currentActiveTileProcesses[data]!;
    } else {
      return cachedParentTiles[data]!;
    }
  }

  static final Map<TileData, Future<ParentTile>> _currentActiveTileProcesses = {};
  static Future<ParentTile> createParentAssetOfTileType(TileData data) async {
    final ThermionAsset asset = await thermion!.createGeometry(shapes[data.shape]!, materialInstances: [materials[data.texture]!]); 
    final ParentTile parentTile = ParentTile(asset);
    cachedParentTiles[data] = parentTile;
    _currentActiveTileProcesses.remove(data);
    return parentTile;
  }

  static Future<Geometry> getShapeGeometry(String shape) async {
    final Geometry? cachedGeometry = shapes[shape];
    if(cachedGeometry == null){
      final Future<Geometry> createdGeometryFuture = createShapeGeometry(shape);
      _currentActiveShapeProcesses[shape] = createdGeometryFuture;
      return await createdGeometryFuture;
    } else {
      return cachedGeometry;
    }
  }
  
  static final Map<String, Future<Geometry>> _currentActiveShapeProcesses = {};
  static Future<Geometry> createShapeGeometry(String shape) async {
    final Map<String, dynamic> shapeJson = await Flame.assets.readJson("assets/3D/shapes/$shape.json");
    
    final List<double> jsonVertices;
    final List<int> jsonIndices;
    final List<double> jsonNormals;
    try {
      jsonVertices = shapeJson["data"]["vertices"];
      jsonIndices = shapeJson["data"]["indices"];
      jsonNormals = shapeJson["data"]["normals"];
    } catch(e) {
      log("shape json has invalid format! check the type of the values and make sure your json contains data/vertices, data/indices and data/normals!");
      rethrow;
    }
    
    final Geometry geometry = Geometry(Float32List.fromList(jsonVertices), jsonIndices, normals: Float32List.fromList(jsonNormals));
    shapes[shape] = geometry;
    return geometry;
  }

  static Future<MaterialInstance> createMaterialFromJson(String materialName) async {
    final Map<String, dynamic> materialJson = await Flame.assets.readJson("assets/3D/materials/$materialName.json");
    
    final bool hasBaseColorTexture = materialJson["hasBaseColorTexture"] ?? false;
    final bool hasNormalTexture = materialJson["hasNormalTexture"] ?? false;
    final bool hasClearCoatTexture = materialJson["hasClearCoatTexture"] ?? false;
    final bool hasClearCoatNormalTexture = materialJson["hasClearCoatNormalTexture"] ?? false;
    final bool hasClearCoatRoughnessTexture = materialJson["hasClearCoatRoughnessTexture"] ?? false;
    final bool hasClearCoat = materialJson["hasClearCoat"] ?? false;
    final bool hasEmissiveTexture = materialJson["hasEmissiveTexture"] ?? false;
    final bool hasOcclusionTexture = materialJson["hasOcclusionTexture"] ?? false;
    final bool hasSheen = materialJson["hasSheen"] ?? false;
    final bool hasSheenRoughnessTexture = materialJson["hasSheenRoughnessTexture"] ?? false;
    final bool hasSheenColorTexture = materialJson["hasSheenColorTexture"] ?? false;
    final bool hasIOR = materialJson["hasIOR"] ?? false;
    final bool hasMetallicRoughnessTexture = materialJson["hasMetallicRoughnessTexture"] ?? false;
    final bool hasTextureTransforms = materialJson["hasTextureTransforms"] ?? false;
    final bool hasTransmission = materialJson["hasTransmission"] ?? false;
    final bool hasTransmissionTexture = materialJson["hasTransmissionTexture"] ?? false;
    final bool hasVertexColors = materialJson["hasVertexColors"] ?? false;
    final bool hasVolume = materialJson["hasVolume"] ?? false;
    final bool hasVolumeThicknessTexture = materialJson["hasVolumeThicknessTexture"] ?? false;
    final bool useSpecularGlossiness = materialJson["useSpecularGlossiness"] ?? false;
    final bool unlit = materialJson["unlit"] ?? false;
    final bool enableDiagnostics = materialJson["enableDiagnostics"] ?? false;
    final bool doubleSided = materialJson["doubleSided"] ?? false;
    
    
    final AlphaMode alphaMode = switch (materialJson["alphaMode"]) {
      "Blend" => AlphaMode.BLEND,
      "MASK" => AlphaMode.MASK,
      "OPAQUE" => AlphaMode.OPAQUE,
      Object() => throw UnimplementedError(),
      null => throw UnimplementedError(),
    };

    return FilamentApp.instance!.createUbershaderMaterialInstance(
      hasBaseColorTexture: hasBaseColorTexture,
      hasNormalTexture: hasNormalTexture,
      hasClearCoatTexture: hasClearCoatTexture,
      hasClearCoatNormalTexture: hasClearCoatNormalTexture,
      hasClearCoatRoughnessTexture: hasClearCoatRoughnessTexture,
      hasClearCoat: hasClearCoat,
      hasEmissiveTexture: hasEmissiveTexture,
      hasOcclusionTexture: hasOcclusionTexture,
      hasSheen: hasSheen,
      hasSheenRoughnessTexture: hasSheenRoughnessTexture,
      hasSheenColorTexture: hasSheenColorTexture,
      hasIOR: hasIOR,
      hasMetallicRoughnessTexture: hasMetallicRoughnessTexture,
      hasTextureTransforms: hasTextureTransforms,
      hasTransmission: hasTransmission,
      hasTransmissionTexture: hasTransmissionTexture,
      hasVertexColors: hasVertexColors,
      hasVolume: hasVolume,
      hasVolumeThicknessTexture: hasVolumeThicknessTexture,
      useSpecularGlossiness: useSpecularGlossiness,
      unlit: unlit,
      enableDiagnostics: enableDiagnostics,
      doubleSided: doubleSided,
      alphaMode: alphaMode,
    );
  }
}