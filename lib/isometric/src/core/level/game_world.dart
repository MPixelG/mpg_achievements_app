import 'dart:async';
import 'dart:developer';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/extensions.dart';
import 'package:flame_riverpod/flame_riverpod.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:mpg_achievements_app/core/router/router.dart';
import 'package:mpg_achievements_app/3d/src/level/tiled_level_loader.dart';
import 'package:mpg_achievements_app/isometric/src/mpg_pixel_adventure.dart';
import 'package:mpg_achievements_app/util/isometric_utils.dart';

import '../../components/background/scrolling_background.dart';
import '../../components/level_components/entity/enemy/ai/isometric_tile_grid.dart';
import '../../components/level_components/entity/enemy/ai/pathfinder.dart';
import '../../components/level_components/entity/enemy/enemy.dart';
import '../../components/level_components/entity/player.dart';
import 'isometric/isometric_tiled_component.dart';

abstract class GameWorld extends World
    with
        HasGameReference<PixelAdventure>,
        KeyboardHandler,
        PointerMoveCallbacks,
        TapCallbacks,
        RiverpodComponentMixin {
  final String levelName;
  late TiledComponent level;
  late Player player;
  late Player player2;
  late Enemy enemy;
  int totalCollectables = 0;
  late final ScrollingBackground background;

  Vector3 calculatedTileSize;

  //reference to the tile grid for finding tapped tile
  late final IsometricTileGrid tileGrid;

  //loads when the class instantiated
  //In dart, late keyword is used to declare a variable or field that will be initialized at a later time.e.g. late String name
  //
  //constructor
  GameWorld({
    required this.levelName,
    ScrollingBackground? background,
    required this.calculatedTileSize,
  }) {
    if (background != null) this.background = background;
  }

  late POIGenerator generator;

  @override
  FutureOr<void> onLoad() async {
    await super.onLoad();
    //await need to be there because it takes some time to load, that's why the method needs to be async
    //otherwise the rest of the programme would stop
    // Load the Tiled map for the current level.
    // Determine if the level is isometric based on the game world's type.
    level = IsometricTiledComponent(
      (await TiledComponent.load('$levelName.tmx', tilesize.xz)).tileMap,
    );
    level.position = Vector2.zero();

    //add player
    await add(game.gameWorld.player);
    await add(game.gameWorld.player2);
       //add player to the list of component in the game
    game.npcs[game.gameWorld.player.playerCharacter] = game.gameWorld.player; //todo more refactor necessary e.g. method od instanitating IsoComponents
    game.npcs[game.gameWorld.player2.playerCharacter] = game.gameWorld.player2;
    print(player.playerCharacter);
    print(player2.playerCharacter);
    // Add the level to the game world so it gets rendered.
    await add(level);

    //_loadScrollingBackground();

    generator = POIGenerator(
      this,
    ); // Initialize the POI generator with the current level
    await add(generator); // Add the POI generator to the game world

    //spawn objects
   // generateSpawningObjectsForLevel(this);
    //add collision objects
  //  generateCollisionsForLevel(this);

    // Debug mode off by default
    add(debugOverlays);
    debugOverlays.scale = Vector2.zero(); // Start hidden/scaled down
    debugOverlays.priority = 2; // Ensure overlays draw above the rest of the game

    // Set dynamic movement bounds for the camera, allowing smooth tracking of the player.
    //game.cam.setMoveBounds(Vector2.zero(), level.size);

    //runs all the other onLoad-events the method is referring to, now not important
    await super.onLoad();
  }

  //creating a background dynamically

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
      );
    } //press N to shake the camera

    if (keysPressed.contains(LogicalKeyboardKey.keyH)) {
      AppRouter.router.pushNamed("widgetBuilder");
    } //press H to toggle the GUI editor overlay

    if (keysPressed.contains(LogicalKeyboardKey.f3)) {//toggle debug mode
      setDebugMode(!debugMode);
    }

    // Debug test for SpeechBubble
    if (keysPressed.contains(LogicalKeyboardKey.keyB)) {
      // A method to toggle the speech bubble
      game.conversationManager.startConversation('assets/yarn/speechbubble_test.yarn');

    }

    //overlaydebug
    if(keysPressed.contains(LogicalKeyboardKey.keyO)){
    final registeredOverlays = game.overlays.registeredOverlays;
    print('--- Overlay Status ---');
    if (registeredOverlays.isEmpty) {
      print('Registered (static) Overlays: None');
    } else {
      print('Registered (static) Overlays: $registeredOverlays');
    }

    // 2. Get the keys of all currently active (visible) overlays.
    // This includes static overlays that are "on" and any dynamic
    // overlays added with addEntry().
    final activeOverlays = game.overlays.activeOverlays;
    if (activeOverlays.isEmpty) {
      print('Active (visible) Overlays: None');
    } else {
      print('Active (visible) Overlays: $activeOverlays');
    }
    print('----------------------');
  }

    // Debug test for Dialogue
    if (keysPressed.contains(LogicalKeyboardKey.keyQ)) {
      // A method to toggle the speech bubble
      game.overlays.add('DialogueScreen');
    }
    return super.onKeyEvent(event, keysPressed);
  }

  Vector2 _mouseCoords = Vector2.zero();

  @override
  void onPointerMove(PointerMoveEvent event) {
    _mouseCoords = event.localPosition..round();
    //player.mouseCoords = _mouseCoords;
  }

  @override
  void onTapDown(TapDownEvent event) {
    super.onTapDown(event);
    //_highlightedTile?.removeFromParent();
    final Vector2 screenPositionTap = event.localPosition; //screen position of the tap
    final Vector2 worldPositionTap = level.toLocal(screenPositionTap);
    //selectedTile = toGridPos(worldPositionTap)..floor();
    //final Vector2 calculatedGridPos = toGridPos(worldPositionTap);
    //final Vector2 worldPositionTile = toWorldPos(calculatedGridPos);
    final Vector2 clickGridPos = toGridPos(worldPositionTap);

    //highlight the selected tile
    // _highlightedTile = TileHighlightRenderable(selectedTile!);
    // _highlightedTile?.position = toWorldPos(selectedTile!) - Vector2(0, tileSize.y/2);

    // add(_highlightedTile!);

    // ---  Debugging Logs ---
    //POI generator
    // print(generator.grid.isBlocked(clickGridPos..floor()));
    // print("world pos: $worldPositionTap");
    //mouse pos -> grid po
    //print("grid pos: ${clickGridPos}\n\n");
    //print('Screen Position of Tap: $screenPositionTap');
    print('Camera Position: ${game.cam.pos}, Zoom: ${game.cam.givenZoom}');
    //print('World Position of Tap (Calculated): $worldPositionTap');
    //print('Calculated Grid Position (Decimal): $calculatedGridPos');
    //print('Selected Tile (Floored): $selectedTile');
    //print('Logical World Position of Selected Tile: $worldPositionTile \n\n');
    //print('highlighted tile pos: ${_highlightedTile?.position}');

    //clickGridPos.clamp(Vector2.zero(), Vector2(level.width / tileSize.x - 1, level.height / tileSize.y - 1));

    if (clickGridPos.x > 0 &&
        clickGridPos.y > 0 &&
        clickGridPos.x < (level.tileMap.map.width) &&
        clickGridPos.y < (level.tileMap.map.height)) {
      inspectTile(clickGridPos.x.toInt(), clickGridPos.y.toInt());
    }
  }

  @override //update the overlays
  void update(double dt) {
    if (debugOverlays.scale == Vector2.zero()) return;

    final Vector3 roundedPlayerPos = player.position.clone()..round();
    final Vector3 roundedPlayerHeadPos = player.gridHeadPos.clone()..round();
    final Vector3 roundedPlayerSize = player.size.clone()..round();
    final Vector3 roundedPlayerSizeScaled = player.size.clone()..multiply(tilesize)..round();

    final String playerCoords = roundedPlayerPos.toString();
    final String playerHeadCoords = roundedPlayerHeadPos.toString();
    final String playerSize = roundedPlayerSize.toString();
    final String playerSizeScaled = roundedPlayerSizeScaled.toString();
    debugOverlays.text =
        "Player: $playerCoords\n"
        "Player Head: $playerHeadCoords\n"
        "Player size (unscaled): $playerSize\n"
        "Player size (scaled): $playerSizeScaled\n"
        "Mouse: $_mouseCoords\n"
        "Grid Mouse Coords isometric: ${toGridPos(_mouseCoords)..floor()} \n"
        "Grid Mouse coords Orthogonal: ${(mousePos.x / tilesize.x).floor()}, ${(mousePos.y / tilesize.y).floor()}\n"
        "CurrentZ ground:${player.zGround}\n";
    debugOverlays.position =
        game.cam.pos - game.cam.visibleWorldRect.size.toVector2() / 2;

    super.update(dt);
  }

  //sets the visibility of all of the hitboxes of all of the components in the level (except for background tiles)
  void setDebugMode(bool val) {
    debugMode = val;
    for (var value in descendants()) {
      value.debugMode = val;
    }
  }

  //gets mouse position Vector2
  Vector2 get mousePos => _mouseCoords;

  void _loadScrollingBackground() {
    final Layer? backgroundLayer = level.tileMap.getLayer('Level');
    String backgroundColor = "Blue";
    if (backgroundLayer != null) {
      backgroundColor = backgroundLayer.properties.getValue('BackgroundColor') ?? "Green";
    }

    final ScrollingBackground background = ScrollingBackground(
      color: backgroundColor,
    );
    background.priority = -3;

    add(background);
  }

  //Important for reading information from tiles -> needs to go into utils
  void inspectTile(int x, int y) {
    if(!kDebugMode) return;

    //get map object
    final map = level.tileMap.map;

    //get layer
    final layer = map.layerByName('Ground') as TileLayer?;

    if (layer == null) {
      log('Layer not found!');
      return;
    }

    //get tileId
    // IMPORTANT: The data is stored in [row][column] format, so it's [y][x]
    final Gid? gid = layer.tileData?[y][x];

    // Check if a tile exists there
    if (gid == null || gid.tile == 0) {
      log('No tile at ($x, $y)');
    } else {
      log('Tile at ($x, $y) has GID: ${gid.tile}');
    }

    // 1. Use the map's helper function to get the tileset for this GID
    final tileset = level.tileMap.map.tilesetByTileGId(gid!.tile);
    log("${tileset.firstGid}");

    // get localID of tile
    ///GID (Global ID): A map-wide unique identifier for a tile. It's what's stored in the layer data. Its primary job is to be unique across all tilesets. GID 0 is always "empty".
    /// Local ID: A tileset-specific identifier, always starting from 0 for the first tile in that tileset. It's used to look up a tile's data (like custom properties) within its own tileset.
    final localId = gid.tile - tileset.firstGid!;

    // 3. Get the Tile object from the tileset using the local ID
    final tile = tileset.tiles[localId];

    // 4. Access the properties
    final properties = tile.properties;

    if (properties.isNotEmpty) {
      log('Properties for tile at ($x, $y):');
      for (var property in properties) {
        log('  - ${property.name}: ${property.value}');
      }
    }
  }

  bool checkCollisionAt(Vector3 gridPos);
}
