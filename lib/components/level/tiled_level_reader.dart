import 'package:flame/components.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:mpg_achievements_app/components/level/isometric/isometric_world.dart';
import 'package:mpg_achievements_app/components/level/game_world.dart';
import '../level_components/checkpoint/checkpoint.dart';
import '../level_components/collectables.dart';
import '../level_components/enemy.dart';
import '../level_components/saw.dart';
import '../physics/collision_block.dart';

void generateSpawningObjectsForLevel(GameWorld gameWorld) {
  //Here were look for all the objects which where added in our Spawnpoints Objectlayer in Level_0.tmx in Tiled and store these objects into a list
  final ObjectGroup? spawnPointsLayer = gameWorld.level.tileMap.getLayer<ObjectGroup>(
    'Spawnpoints',
  );

  //if there is no Spawnpoint-layer the game can never the less run and does not crash / Nullcheck-Safety
  if (spawnPointsLayer != null) {
    //then we go through the list and check for the class Player, which was also defined as an object in the Óbjectlayer
    //When we find that class we create our player and add it to the level in the defined spawnpoint - ! just says that it can be null
    for (final spawnPoint in spawnPointsLayer.objects) {
      switch (spawnPoint.class_) {
        case 'Player':
        //player spawning
          gameWorld.player.position = Vector2(spawnPoint.x, spawnPoint.y);
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
            position: Vector2(spawnPoint.x, spawnPoint.y),
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
          gameWorld.enemy.position = Vector2(spawnPoint.x, spawnPoint.y);
          gameWorld.add(gameWorld.enemy);

        default:
      }
    }
  }
}


void generateCollisionsForLevel(GameWorld gameWorld) {
  final collisionsLayer = gameWorld.level.tileMap.getLayer<ObjectGroup>('Collisions');
  //convert orthogonal to isometric coordinates
  Vector2 _orthogonalToIsometric(Vector2 orthoPos) {
    return Vector2(
        ((orthoPos.x - orthoPos.y) * 1.0),
        (orthoPos.x + orthoPos.y) * 0.5 + 1
    );
  }

  if (collisionsLayer != null) {
    for (final collision in collisionsLayer.objects) {

      Vector2 pos;

      if(gameWorld is IsometricWorld){
        pos = _orthogonalToIsometric(collision.position) + Vector2(gameWorld.level.width / 2, 0);
      } else pos = collision.position;



      switch (collision.class_) {
        case 'Platform':
          final platform = CollisionBlock(
            position: pos,
            size: Vector2(collision.width, collision.height),
            hasCollisionDown: false,
            hasHorizontalCollision: false,
            gameWorld: gameWorld
          );
          gameWorld.add(platform);
        case 'Ladder':
          final ladder = CollisionBlock(
            position: pos,
            size: Vector2(collision.width - 10, collision.height),
            climbable: true,
            hasCollisionDown: false,
            hasCollisionUp: true,
            hasHorizontalCollision: false,
            isLadder: true,
            gameWorld: gameWorld
          );
          gameWorld.add(ladder);
        default:
          final block = CollisionBlock(
            position: pos,
            size: Vector2(collision.width, collision.height),
            gameWorld: gameWorld
          );
          gameWorld.add(block);
      }
    }
  }


}