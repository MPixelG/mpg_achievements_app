import 'dart:async';
import 'package:flame/components.dart' hide Vector2;
import 'package:mpg_achievements_app/3d/src/game.dart';
import 'package:mpg_achievements_app/isometric/src/core/level/level_object.dart';
import 'package:mpg_achievements_app/isometric/src/core/level/tiled_level.dart';
import 'package:thermion_flutter/thermion_flutter.dart';
import 'package:vector_math/vector_math_64.dart' as v64;
import 'game_world.dart';
//todo refactor and integrate in new tiled_level

class LevelLoader {
  final PixelAdventure3D game = PixelAdventure3D.currentInstance;
  final ThermionViewer viewer;
  late final TiledLevel levelData;
  late final Vector2 tileSize;
  final double gridScale = 2.0;

  LevelLoader({
    required this.levelData,
    //for test now tilesize does not matter
    required this.tileSize,
    required this.viewer,
  });

  void init() {
   // _spawnObjects();
    //spawnTiles();

  }


  //Iterates through tile layers and spawns 3D tile models in Thermion
  Future<void> spawnTiles() async {

    // Iterate over all layers
    for (int layerIndex = 0; layerIndex < levelData.layers.length; layerIndex++) {
      final layer = levelData.layers[layerIndex];

      // Calculate a height offset based on the layer index
      // Layer 0 = 0m height, Layer 1 = 1m height, etc.
      // Adjust this multiplier based on how tall your blocks are
      final double yHeight = layerIndex * gridScale;

      for (final tile in layer.activeTiles) {
        // 1. Get the model path associated with this tile GID
        final tileInfo = levelData.tilesetData[tile.gid];
        print(tileInfo);
        // Only spawn if we found a valid model path
        if (tileInfo != null && tileInfo.modelPath != null) {

          // 2. Clean up the path (Thermion usually wants paths relative to asset root)
          // e.g. "assets/tiles/block.glb" -> "tiles/block.glb"
          String modelPath = tileInfo.modelPath!;
          if (modelPath.startsWith('assets/')) {
            modelPath = modelPath.substring(7); // Remove 'assets/'
          } else if (modelPath.startsWith('assets\\')) {
            modelPath = modelPath.substring(7); // Remove windows style
            print(modelPath);
          }

          // 3. Load the model or wrapper into the 3D scene
            final dynamic asset = await viewer.loadGltf(modelPath);

            //extract entity ID
            final entityID = (asset as dynamic).entity;

            // 4. Position the model
            // Tiled X -> 3D X
            // Tiled Y -> 3D Z (Depth)
            // Layer -> 3D Y (Height)
            final double xPos = tile.x * tileSize.x;
            final double zPos = tile.y * tileSize.y;

            //Create translation Matrix -> is there a better way?
            final matrix = v64.Matrix4.identity();
            matrix.setTranslation(v64.Vector3(xPos,yHeight,zPos));

            //Filament
            FilamentApp.instance?.setTransform(entityID, matrix);
            print('tile spawn');

        }
      }
    }
  }

// ... existing _spawnObjects and _spawnCollisions ...
}
/*
  void _spawnObjects(){
    //Here were look for all the objects which where added in our Spawnpoints Objectlayer in Level_0.tmx in Tiled and store these objects into a list
    final LevelObjectLayer? spawnPointsLayer = levelData.getObjectLayer('Spawnpoints');
    if(spawnPointsLayer == null) return;

    //if there is no Spawnpoint-layer the game can never the less run and does not crash / Nullcheck-Safety
    //then we go through the list and check for the class Player, which was also defined as an object in the Óbjectlayer
    //When we find that class we create our player and add it to the level in the defined spawnpoint - ! just says that it can be null
    for (final object in spawnPointsLayer.objects) {
      print("Spawning ${object.type} at (${object.x},{$object.y})");

      switch (object.type) {
        case 'Player':
        //player spawning

        case 'Collectable':
        //checking type for spawning


          //collectable spawning

          break;
        case "Saw":

          //saw rotates in the other direction

          break;
        case "Checkpoint":

          break;
        case "Enemy":


        default:
      }
    }*/


