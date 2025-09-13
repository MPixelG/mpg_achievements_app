import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flame/flame.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:mpg_achievements_app/components/level/isometric/isometricRenderable.dart';
import 'package:mpg_achievements_app/components/level/rendering/game_tile_map.dart';
import 'package:mpg_achievements_app/components/util/utils.dart';
import 'package:mpg_achievements_app/mpg_pixel_adventure.dart';

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
  final Vector2 screenPos;
  final Vector2 gridPos;
  // The layer index from the Tiled map. This serves as the primary sorting key
  final int zIndex;
  final RenderCategory category;
  RenderInstance(this.render, this.screenPos, this.zIndex, this.gridPos, this.category);
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
    // Pre-build the tile cache for efficient rendering later reading data from the Tiled map (every layer every tile)
  }

  ///Builds a cache of tile render instances for efficient rendering.


  List<RenderInstance>? lastRenderables;
  Iterable<IsometricRenderable>? lastComponents;
  void renderComponentsInTree(Canvas canvas, Iterable<IsometricRenderable> components) {

    if(lastComponents != components || lastRenderables == null) {
      lastComponents = components;
      lastRenderables = calculateSortedRenderInstances(components);
    }

    for (final r in lastRenderables!) { //render everything in the sorted order
      r.render(canvas, position: r.screenPos - tileMap.destTileSize.xx / 2, size: tileMap.destTileSize.xx);
    }

  }

  List<RenderInstance> calculateSortedRenderInstances([Iterable<IsometricRenderable> additionals = const []]){
    final allRenderables = <RenderInstance>[]; //all the renderables that should be rendered, sorted by their z-index and position distance to the 0-point
    allRenderables.addAll(gameTileMap.renderableTiles); //add all tiles
    allRenderables.addAll(additionals.map((e) => RenderInstance((c, {Vector2? position, Vector2? size}) => e.renderTree(c), e.position, e.renderPriority, e.gridFeetPos, e.renderCategory))); //add all given components to the list of renderables so that they are also sorted and rendered in the correct order


    allRenderables.sort((a, b) { //now we sort the renderables by their z-index and position
      Vector3 pos1 = Vector3(a.gridPos.x, a.gridPos.y,
          a.zIndex.toDouble() * tilesize.z);
      Vector3 pos2 = Vector3(b.gridPos.x, b.gridPos.y,
          b.zIndex.toDouble() * tilesize.z);

      int comparedPos = pos1.compareTo(pos2); //compare the foot y positions

      if (comparedPos != 0) {
        return comparedPos;
      }

      // ...use the category as the definitive tie-breaker.
      return a.category.index.compareTo(b.category.index);
    });
    return allRenderables;
  }
}
extension on Vector3 {
  int compareTo(Vector3 gridPos) {
    return (distanceTo(Vector3.zero()).compareTo(gridPos.distanceTo(Vector3.zero())));
  }
}