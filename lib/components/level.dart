import 'dart:async';
import 'package:flame/components.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:mpg_achievements_app/components/background_tile.dart';
import 'package:mpg_achievements_app/components/collision_block.dart';
import 'package:mpg_achievements_app/components/player.dart';

class Level extends World with HasGameReference {
  final String levelName;
  late TiledComponent level;
  final Player player;
  List<CollisionBlock> collisionsBlockList = [];
  //loads when the class instantiated
  //In dart, late keyword is used to declare a variable or field that will be initialized at a later time.e.g. late String name
  //
  //constructor
  Level({required this.levelName, required this.player});

  @override
  FutureOr<void> onLoad() async {
    //await need to be there because it takes some time to load, that's why the method needs to be async
    //otherwise the rest of the programme would stop
    //16 is 16x16 of our tileset
    level = await TiledComponent.load('$levelName.tmx', Vector2.all(16));
    add(level);
    _scrollingBackground();
    _spawningObjects();
    _addCollisions();
    //runs all the other onLoad-events the method is referring to, now not important
    return super.onLoad();
  }
  //creating a background dynamically //todo add scrolling
  void _scrollingBackground() {
    final backgroundLayer = level.tileMap.getLayer('Level');

    const tileSize = 64;
    //calculating the number of tiles we need for our level/game / floor() rounds the number here our game reference is needed
    final numTilesY = (game.size.y / tileSize).floor();
    final numTilesX = (game.size.x / tileSize).floor();

    if(backgroundLayer != null){
      final backgroundColor = backgroundLayer.properties.getValue('BackgroundColor');

      //?? says that if backgroundColor is null use gray if not null use backgroundColor / position is start-coordinates of background
      for(double y = 0; y< numTilesY; y++){
        for(double x = 0;x < numTilesX; x++ ){
          //?? says that if backgroundColor is null use gray if not null use backgroundColor / position is start-coordinates of background
          //Vector2 must be *tileSize because otherwise we would ad in position of the loop numbers, but every time a tile is added we need to add 64 to the position
          final backgroundTile = BackgroundTile(
              color: backgroundColor ??'Gray',
              position: Vector2(x * tileSize - tileSize ,y * tileSize - tileSize));
          add(backgroundTile);
        }

      }
    }
  }

  void _spawningObjects() {
    //Here were look for all the objects which where added in our Spawnpoints Objectlayer in Level_0.tmx in Tiled and store these objects into a list
    final spawnPointsLayer = level.tileMap.getLayer<ObjectGroup>('Spawnpoints');

    //if there is no Spawnpointslayer the game can never the less run and does not crash / Nullcheck-Safety
    if (spawnPointsLayer != null) {
      //then we go through the list and check for the class Player, which was also defined as an object in the Óbjectlayer
      //When we find that class we create our player and add it to the level in the defined spawnpoint - ! just says that it can be null
      for (final spawnPoint in spawnPointsLayer!.objects) {
        switch (spawnPoint.class_) {
          case 'Player':
          //player
            player.position = Vector2(spawnPoint.x, spawnPoint.y);
            add(player);
            break;
          default:
        }
      }
    }
  }

  void _addCollisions() {

    final collisionsLayer = level.tileMap.getLayer<ObjectGroup>('Collisions');




    if (collisionsLayer != null) {
      for (final collision in collisionsLayer.objects) {
        //makes a list of all the collision object that are in the level and creates CollisionBlockObject-List with the respective attribute values
        switch (collision.class_) {
          case 'Platform':
            final platform = CollisionBlock(
              position: Vector2(collision.x, collision.y),
              size: Vector2(collision.width, collision.height),
              isPlatform: true,
            );
            collisionsBlockList.add(platform);
            add(platform);
          default:
            final block = CollisionBlock(
              position: Vector2(collision.x, collision.y),
              size: Vector2(collision.width, collision.height),
            );
            collisionsBlockList.add(block);
            add(block);
        }
      }
    }
    //all collisionsBlocks are given to the player and now the player has a reference
    player.collisionsBlockList = collisionsBlockList;
  }
}
