import 'dart:math';
import 'dart:ui';

import 'package:flame/extensions.dart';
import 'package:mpg_achievements_app/isometric/src/mpg_pixel_adventure.dart';

import '../isometric/isometric_renderable.dart';
import 'chunk.dart';
import 'game_tile_map.dart';
import 'neighbor_chunk_cluster.dart';

class ChunkGrid {
  static const double chunkSpacing = 0;

  Map<Vector2, Chunk> chunks = {};

  GameTileMap gameTileMap;

  bool _needsUpdate = true;
  Future<void>? _currentBuildTask;

  void markForUpdate() => _needsUpdate = true;

  ChunkGrid(this.gameTileMap) {
    generateChunks();
    if (!shaderInitialized && !shaderBeingInitialized) {
      shaderBeingInitialized = true;
      initShader();
    }
  }

  void generateChunks() {
    final map = gameTileMap.tiledMap;
    final chunkCountX = (map.width / Chunk.chunkSize).ceil();
    final chunkCountZ = (map.height / Chunk.chunkSize).ceil();

    for (int x = 0; x < chunkCountX; x++) {
      for (int z = 0; z < chunkCountZ; z++) {
        final chunk = Chunk.fromGameTileMap(gameTileMap, x, 0, z);
        chunks[Vector2(x.toDouble(), z.toDouble())] = chunk;
      }
    }
  }

  NeighborChunkCluster getNeighborChunkCluster(Chunk chunk) {
    final cx = chunk.x;
    final cz = chunk.z;
    final Chunk? tl = chunks[Vector2((cx - 1).toDouble(), (cz - 1).toDouble())];
    final Chunk? t = chunks[Vector2(cx.toDouble(), (cz - 1).toDouble())];
    final Chunk? tr = chunks[Vector2((cx + 1).toDouble(), (cz - 1).toDouble())];
    final Chunk? r = chunks[Vector2((cx + 1).toDouble(), cz.toDouble())];
    final Chunk? br = chunks[Vector2((cx + 1).toDouble(), (cz + 1).toDouble())];
    final Chunk? b = chunks[Vector2(cx.toDouble(), (cz + 1).toDouble())];
    final Chunk? bl = chunks[Vector2((cx - 1).toDouble(), (cz + 1).toDouble())];
    final Chunk? l = chunks[Vector2((cx - 1).toDouble(), cz.toDouble())];
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

  //todo add upscaling
  //todo fix viewport scaling when resizing window
  Future<void> buildMaps(
    List<IsometricRenderable> components,
    Vector2 camPos,
    Vector2 viewportSize, [
    Offset offset = Offset.zero,
  ]) async {
    if (currentlyRebuilding) return;
    currentlyRebuilding = true;

    final PictureRecorder albedoRecorder = PictureRecorder();
    final PictureRecorder normalRecorder = PictureRecorder();

    final Canvas normalCanvas = Canvas(normalRecorder);
    final Canvas albedoCanvas = Canvas(albedoRecorder);

    final Vector2 posTL = -camPos + (viewportSize / 2);
    albedoCanvas.translate(posTL.x, posTL.y);
    normalCanvas.translate(posTL.x, posTL.y);

    for (var value in chunks.entries) {
      final Chunk chunk = value.value;

      Vector2 chunkPos = Vector2(
        ((chunk.x - chunk.z) * (Chunk.chunkSize + chunkSpacing)) * tilesize.x / 2,
        (chunk.x + chunk.z) * (Chunk.chunkSize + chunkSpacing) * tilesize.z / 2,
      );
      chunkPos += offset.toVector2();
      chunkPos.y -= chunk.yHeightUsedPixels;
      final Vector2 unPositionedChunkPos = chunkPos - camPos + (viewportSize / 2);

      if (unPositionedChunkPos.x < 0) {
        continue;
      }
      if (unPositionedChunkPos.y < 0) {
        continue;
      }
      if (unPositionedChunkPos.x > viewportSize.x) {
        continue;
      }
      if (unPositionedChunkPos.y > viewportSize.y) {
        continue;
      }

      final Vector2 drawPos = chunk.albedoWorldTopLeft ?? chunkPos;

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
    }

    await Future.wait([
      normalRecorder
          .endRecording()
          .toImage(viewportSize.x.toInt(), viewportSize.y.toInt())
          .then((value) => lastNormal = value),
      albedoRecorder
          .endRecording()
          .toImage(viewportSize.x.toInt(), viewportSize.y.toInt())
          .then((value) => lastAlbedo = value),
    ]).then((value) {
      fullAlbedo?.dispose();
      fullNormal?.dispose();
      fullAlbedo = lastAlbedo;
      fullNormal = lastNormal;
      currentlyRebuilding = false;
    });
  }

  Image? lastAlbedo;
  Image? lastNormal;

  Image? fullAlbedo;
  Image? fullNormal;

  Paint shaderPaint = Paint();
  bool shaderInitialized = false;
  bool shaderBeingInitialized = false;

  void render(
    Canvas canvas,
    List<IsometricRenderable> components,
    Vector2 camPos,
    Vector2 viewportSize, [
    Offset offset = Offset.zero,
  ]) {
    if (components.length > 1) {
      components.sort((a, b) => depth(a).compareTo(depth(b)));
    }

    if (_needsUpdate && _currentBuildTask == null) {
      _currentBuildTask = buildMaps(components, camPos, viewportSize).then((_) {
        _currentBuildTask = null;
      });
    }
    if (fullAlbedo == null || fullNormal == null || shader == null) return;

    shader!.setImageSampler(0, fullAlbedo!);
    shader!.setImageSampler(1, fullNormal!);

    final double time = DateTime.now().millisecondsSinceEpoch / 10000;
    final double lightX = cos(time) * 300;
    final double lightZ = sin(time) * 300;

    shader!.setFloatUniforms((val) {
      val.setFloats([viewportSize.x, viewportSize.y, lightX, lightZ, 35]);
    });

    shaderPaint.shader = shader;
    final Vector2 posTL = camPos - (viewportSize / 2);
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

  void initShader() async {
    final FragmentProgram program = await FragmentProgram.fromAsset(
      "assets/shaders/lighting.frag",
    );
    shader = program.fragmentShader();
  }
}
