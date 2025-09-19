import 'dart:math';
import 'dart:ui';
import 'dart:ui' as ui;

import 'package:flame/extensions.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:mpg_achievements_app/components/entity/player.dart';
import 'package:mpg_achievements_app/components/level/rendering/game_tile_map.dart';
import 'package:mpg_achievements_app/main.dart';

import '../../../mpg_pixel_adventure.dart';
import '../isometric/isometric_renderable.dart';
import '../isometric/isometric_tiled_component.dart';

class GBuffer {
  Image? normalAndDepthMap;
  Image? albedoMap;

  bool _corrupted = true;

  void setCorrupted() => _corrupted = true;

  GameTileMap gameTileMap;
  GBuffer(this.gameTileMap){
    setupPaintShader();
  }


  List<RenderInstance>? lastRenderables;
  Iterable<IsometricRenderable>? lastComponents;


  ui.Paint paint = ui.Paint();
  Paint depthMapPaint = Paint()..blendMode = BlendMode.srcOver;
  late FragmentShader? shader;
  void setupPaintShader() async{
    FragmentProgram program = await FragmentProgram.fromAsset("assets/shaders/lighting.frag");
    shader = program.fragmentShader();
  }

  void _renderComponentsInTree(Canvas canvas, Iterable<IsometricRenderable> components) {
    buildMaps(components);
    if(normalAndDepthMap != null && albedoMap != null && shader != null) {
      double width = gameTileMap.tiledMap.width * tilesize.x;
      double height = gameTileMap.tiledMap.height * tilesize.y;

      Vector2 mousePos = gameWidgetKey.currentState!.currentGame.gameWorld.mousePos;

      Player player = gameWidgetKey.currentState!.currentGame.gameWorld.player;

      double x = player.absoluteCenter.x / width;
      double y = player.absoluteCenter.y / height;
      double z = 1.5;


      shader!.setImageSampler(0, albedoMap!);
      shader!.setImageSampler(1, normalAndDepthMap!);
      shader!.setFloatUniforms((value) {
        value.setFloats([width, height]);
        value.setFloats([x, y, z]);
        value.setFloats([gameTileMap.totalZLayers * tilesize.z / width]);
      });

      paint.shader ??= shader;
      canvas.drawRect(Rect.fromPoints(Offset.zero, Offset(width.toDouble(), height)), paint);
      //canvas.drawImage(normalAndDepthMap!, Offset.zero, paint);

      //to draw a little light bulb at the current light
      // canvas.drawLine(Offset(x * width, y * height), Offset(x * width, y * height - z * tilesize.z + 5), Paint()..color = Colors.white70);
      // canvas.drawCircle(Offset(x * width, y * height - z * tilesize.z), 3, Paint()..color = Colors.white70);

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

  void buildMaps(Iterable<IsometricRenderable> components){
    lastComponents = components;
    lastRenderables = calculateSortedRenderInstances(components);
    buildAlbedoMap();
    buildNormalAndDepthMap();
    _corrupted = false;
  }




  void buildNormalAndDepthMap() async{
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    for (final r in lastRenderables!) { //render everything in the sorted order
      if(r.normal != null) {
        canvas.drawImage((r.normal!), (r.screenPos - tilesize.xz/2).toOffset(), depthMapPaint);
      }
    }

    final picture = recorder.endRecording();
    normalAndDepthMap = await picture.toImage(((gameTileMap.tiledMap.width+1) * tilesize.x).toInt(), ((gameTileMap.tiledMap.height+1) * tilesize.y).toInt());
  }

  void buildAlbedoMap() async{
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);


    for (final r in lastRenderables!) { //render everything in the sorted order
      r.render(canvas, position: r.screenPos - tilesize.xz/2,
          size: tilesize.xy);
    }

    final picture = recorder.endRecording();
    albedoMap = await picture.toImage(((gameTileMap.tiledMap.width+1) * tilesize.x).toInt(), ((gameTileMap.tiledMap.height+1) * tilesize.y).toInt());
  }

  void render(Canvas canvas, Iterable<IsometricRenderable> components){
    _renderComponentsInTree(canvas, components);
  }

}


extension on Vector3 {
  int compareTo(Vector3 gridPos) {
    return (distanceTo(Vector3.zero()).compareTo(gridPos.distanceTo(Vector3.zero())));
  }
}
