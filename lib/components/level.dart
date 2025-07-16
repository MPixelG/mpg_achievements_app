import 'dart:async';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:flutter/cupertino.dart' hide PointerMoveEvent;
import 'package:flutter/gestures.dart' hide PointerMoveEvent;
import 'package:flutter/services.dart';
import 'package:mpg_achievements_app/components/background/background_tile.dart';
import 'package:mpg_achievements_app/components/collision_block.dart';
import 'package:mpg_achievements_app/components/collectables.dart';
import 'package:mpg_achievements_app/components/player.dart';
import 'package:mpg_achievements_app/components/saw.dart';
import 'package:mpg_achievements_app/mpg_pixel_adventure.dart';
import 'package:flutter/gestures.dart' hide PointerMoveEvent;

import 'background/scrolling_background.dart';

class Level extends World with HasGameReference, KeyboardHandler, PointerMoveCallbacks{
  final String levelName;
  late TiledComponent level;
  final Player player;

  //Todo add feature to make levels with and without scrolling background
  final bool scrollingBackground = false;

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

    add(overlays);
    overlays.scale = Vector2.zero(); //hide the overlays
    //runs all the other onLoad-events the method is referring to, now not important
    return super.onLoad();
  }

  //creating a background dynamically //todo add scrolling
  void _scrollingBackground() {
    final backgroundLayer = level.tileMap.getLayer('Level');
    String backgroundColor = "Green";
    if (backgroundLayer != null) {
      backgroundColor = backgroundLayer.properties.getValue(
        'BackgroundColor',
      );
    }

    ScrollingBackground background = ScrollingBackground(tileColor: backgroundColor, camera: (parent as PixelAdventure).cam);

    add(background);


    /*const tileSize = 64;
    //calculating the number of tiles we need for our level/game / floor() rounds the number here our game reference is needed
    final numTilesY = (game.size.y / tileSize).floor();
    final numTilesX = (game.size.x / tileSize).floor();

    if (backgroundLayer != null) {
      final backgroundColor = backgroundLayer.properties.getValue(
        'BackgroundColor',
      );

      //?? says that if backgroundColor is null use gray if not null use backgroundColor / position is start-coordinates of background
      for (double y = 0; y < game.size.y / numTilesY; y++) {
        for (double x = 0; x < numTilesX; x++) {
          //?? says that if backgroundColor is null use gray if not null use backgroundColor / position is start-coordinates of background
          //Vector2 must be *tileSize because otherwise we would ad in position of the loop numbers, but every time a tile is added we need to add 64 to the position
          final backgroundTile = BackgroundTile(
            color: backgroundColor ?? 'Yellow',
            position: Vector2(x * tileSize - tileSize, y * tileSize),
          );
          add(backgroundTile);
        }
      }
    }*/
  }

  void _spawningObjects() {
    //Here were look for all the objects which where added in our Spawnpoints Objectlayer in Level_0.tmx in Tiled and store these objects into a list
    final spawnPointsLayer = level.tileMap.getLayer<ObjectGroup>('Spawnpoints');

    //if there is no Spawnpointslayer the game can never the less run and does not crash / Nullcheck-Safety
    if (spawnPointsLayer != null) {
      //then we go through the list and check for the class Player, which was also defined as an object in the Óbjectlayer
      //When we find that class we create our player and add it to the level in the defined spawnpoint - ! just says that it can be null
      for (final spawnPoint in spawnPointsLayer.objects) {
        switch (spawnPoint.class_) {
          case 'Player':
            //player spawning
            player.position = Vector2(spawnPoint.x, spawnPoint.y);
            add(player);
            break;
          case "Collectable":
            //fruit spawning
            final collectable = Collectable(
              collectable: spawnPoint.name,
              position: Vector2(spawnPoint.x, spawnPoint.y),
              size: Vector2(spawnPoint.width, spawnPoint.height),
            );
            add(collectable);
            break;
          case "Saw":
            final isVertical = spawnPoint.properties.getValue('isVertical');
            final offNeg = spawnPoint.properties.getValue('offNeg');
            final offPos = spawnPoint.properties.getValue('offPos');
            final saw = Saw(isVertical: isVertical, offNeg: offNeg,offPos: offPos,
              position: Vector2(spawnPoint.x, spawnPoint.y),
              size: Vector2(spawnPoint.width, spawnPoint.height),
            );
            //saw rotates in the other direction
            saw.scale.x = -1;
            add(saw);
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
            add(platform);
          default:
            final block = CollisionBlock(
              position: Vector2(collision.x, collision.y),
              size: Vector2(collision.width, collision.height),
            );
            add(block);
        }
      }
    }
    //all collisionsBlocks are given to the player and now the player has a reference
    //player.collisionsBlockList = collisionsBlockList;
  }

   TextComponent overlays = TextComponent(text: "hello!", position: Vector2(0, 0));
    @override
    bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
      if (keysPressed.contains(LogicalKeyboardKey.keyV)) {if(overlays.scale == Vector2.zero()) overlays.scale = Vector2.all(0.5); else overlays.scale = Vector2.zero();} //press V to toggle the visibility of the overlays
      return super.onKeyEvent(event, keysPressed);
    }

    Vector2 mouseCoords = Vector2.zero();
    @override
    void onPointerMove(PointerMoveEvent event) {
        mouseCoords = event.localPosition..round();
        player.mouseCoords = mouseCoords;
    }

    @override



    @override //update the overlays
    void update(double dt) {
      if(overlays.scale == Vector2.zero()) return;

      Vector2 roundedPlayerPos = player.position.clone()..round();

      String playerCoords = roundedPlayerPos.toString();
      overlays.text = "Player: " + playerCoords + "\nMouse: " + mouseCoords.toString();

      super.update(dt);
    }

    //sets the visibility of all of the hitboxes of all of the components in the level (except for background tiles)
    void setDebugMode(bool val) {
      for (var value in this.descendants()) {
        if (value is BackgroundTile) continue;

        value.debugMode = val;
      }
    }


    Vector2 get mousePos => mouseCoords;


  }