import 'package:flame/extensions.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:mpg_achievements_app/components/level/isometric/isometric_renderable.dart';
import 'package:mpg_achievements_app/components/level/rendering/game_tile_map.dart';

// An enumeration to categorize renderable objects.
enum RenderCategory {
  tile,
  tileHighlight,
  entity
}

// A data class designed to hold all the necessary information for rendering a single object,
class RenderInstance {

  // A function reference that knows how to draw the object.
  final void Function(Canvas, {Vector2 position, Vector2 size}) render;
  final Image? texture;
  final Image? normal;
  final Vector2 screenPos;
  final Vector2 gridPos;
  // The layer index from the Tiled map. This serves as the primary sorting key
  final int zIndex;
  final RenderCategory category;
  RenderInstance(this.render, this.screenPos, this.zIndex, this.gridPos, this.category, [this.texture, this.normal]);
}


// Instead of letting Flame render layer by layer, this component deconstructs the map
// into a list of individual `RenderInstance` objects
class IsometricTiledComponent extends TiledComponent{
  IsometricTiledComponent(super.map);

  late GameTileMap gameTileMap;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    gameTileMap = GameTileMap(tileMap.map);
  }

  void renderComponentsInTree(Canvas canvas, Iterable<IsometricRenderable> components) {
  }
}