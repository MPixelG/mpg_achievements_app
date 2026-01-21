import 'dart:async';
import 'package:mpg_achievements_app/3d/src/game.dart';
import 'package:mpg_achievements_app/3d/src/level/entity_factory.dart';
import 'package:mpg_achievements_app/3d/src/level/tiled_level.dart';
import 'package:thermion_flutter/thermion_flutter.dart';
import 'package:vector_math/vector_math_64.dart' as v64;
//todo refactor and integrate in new tiled_level

class LevelLoader {
  final PixelAdventure3D game = PixelAdventure3D.currentInstance;
  final ThermionViewer viewer;
  late final TiledLevel levelData;
  final double tiledPixelSize = 128.0;
  final double gridScale = 2.0;


  LevelLoader({
    required this.levelData,
    required this.viewer,
  });

  void init() {
    // _spawnObjects();
    //spawnTiles();
  }

  //Iterates through tile layers and spawns 3D tile models in Thermion
  Future<void> spawnTiles() async {
    // Iterate over all layers
    for (
      int layerIndex = 0;
      layerIndex < levelData.layers.length;
      layerIndex++
    ) {
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
          final String modelPath = tileInfo.modelPath!;
          print(modelPath);



          // 3. Load the model or wrapper into the 3D scene
          final dynamic asset = await viewer.loadGltf(modelPath);
          
          print("loaded!");

          //extract entity ID
          final entityID = (asset as dynamic).entity;

          // 4. Position the model
          // Tiled X -> 3D X
          // Tiled Y -> 3D Z (Depth)
          // Layer -> 3D Y (Height)
          final double xPos = tile.x * 2.0;
          final double zPos = tile.y * 2.0;

          final position = v64.Vector3(xPos, yHeight, zPos);

          //Create translation Matrix -> is there a better way?
          final matrix = v64.Matrix4.identity();
          matrix.setTranslation(position);

          //Filament
          FilamentApp.instance?.setTransform(entityID, matrix);
          print('tile spawn at $xPos $yHeight $zPos ');
        }
      }
    }
  }

  Future<void> spawnObjects() async {
    // Iterate over all layers
    for (
      int layerIndex = 0;
      layerIndex < levelData.layers.length;
      layerIndex++
    ) {
      final layer = levelData.objectLayers[layerIndex];

      // Calculate a height offset based on the layer index
      // Layer 0 = 0m height, Layer 1 = 1m height, etc.
      // Adjust this multiplier based on how tall your blocks are
      final double yHeight = layerIndex * gridScale;

      for (final object in layer.objects) {
        //add nullcheck or default model
        final String modelPath = object.properties['model_path'].toString();
        print(modelPath);

        // 1. Get raw value (could be String, num, or null)
        final rawOffset = object.properties['y_offset'];

        double objectOffset = 0.0;

        if (rawOffset is num) {
          objectOffset = rawOffset.toDouble();
        } else if (rawOffset is String) {
          objectOffset = double.tryParse(rawOffset) ?? 0.0;
        }
        final double finalY = yHeight + objectOffset;

        // 4. Position the model
        // Tiled X -> 3D X
        // Tiled Y -> 3D Z (Depth)
        // Layer -> 3D Y (Height)
        final double xPos = object.x.toDouble()/tiledPixelSize;
        final double zPos = object.y.toDouble()/tiledPixelSize;
        final double yPos = finalY;

        final position = v64.Vector3(xPos,yPos,zPos);
        //Object type
        final String type = object.type ?? 'Player';
        print(type);

        print('spawn object type at $xPos $yPos $zPos ');

        //Entity Factory looks at the
        final component = EntityFactory.create(
            type,
            position,
            Vector3.all(1.0),
            object.properties,
            );

        /*final player = Player(
            position: v64.Vector3(xPos, yPos, zPos),
            size: Vector3.all(1.0), // Player size
            asset: asset,
            );*/
          print(component?.position);

          // Add to Flame Game Loop
          game.add(component!);
          // Optional: If you need to track the player in the loader
          // game.player = player;

        }

      }

      //todo add logic for different objects
    }
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
