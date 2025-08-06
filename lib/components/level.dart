import 'dart:async';
import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/extensions.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:flutter/material.dart' hide PointerMoveEvent, AnimationStyle;
import 'package:flutter/services.dart';
import 'package:mpg_achievements_app/components/ai/pathfinder.dart';
import 'package:mpg_achievements_app/components/animation/animation_style.dart';
import 'package:mpg_achievements_app/components/background/LayeredImageBackground.dart';
import 'package:mpg_achievements_app/components/background/background_tile.dart';
import 'package:mpg_achievements_app/components/physics/collision_block.dart';
import 'package:mpg_achievements_app/components/level_components/collectables.dart';
import 'package:mpg_achievements_app/components/level_components/enemy.dart';
import 'package:mpg_achievements_app/components/physics/collisions.dart';
import 'package:mpg_achievements_app/components/player.dart';
import 'package:mpg_achievements_app/components/shaders/shader_manager.dart';
import 'package:mpg_achievements_app/components/util/utils.dart';
import 'package:mpg_achievements_app/mpg_pixel_adventure.dart';

import 'background/scrolling_background.dart';
import 'level_components/saw.dart';
import 'level_components/checkpoint/checkpoint.dart';

class Level extends World
    with
        HasGameReference<PixelAdventure>,
        KeyboardHandler,
        PointerMoveCallbacks,
        TapCallbacks {
  final String levelName;
  late TiledComponent level;
  final Player player;
  Enemy enemy;

  int totalCollectables = 0;

  late final Vector2 tilesize;

  //Todo add feature to make levels with and without scrolling background //added via Tiled
  final bool scrollingBackground = false;

  //loads when the class instantiated
  //In dart, late keyword is used to declare a variable or field that will be initialized at a later time.e.g. late String name
  //
  //constructor
  Level(this.enemy, {required this.levelName, required this.player});

  late POIGenerator generator;

  @override
  FutureOr<void> onLoad() async {
    tilesize = (await getTilesizeOfLevel(levelName));

    //await need to be there because it takes some time to load, that's why the method needs to be async
    //otherwise the rest of the programme would stop
    // Load the Tiled map for the current level.
    // The '$levelName.tmx' refers to a .tmx file (created in Tiled), using 32x32 tiles.
    level = await TiledComponent.load('$levelName.tmx', tilesize);
    add(level);

    // If level not Parallax, load level with  scrolling background, property is added in Tiled
    if (level.tileMap.getLayer('Level')?.properties.getValue('Parallax') ?? false) {
      _loadParallaxLevel();
    } else {
      _scrollingBackground();
    }

    String side = level.tileMap.getLayer('Level')?.properties.getValue('Side') ?? "Side";

    if (side == "Side") {
      player.viewSide = ViewSide.side;
    } else if(side == "TopDown"){
      player.viewSide = ViewSide.topDown;
    }


    generator = POIGenerator(this);
    add(generator);

    //spawn objects
    _spawningObjects();
    //add collision objects
    _addCollisions();

    // Set their scale and render priority so they display correctly.
    add(debugOverlays);
    debugOverlays.scale = Vector2.zero(); // Start hidden/scaled down
    debugOverlays.priority =
        2; // Ensure overlays draw above the rest of the game

    // Set dynamic movement bounds for the camera, allowing smooth tracking of the player.
    game.cam.setMoveBounds(Vector2.zero(), level.size);

    //runs all the other onLoad-events the method is referring to, now not important
    return super.onLoad();
  }

  //creating a background dynamically
  void _scrollingBackground() {
    final backgroundLayer = level.tileMap.getLayer('Level');
    String backgroundColor = "Green";
    if (backgroundLayer != null) {
      backgroundColor =
          backgroundLayer.properties.getValue('BackgroundColor') ?? "Green";
    }

    ScrollingBackground background = ScrollingBackground(
      tileColor: backgroundColor,
      camera: (parent as PixelAdventure).cam,
    );
    background.priority = -3;

    add(background);
  }

  void _spawningObjects() {
    //Here were look for all the objects which where added in our Spawnpoints Objectlayer in Level_0.tmx in Tiled and store these objects into a list
    final ObjectGroup? spawnPointsLayer = level.tileMap.getLayer<ObjectGroup>(
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
            player.position = Vector2(spawnPoint.x, spawnPoint.y);
            add(player);
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
            totalCollectables++;
            add(collectable);
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
            add(saw);
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
              player.lastCheckpoint = checkpoint;
              player.position = checkpoint.position;
            }
            add(checkpoint);
            break;
          case "Enemy":
            //enemy spawning
            enemy = Enemy(enemyCharacter: "Virtual Guy");
            enemy.position = Vector2(spawnPoint.x, spawnPoint.y);
            add(enemy);

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
              hasCollisionDown: false,
              hasHorizontalCollision: false,
            );
            add(platform);
          case 'Ladder':
            final ladder = CollisionBlock(
              position: Vector2(collision.x, collision.y),
              size: Vector2(collision.width - 10, collision.height),
              climbable: true,
              hasCollisionDown: false,
              hasCollisionUp: true,
              hasHorizontalCollision: false,
              isLadder: true,
            );
            add(ladder);
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

  TextComponent debugOverlays = TextComponent(
    text: "hello!",
    position: Vector2(0, 0),
  );

  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    if (keysPressed.contains(LogicalKeyboardKey.keyV)) {
      if (debugOverlays.scale == Vector2.zero()) {
        debugOverlays.scale = Vector2.all(0.5);
      } else {
        debugOverlays.scale = Vector2.zero();
      }
    } //press V to toggle the visibility of the overlays
    if (keysPressed.contains(LogicalKeyboardKey.keyN)) {
      (parent as PixelAdventure).cam.shakeCamera(
        6,
        5,
        animationStyle: AnimationStyle.EaseOut,
      );
    } //press V to toggle the visibility of the overlays

    if (keysPressed.contains(LogicalKeyboardKey.keyH))
      game.overlays.toggle("guiEditor");

    return super.onKeyEvent(event, keysPressed);
  }

  Vector2 _mouseCoords = Vector2.zero();

  @override
  void onPointerMove(PointerMoveEvent event) {
    _mouseCoords = event.localPosition..round();
    player.mouseCoords = _mouseCoords;
  }

  @override
  void onTapDown(TapDownEvent event) {
    generator.onClick(event);
    super.onTapDown(event);
  }

  @override //update the overlays
  void update(double dt) {
    if (debugOverlays.scale == Vector2.zero()) return;

    Vector2 roundedPlayerPos = player.position.clone()..round();

    String playerCoords = roundedPlayerPos.toString();
    debugOverlays.text =
        "Player: $playerCoords\nMouse: $_mouseCoords\nGrid Mouse Coords isometric: ${(screenToTileIsometric(screenPosition: _mouseCoords, cameraPosition: game.cam.pos))..floor()} \nGrid Mouse coords Orthogonal: ${(mousePos.x / tilesize.x).floor()}, ${(mousePos.y / tilesize.y).floor()}";
    debugOverlays.position =
        game.cam.pos - game.cam.visibleWorldRect.size.toVector2() / 2;

    super.update(dt);
  }


  Vector2 screenToTileIsometric({
    required Vector2 screenPosition,
    required Vector2 cameraPosition,
    double zoom = 1,
  }) {
    final worldX = (screenPosition.x / zoom) + cameraPosition.x;
    final worldY = (screenPosition.y / zoom) + cameraPosition.y;

    final tileX = (worldX / (tilesize.x / 2) + worldY / (tilesize.y / 2)) / 2;
    final tileY = (worldY / (tilesize.y / 2) - worldX / (tilesize.x / 2)) / 2;

    return Vector2(tileX.floorToDouble(), tileY.floorToDouble());
  }



  //sets the visibility of all of the hitboxes of all of the components in the level (except for background tiles)
  void setDebugMode(bool val) {
    for (var value in descendants()) {
      if (value is BackgroundTile) continue;

      value.debugMode = val;
    }
  }

  //gets mouse position Vector2
  Vector2 get mousePos => _mouseCoords;

  //if parallax effect, this method is called
  void _loadParallaxLevel() {
    int amountOfBackgroundImages =
        (level.tileMap
                .getLayer("Level")
                ?.properties
                .byName["BackgroundImages"]
                ?.value
            as int) ??
        0;

    // Lists to store background images and their corresponding parallax factors.
    // Lists (not Sets) are used to preserve the order — each image must match its parallax factor by index.
    Set<TiledImage> images = {};
    List<Vector2> parralaxFactors = [];
    List<Vector2> startPositions = [];
    ImageLayer? imageLayer;

    // Loop through all background image layers defined in Tiled.
    // Background image layers are expected to be named "background1", "background2", etc.
    for (int i = 1; i <= amountOfBackgroundImages; i++) {
      // Try to get the image layer from the Tiled map.
      imageLayer = level.tileMap.getLayer("background$i") as ImageLayer;
      imageLayer.visible =
          false; // Disable visibility in the Tiled layer — we’ll render it manually for the parallax effect.
      images.add(imageLayer.image);
      // Retrieve the custom parallax factor property from the image layer.
      // If not found, default to 0.3.
      parralaxFactors.add(
        Vector2(
          imageLayer.parallaxX.toDouble(),
          imageLayer.parallaxY.toDouble(),
        ),
      );
      startPositions.add(
        Vector2(imageLayer.offsetX.toDouble(), imageLayer.offsetY.toDouble()),
      );
    }


    // Add a custom LayeredImageBackground component that will handle rendering
    // parallax background images with different scrolling speeds.
    // Pass in the camera and the start position for background rendering.
    add(
      LayeredImageBackground(
        images,
        game.cam,
        parallaxFactors: parralaxFactors,
        startPositions: startPositions,
      ),
    );
  }
}
