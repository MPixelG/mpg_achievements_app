import 'dart:core';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:mpg_achievements_app/core/level/generation/chunk_generator.dart';
import 'package:mpg_achievements_app/core/level/rendering/cached_image_world_map.dart';
import 'package:mpg_achievements_app/mpg_pixel_adventure.dart';
import 'package:mpg_achievements_app/util/isometric_utils.dart';

import '../isometric/isometric_renderable.dart';
import 'chunk.dart';
import 'neighbor_chunk_cluster.dart';

class ChunkGrid {
  Map<Vector2, Chunk> chunks = {};

  CachedImageWorldMap? albedoCache = CachedImageWorldMap();
  CachedImageWorldMap? normalCache = CachedImageWorldMap();

  ChunkGenerator generator;

  ChunkGrid({required this.generator});

  void generateChunksInViewport(Vector2 position, Vector2 size) {
    final Set<Vector2> visibleChunkCoords = chunksVisibleByCamera(position, size);

    for (var coord in visibleChunkCoords) {
      if (!chunks.containsKey(coord)) {
        final Chunk newChunk = generator.generateChunk(coord.x.toInt(), coord.y.toInt());
        chunks[coord] = newChunk;
      }
    }
  }

  static const double viewportExtendPixels = 32;
  static const double upscaleFactor = 1;

  void render(
    Canvas canvas,
    List<IsometricRenderable> components,
    Vector2 position,
    Vector2 viewportSize,
  ) async {
    if (albedoCache != null) {
      if(albedoCache!.image != null) {
        final Vector2 posTL = position - Vector2.all(viewportExtendPixels / upscaleFactor / 2);

        canvas.save();
        canvas.translate(posTL.x, posTL.y);

        canvas.drawImage(albedoCache!.image!, -(posTL - albedoCache!.camPos).toOffset(), Paint());

        canvas.drawCircle((viewportSize / 2).toOffset() -(posTL - albedoCache!.camPos).toOffset(), 15, Paint()..color=const Color(0x887B15B7));

        canvas.drawRect(-(position - albedoCache!.camPos).toOffset() & (viewportSize + Vector2.all(viewportExtendPixels)) .toSize(), Paint()..color = const Color(0x88FF0000)..style=PaintingStyle.stroke..strokeWidth=2);


        canvas.restore();
      } else {
        print("null!");
      }
    } else {
      print("albedoCache is null!");
    }
    for (var component in components) {
      component.renderTree(canvas);
    }
  }


  bool currentlyRebuilding = false;
  Future<void> rebuildCaches(Vector2 position, Vector2 viewportSize) async {
    if (currentlyRebuilding) return;
    currentlyRebuilding = true;

    final Set<Vector2> visibleChunkCoords = chunksVisibleByCamera(position, viewportSize);

    for (var coord in visibleChunkCoords) {
      if (!chunks.containsKey(coord)) {
        final Chunk newChunk = generator.generateChunk(coord.x.toInt(), coord.y.toInt());
        chunks[coord] = newChunk;
      }
    }

    final PictureRecorder albedoRecorder = PictureRecorder();
    final PictureRecorder normalRecorder = PictureRecorder();

    final Canvas albedoCanvas = Canvas(albedoRecorder);
    final Canvas normalCanvas = Canvas(normalRecorder);


    final Vector2 posTL = -position + Vector2.all(viewportExtendPixels / upscaleFactor / 2); //todo adjust in velocity of camera
    albedoCanvas.translate(posTL.x, posTL.y);
    normalCanvas.translate(posTL.x, posTL.y);

    for (var chunk in chunks.values) {

      final Vector2 chunkPos = Vector2(
        ((chunk.x - chunk.z) * (Chunk.chunkSize)) * tilesize.x / 2,
        (chunk.x + chunk.z) * (Chunk.chunkSize) * tilesize.z / 2,
      );
      chunkPos.y -= chunk.yHeightUsedPixels;

      final Vector2 drawPos = chunk.albedoWorldTopLeft ?? chunkPos;

      albedoCanvas.save();
      normalCanvas.save();

      albedoCanvas.translate(drawPos.x, drawPos.y);
      normalCanvas.translate(drawPos.x, drawPos.y);

      chunk.render(
        albedoCanvas,
        normalCanvas,
      );

      albedoCanvas.restore();
      normalCanvas.restore();
    }

    await Future.wait([
      albedoRecorder
          .endRecording()
          .toImage((viewportSize.x).toInt(), (viewportSize.y).toInt())
          .then((value) {
            albedoCache?.dispose();
            albedoCache = CachedImageWorldMap(camPos: position, image: value);
          }),
      normalRecorder
          .endRecording()
          .toImage(viewportSize.x.toInt(), viewportSize.y.toInt())
          .then((value) {
        normalCache?.dispose();
        normalCache = CachedImageWorldMap(camPos: position, image: value);
      }),
    ]);
    currentlyRebuilding = false;
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


  Set<Vector2> chunksVisibleByCamera(Vector2 position, Vector2 size) {
    final Vector2 topLeft = position;
    final Vector2 bottomRight = position + size;
    return chunksInScreenRect(topLeft, bottomRight);
  }

  Set<Vector2> chunksInScreenRect(Vector2 topLeft, Vector2 bottomRight) {
    final Vector2 topLeftWorld = toWorldPos2D(topLeft)..floor();
    final Vector2 bottomRightWorld = toWorldPos2D(bottomRight)..floor();
    return chunksInWorldRect(topLeftWorld, bottomRightWorld);
  }

  Set<Vector2> chunksInWorldRect(Vector2 topLeft, Vector2 bottomRight) {
    final Vector2 topLeftChunk = chunkAtWorldPos(topLeft);
    final Vector2 bottomRightChunk = chunkAtWorldPos(bottomRight);

    final Set<Vector2> chunkCoords = {};

    for (int x = topLeftChunk.x.toInt(); x <= bottomRightChunk.x.toInt(); x++) {
      for (int z = topLeftChunk.y.toInt(); z <= bottomRightChunk.y.toInt(); z++) {
        chunkCoords.add(Vector2(x.toDouble(), z.toDouble()));
      }
    }

    return chunkCoords;
  }

  Vector2 chunkAtWorldPos(Vector2 worldPos) {
    final int chunkX = (worldPos.x / (Chunk.chunkSize * tilesize.x)).floor();
    final int chunkZ = (worldPos.y / (Chunk.chunkSize * tilesize.y)).floor();
    return Vector2(chunkX.toDouble(), chunkZ.toDouble());
  }
}
