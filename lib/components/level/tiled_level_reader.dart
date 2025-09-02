import 'package:flame/components.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:mpg_achievements_app/components/level/level.dart';
import '../level_components/checkpoint/checkpoint.dart';
import '../level_components/collectables.dart';
import '../level_components/enemy.dart';
import '../level_components/saw.dart';
import '../physics/collision_block.dart';

void generateSpawningObjectsForLevel(Level level) {
  //Here were look for all the objects which where added in our Spawnpoints Objectlayer in Level_0.tmx in Tiled and store these objects into a list
  final ObjectGroup? spawnPointsLayer = level.level.tileMap.getLayer<ObjectGroup>(
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
          level.player.position = Vector2(spawnPoint.x, spawnPoint.y);
          level.add(level.player);
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
          level.add(collectable);
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
          level.add(saw);
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
            level.player.position = checkpoint.position;
          }
          level.add(checkpoint);
          break;
        case "Enemy":
        //enemy spawning
          level.enemy = Enemy(enemyCharacter: "Virtual Guy");
          level.enemy.position = Vector2(spawnPoint.x, spawnPoint.y);
          level.add(level.enemy);

        default:
      }
    }
  }
}


void generateCollisionsForLevel(Level level) {
  final collisionsLayer = level.level.tileMap.getLayer<ObjectGroup>('Collisions');

  if (collisionsLayer != null) {
    for (final collision in collisionsLayer.objects) {
      //makes a list of all the collision object that are in the level and creates CollisionBlockObject-List with the respective attribute values
      switch (collision.class_) {
        case 'Platform':
          final platform = CollisionBlock(
            position: Vector2(collision.x, collision.y),
            size: Vector2(collision.width, collision.height),
            hasCollisionDown: false,
            hasHorizontalCollision: false,
            level: level
          );
          level.add(platform);
        case 'Ladder':
          final ladder = CollisionBlock(
            position: Vector2(collision.x, collision.y),
            size: Vector2(collision.width - 10, collision.height),
            climbable: true,
            hasCollisionDown: false,
            hasCollisionUp: true,
            hasHorizontalCollision: false,
            isLadder: true,
            level: level
          );
          level.add(ladder);
        default:
          final block = CollisionBlock(
            position: Vector2(collision.x, collision.y),
            size: Vector2(collision.width, collision.height),
            level: level
          );
          level.add(block);
      }
    }
  }
}