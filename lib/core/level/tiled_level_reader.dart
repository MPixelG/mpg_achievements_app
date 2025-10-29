import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:flame_tiled/flame_tiled.dart' show ObjectGroup, TiledObjectHelpers;
import 'package:mpg_achievements_app/core/level/tiled_level.dart';
import 'package:mpg_achievements_app/core/physics/collision_block.dart';
import 'package:mpg_achievements_app/mpg_pixel_adventure.dart';
import 'package:mpg_achievements_app/util/isometric_utils.dart';
import 'package:mpg_achievements_app/util/utils.dart';
import 'package:xml/xml.dart';

import '../../components/level_components/checkpoint/checkpoint.dart';
import '../../components/level_components/collectables.dart';
import '../../components/level_components/entity/enemy/enemy.dart';
import '../../components/level_components/saw.dart';
import 'game_world.dart';
import 'rendering/chunk.dart';

void generateSpawningObjectsForLevel(GameWorld gameWorld) {
  //Here were look for all the objects which where added in our Spawnpoints Objectlayer in Level_0.tmx in Tiled and store these objects into a list
  final ObjectGroup? spawnPointsLayer = gameWorld.level.tileMap
      .getLayer<ObjectGroup>('Spawnpoints');

  //if there is no Spawnpoint-layer the game can never the less run and does not crash / Nullcheck-Safety
  if (spawnPointsLayer != null) {
    //then we go through the list and check for the class Player, which was also defined as an object in the Óbjectlayer
    //When we find that class we create our player and add it to the level in the defined spawnpoint - ! just says that it can be null
    for (final spawnPoint in spawnPointsLayer.objects) {

      print("spawning object of class: ${spawnPoint.class_} at ${spawnPoint.position}");

      switch (spawnPoint.class_) {
        case 'Player':
          //player spawning

          Vector2 twoDimIsoPos = orthogonalToIsometric(spawnPoint.position); //todo fix for level offset.
          print("grid pos: $twoDimIsoPos, spawn point: ${spawnPoint.position}");
          gameWorld.player.position = Vector3(7, 1, 7);
          gameWorld.player.priority = 1;
          break;
        case 'Collectable':
          //checking type for spawning
          bool interactiveTask =
              spawnPoint.properties.getValue('interactiveTask') ?? false;
          String collectablePath(bool task) =>
              task == true ? 'objects' : 'Items/Fruits';

          //collectable spawning
          final collectable = Collectable(
            collectable: spawnPoint.name,
            position: Vector2(spawnPoint.x, spawnPoint.y),
            size: Vector2(spawnPoint.width, spawnPoint.height),
            interactiveTask: interactiveTask,
            collectablePath: collectablePath(interactiveTask),
            animated: !interactiveTask,
          );
          Collectable.totalAmountOfCollectables++;
          gameWorld.add(collectable);
          break;
        case "Saw":
          final isVertical = spawnPoint.properties.getValue('isVertical');
          final offNeg = spawnPoint.properties.getValue('offNeg');
          final offPos = spawnPoint.properties.getValue('offPos');
          final saw = Saw(
            isVertical: isVertical,
            offNeg: offNeg,
            offPos: offPos,
            position: Vector2(spawnPoint.x, spawnPoint.y),
            size: Vector2(spawnPoint.width, spawnPoint.height),
          );
          //saw rotates in the other direction
          saw.scale.x = -1;
          gameWorld.add(saw);
          break;
        case "Checkpoint":
          final id = spawnPoint.properties.getValue('id');
          final isActivated = spawnPoint.properties.getValue('isActivated');
          final checkpoint = Checkpoint(
            id: id,
            isActivated: isActivated,
            position: Vector3.array([...toGridPos(spawnPoint.position).storage, spawnPointsLayer.id?.toDouble() ?? 0.0]),
          );
          // if checkpoint is already activated in tiled, the original spawnpoint is overridden
          if (isActivated == true) {
            //todo state management implement necessary level.player.lastCheckpoint = checkpoint;
            gameWorld.player.position = checkpoint.position;
          }
          gameWorld.add(checkpoint);
          break;
        case "Enemy":
          //enemy spawning
          gameWorld.enemy = Enemy(enemyCharacter: "Virtual Guy");
          gameWorld.enemy.position = Vector3(spawnPoint.x, spawnPoint.y, 0); //todo correct reading of z pos
          gameWorld.add(gameWorld.enemy);

        default:
      }
    }
  }
}

void generateCollisionsForLevel(GameWorld gameWorld) {
  final collisionsLayer = gameWorld.level.tileMap.getLayer<ObjectGroup>(
    'Collisions',
  );
  //convert orthogonal to isometric coordinates
  Vector2 orthogonalToIsometric(Vector2 orthoPos) {
    return Vector2(
      ((orthoPos.x - orthoPos.y)),
      (orthoPos.x + orthoPos.y) * 0.5,
    );
  }

  if (collisionsLayer != null) {
    for (final collision in collisionsLayer.objects) {
      Vector2 pos = orthogonalToIsometric(collision.position);
      // get z and zHeight from properties, if not set default to 0 and 16
      final double yPos = collision.properties.getValue('zPosition') ?? 0;

      final Vector2 scaledSize = collision.size.clone()..divide(tilesize.xy);
      final Vector2 scaledPos = collision.position;

      switch (collision.class_) {
        default:
          /*final block = CollisionBlock(
            position: Vector3(pos.x, yPos, pos.y),
            size: Vector3(collision.width / tilesize.x, 1, collision.height / tilesize.y),
          );*/
          //gameWorld.add(block);
      }
    }
  }
}

Future<void> parse(String filename) async{
  String fileContent = await Flame.assets.readFile(filename);

  XmlDocument document = XmlDocument.parse(fileContent);

  TiledLevel level = TiledLevel.fromXml(document);
  print('Level width: ${level.width}, height: ${level.height}');
  print('Number of layers: ${level.layers.length}');
  print("first layer: ${level.layers[0].name} with width ${level.layers[0].width} and height ${level.layers[0].height}. Data: ${level.layers[0].data}");
}