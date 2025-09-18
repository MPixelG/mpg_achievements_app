import 'dart:math';
import 'dart:ui' as ui;

import 'package:flame/extensions.dart';
import 'package:flame/flame.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:mpg_achievements_app/components/level/isometric/isometric_renderable.dart';
import 'package:mpg_achievements_app/components/level/rendering/game_tile_map.dart';
import 'package:mpg_achievements_app/mpg_pixel_adventure.dart';

// An enumeration to categorize renderable objects.
enum RenderCategory {
  tile,
  tileHighlight,
  entity,
  effect,
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
  bool _corrupted = true;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    gameTileMap = GameTileMap(tileMap.map);
    await loadShader();
    updateShaderUniforms(Vector2(100, 100), Vector2.zero(), game.size, 0);
    // Pre-build the tile cache for efficient rendering later reading data from the Tiled map (every layer every tile)
  }

  late ui.FragmentProgram program;
  late ui.FragmentShader shader;
  late final ui.Paint shaderPaint;

  Future<void> loadShader() async {
    final program = await ui.FragmentProgram.fromAsset('assets/shaders/lighting.frag');
    shader = program.fragmentShader();
    shader.setImageSampler(0, Flame.images.fromCache(
        "Pixel_ArtTop_Down/basic_isometric_block_normal.png"));
    shader.setImageSampler(1, Flame.images.fromCache(
        "Pixel_ArtTop_Down/basic_isometric_block_normal.png"));

    shaderPaint = ui.Paint()..shader = shader;
  }

  void updateShaderUniforms(Vector2 lightPos, Vector2 tilePos, Vector2 screenSize, double tilePosZ) {
    shader.setFloatUniforms((value) {
      value.setFloats([lightPos.x, lightPos.y]);
      value.setFloats([tilePos.x, tilePos.y]);
      value.setFloats([screenSize.x, screenSize.y]);
      value.setFloats([tilePosZ]);
    },);
  }


  List<RenderInstance>? lastRenderables;
  Iterable<IsometricRenderable>? lastComponents;
  void renderComponentsInTree(Canvas canvas, Iterable<IsometricRenderable> components) {

    if(lastComponents != components || lastRenderables == null || _corrupted){ //only recalculate if the components have changed
      lastComponents = components;
      lastRenderables = calculateSortedRenderInstances(components);
    }


    for (final r in lastRenderables!) { //render everything in the sorted order


      if (r.texture == null) {
        r.render(canvas, position: r.screenPos - tilesize.xy / 2,
            size: tilesize.xy);
      } else {
        shader.setImageSampler(0, r.texture!);
        shader.setImageSampler(1, r.normal!);


        updateShaderUniforms(
            (game as PixelAdventure).gameWorld.mousePos - Vector2.all(10),
            r.screenPos - (tilesize.xy / 2),
            tilesize.xy,
            r.zIndex * tilesize.z
        );

        canvas.drawRect(
          Rect.fromPoints((r.screenPos - (tilesize.xy / 2)).toOffset(), (r.screenPos - (tilesize.xy / 2) + tilesize.xy).toOffset()),
          shaderPaint,
        );
      }
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
    _corrupted = false;
    print("resorted allRenderables");
    return allRenderables;
  }

  void forceRebuildCache(){
    _corrupted = true;
  }

}
extension on Vector3 {
  int compareTo(Vector3 gridPos) {
    return (distanceTo(Vector3.zero()).compareTo(gridPos.distanceTo(Vector3.zero())));
  }
}