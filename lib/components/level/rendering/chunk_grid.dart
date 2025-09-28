import 'dart:math';
import 'dart:ui';

import 'package:flame/extensions.dart';
import 'package:mpg_achievements_app/components/level/isometric/isometric_renderable.dart';
import 'package:mpg_achievements_app/components/level/rendering/chunk.dart';

import '../../../mpg_pixel_adventure.dart';
import 'game_tile_map.dart';

class ChunkGrid {
  static const double chunkSpacing = 0;

  Map<Vector2, Chunk> chunks = {};

  GameTileMap gameTileMap;
  ChunkGrid(this.gameTileMap) {
    generateChunks();
    if(!shaderInitialized && !shaderBeingInitialized){
      shaderBeingInitialized = true;
      initShader();
    }
  }

  void generateChunks() {
    final map = gameTileMap.tiledMap;
    final chunkCountX = (map.width / Chunk.chunkSize).ceil();
    final chunkCountY = (map.height / Chunk.chunkSize).ceil();

    for (int x = 0; x < chunkCountX; x++) {
      for (int y = 0; y < chunkCountY; y++) {
        final chunk = Chunk.fromGameTileMap(gameTileMap, x, y, 0);
        chunks[Vector2(x.toDouble(), y.toDouble())] = chunk;
      }
    }
  }

  NeighborChunkCluster getNeighborChunkCluster(Chunk chunk) {
    final cx = chunk.x;
    final cy = chunk.y;
    Chunk? tl = chunks[Vector2((cx - 1).toDouble(), (cy - 1).toDouble())];
    Chunk? t = chunks[Vector2(cx.toDouble(), (cy - 1).toDouble())];
    Chunk? tr = chunks[Vector2((cx + 1).toDouble(), (cy - 1).toDouble())];
    Chunk? r = chunks[Vector2((cx + 1).toDouble(), cy.toDouble())];
    Chunk? br = chunks[Vector2((cx + 1).toDouble(), (cy + 1).toDouble())];
    Chunk? b = chunks[Vector2(cx.toDouble(), (cy + 1).toDouble())];
    Chunk? bl = chunks[Vector2((cx - 1).toDouble(), (cy + 1).toDouble())];
    Chunk? l = chunks[Vector2((cx - 1).toDouble(), cy.toDouble())];
    return NeighborChunkCluster(
      topLeft: tl,
      top: t,
      topRight: tr,
      right: r,
      bottomRight: br,
      bottom: b,
      bottomLeft: bl,
      left: l,
    );
  }

  bool currentlyRebuilding = false;
  Future<void> buildMaps(
      Iterable<IsometricRenderable> components,
      Vector2 camPos,
      Vector2 viewportSize,[
        Offset offset = Offset.zero,
      ]) async {
    if(currentlyRebuilding) return;
    currentlyRebuilding = true;

    PictureRecorder albedoRecorder = PictureRecorder();
    PictureRecorder normalRecorder = PictureRecorder();

    Canvas normalCanvas = Canvas(normalRecorder);
    Canvas albedoCanvas = Canvas(albedoRecorder);

    Vector2 posTL = -camPos + (viewportSize/2);
    albedoCanvas.translate(posTL.x, posTL.y);
    normalCanvas.translate(posTL.x, posTL.y);
    albedoCanvas.save();
    normalCanvas.save();

    for (var value in chunks.entries) {
      Chunk chunk = value.value;

      Vector2 chunkPos = Vector2(
        ((chunk.x - chunk.y + 3) * (Chunk.chunkSize + chunkSpacing)) *
            tilesize.x / 2,
        (chunk.x + chunk.y) * (Chunk.chunkSize + chunkSpacing) * tilesize.z / 2,
      );
      chunkPos += offset.toVector2();
      chunkPos.y -= chunk.zHeightUsedPixels;
      Vector2 unPositionedChunkPos = chunkPos - camPos + (viewportSize / 2);

      if (unPositionedChunkPos.x < 0) {
        double chunkPosR = unPositionedChunkPos.x + Chunk.chunkSize*tilesize.x;
        if (chunkPosR < 0) {
          continue;
        }
      }
      if (unPositionedChunkPos.y < 0) {
        double chunkPosB = unPositionedChunkPos.y + Chunk.chunkSize*tilesize.z;
        if (chunkPosB < 0) {
          continue;
        }
      }
      if (unPositionedChunkPos.x > viewportSize.x) {
        continue;
      }
      if (unPositionedChunkPos.y > viewportSize.y) {
        continue;
      }

      Vector2 drawPos;
      if (chunk.albedoWorldTopLeft != null) {
        drawPos = chunk.albedoWorldTopLeft!;
      } else {
        drawPos = chunkPos;
      }
      drawPos = chunkPos;

      albedoCanvas.save();
      normalCanvas.save();

      albedoCanvas.translate(drawPos.x, drawPos.y);
      normalCanvas.translate(drawPos.x, drawPos.y);

      chunk.render(
        albedoCanvas,
        normalCanvas,
        components,
        getNeighborChunkCluster(chunk),
      );

      albedoCanvas.restore();
      normalCanvas.restore();

      currentlyRebuilding = false;

      //canvas.drawLine((chunkPos - Vector2(0, chunk.zHeightUsedPixels.toDouble())).toOffset(), chunkPos.toOffset(), Paint()..color = Colors.green);
    }

    await Future.wait([
      normalRecorder.endRecording().toImage(viewportSize.x.toInt(), viewportSize.y.toInt()).then((value) => fullNormal = value),
      albedoRecorder.endRecording().toImage(viewportSize.x.toInt(), viewportSize.y.toInt()).then((value) => fullAlbedo = value)
    ]);
  }

  Image? fullAlbedo;
  Image? fullNormal;

  Paint shaderPaint = Paint();
  bool shaderInitialized = false;
  bool shaderBeingInitialized = false;

  void render(
    Canvas canvas,
    Iterable<IsometricRenderable> components,
    Vector2 camPos,
    Vector2 viewportSize, [
    Offset offset = Offset.zero,
      ]) {

    buildMaps(components, camPos, viewportSize);

    if(fullAlbedo == null || fullNormal == null || shader == null) return;

    shader!.setImageSampler(0, fullAlbedo!);
    shader!.setImageSampler(1, fullNormal!);
    shader!.setFloatUniforms((val) {
      val.setFloats([
        viewportSize.x, viewportSize.y,
        10, 100, 100,
        0.5,
      ]);
    });

    shaderPaint.shader = shader;
    Vector2 posTL = camPos - (viewportSize/2);
    canvas.save();
    canvas.translate(posTL.x, posTL.y);
    canvas.drawRect(viewportSize.toRect(), shaderPaint);
    canvas.restore();
    // canvas.drawImage(fullAlbedo!, posTL.toOffset(), Paint());

    components.where((element) => element.updatesNextFrame).forEach((element) {
      element.updatesNextFrame = false;
      //element.setDirty(false);
    });

    for (final c in chunks.values) {
      c.isUsedByNeighbor = false;
    }
  }


  FragmentShader? shader;
  void initShader() async{
    FragmentProgram program = await FragmentProgram.fromAsset("assets/shaders/lighting.frag");
    shader = program.fragmentShader();
  }
}
