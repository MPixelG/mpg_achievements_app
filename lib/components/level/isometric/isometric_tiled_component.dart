import 'dart:math';
import 'dart:ui' as ui;

import 'package:flame/extensions.dart';
import 'package:flame/flame.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:mpg_achievements_app/components/level/isometric/isometric_renderable.dart';
import 'package:mpg_achievements_app/components/level/rendering/g_buffer.dart';
import 'package:mpg_achievements_app/components/level/rendering/game_tile_map.dart';
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

  late GBuffer gBuffer;
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    gBuffer = GBuffer(GameTileMap(tileMap.map));
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

  void renderComponentsInTree(Canvas canvas, Iterable<IsometricRenderable> components) {
    gBuffer.render(canvas, components);
  }
}