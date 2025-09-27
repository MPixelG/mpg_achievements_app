import 'package:flame/extensions.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:mpg_achievements_app/components/level/isometric/isometric_renderable.dart';
import 'package:mpg_achievements_app/components/level/rendering/chunk_grid.dart';
import 'package:mpg_achievements_app/components/level/rendering/game_tile_map.dart';

// An enumeration to categorize renderable objects.
enum RenderCategory { tile, tileHighlight, entity, effect }

// A data class designed to hold all the necessary information for rendering a single object,
class RenderInstance {
  // A function reference that knows how to draw the object.
  final void Function(Canvas, {Vector2 position, Vector2 size}) render;
  final void Function(Canvas, {Vector2 position, Vector2 size})? renderNormal;
  final Vector2 screenPos;
  final Vector3 gridPos;
  // The layer index from the Tiled map. This serves as the primary sorting key
  final RenderCategory category;
  RenderInstance(
    this.render,
    this.screenPos,
    this.gridPos,
    this.category, {
    this.renderNormal,
  });
}

// Instead of letting Flame render layer by layer, this component deconstructs the map
// into a list of individual `RenderInstance` objects
class IsometricTiledComponent extends TiledComponent {
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

  List<RenderInstance>? lastRenderables;
  Iterable<IsometricRenderable>? lastComponents;
  void renderComponentsInTree(
    Canvas canvas,
    Iterable<IsometricRenderable> components,
    Vector2 position,
    Vector2 viewportSize,
  ) {
    chunks.render(canvas, components, position, viewportSize);
  }

  void forceRebuildCache() {}
}
