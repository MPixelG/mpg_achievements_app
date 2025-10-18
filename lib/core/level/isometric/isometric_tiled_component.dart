import 'package:flame/extensions.dart';
import 'package:flame_tiled/flame_tiled.dart';

import '../rendering/chunk_grid.dart';
import '../rendering/game_tile_map.dart';
import 'isometric_renderable.dart';

// A data class designed to hold all the necessary information for rendering a single object,

// Instead of letting Flame render layer by layer, this component deconstructs the map
// into a list of individual `RenderInstance` objects
class IsometricTiledComponent extends TiledComponent { //todo improve rendering as soon as we only have IsometricTiledComponent in the game
  IsometricTiledComponent(super.map);

  late GameTileMap gameTileMap;
  late ChunkGrid chunks;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    gameTileMap = GameTileMap(tileMap.map);
    gameTileMap.init();
    chunks = ChunkGrid(gameTileMap);
    // Pre-build the tile cache for efficient rendering later reading data from the Tiled map (every layer every tile)
  }

  void renderComponentsInTree(
    Canvas canvas,
    List<IsometricRenderable> components,
    Vector2 position,
    Vector2 viewportSize,
  ) {
    chunks.render(canvas, components, position, viewportSize);
  }

  void forceRebuildCache() {}
}