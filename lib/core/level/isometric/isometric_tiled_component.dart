import 'dart:async';

import 'package:flame/components.dart' hide Timer;
import 'package:flame/extensions.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:flutter/services.dart';
import 'package:mpg_achievements_app/core/level/generation/chunk_generator.dart';
import 'package:mpg_achievements_app/core/level/generation/tiled_map_generator.dart';
import 'package:mpg_achievements_app/util/utils.dart';

import '../rendering/game_tile_map.dart';
import '../rendering/new_chunk_grid.dart';
import 'isometric_renderable.dart';

// A data class designed to hold all the necessary information for rendering a single object,

// Instead of letting Flame render layer by layer, this component deconstructs the map
// into a list of individual `RenderInstance` objects
class IsometricTiledComponent extends TiledComponent with KeyboardHandler{ //todo improve rendering as soon as we only have IsometricTiledComponent in the game
  IsometricTiledComponent(super.map);

  late GameTileMap gameTileMap;
  late ChunkGrid chunks;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    gameTileMap = GameTileMap(tileMap.map);

    final ChunkGenerator generator = TiledMapGenerator(gameTileMap);
    chunks = ChunkGrid(generator: generator);

    // //update rebuild every 2 seconds to true for testing
    // Timer.periodic(const Duration(seconds: 2), (timer) {
    //   rebuild = true;
    // });



    print(" !! Info! to update the anchor of the buffer, press the F key !! ");
    // Pre-build the tile cache for efficient rendering later reading data from the Tiled map (every layer every tile)
  }

  double virtualZoom = 1;
  void renderComponentsInTree(
    Canvas canvas,
    List<IsometricRenderable> components,
    Vector2 position,
    Vector2 viewportSize
  ) {
    chunks.render(canvas, components, position, viewportSize/virtualZoom, viewportSize, virtualZoom);
  }

  void forceRebuildCache() {}
  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    if(event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.keyF) {
      chunks.rebuild = true;
      return true;
    }
    if(event is! KeyUpEvent && event.logicalKey == LogicalKeyboardKey.numpad4) {
      zoomVelocity+=0.04;
      print("zoom set to $virtualZoom");
      return true;
    }
    if(event is! KeyUpEvent && event.logicalKey == LogicalKeyboardKey.numpad5) {
      zoomVelocity-=0.04;
      print("zoom set to $virtualZoom");
      return true;
    }
    if(event is! KeyUpEvent && event.logicalKey == LogicalKeyboardKey.numpad6) {
      virtualZoom = 1;
      return true;
    }

    if(event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.keyG && keysPressed.contains(LogicalKeyboardKey.f3)) {
      chunks.debugRender = !chunks.debugRender;
      return true;
    }
    return super.onKeyEvent(event, keysPressed);
  }
  
  double zoomVelocity = 0;
  double lastZoom = double.negativeInfinity;
  @override
  void update(double dt){
    zoomVelocity *= 0.9;
    virtualZoom += zoomVelocity;
    if(abs(lastZoom - virtualZoom) > 0.001) {
      chunks.rebuild = true;
      lastZoom = virtualZoom;
      print("rebuilding!");
    }
    if(virtualZoom < 0.1) {
      virtualZoom = 0.1;
      zoomVelocity = 0.03;
    }
  }
}