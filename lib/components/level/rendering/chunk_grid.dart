import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:mpg_achievements_app/components/level/isometric/isometric_renderable.dart';
import 'package:mpg_achievements_app/components/level/rendering/chunk.dart';

import '../../../mpg_pixel_adventure.dart';
import 'game_tile_map.dart';

class ChunkGrid {
  static const double CHUNK_SPACING = 0;

  Map<Vector2, Chunk> chunks = {};

  GameTileMap gameTileMap;
  ChunkGrid(this.gameTileMap){
    generateChunks();
  }

  NeighborChunkCluster getNeighborChunkCluster(Chunk chunk){
    Chunk? tl = chunks[Vector2(chunk.x - 1, chunk.y - 1)];
    Chunk? t = chunks[Vector2(chunk.x.toDouble(), chunk.y - 1)];
    Chunk? tr = chunks[Vector2(chunk.x + 1, chunk.y + 1)];
    Chunk? r = chunks[Vector2(chunk.x + 1, chunk.y.toDouble())];
    Chunk? bl = chunks[Vector2(chunk.x - 1, chunk.y - 1)];
    Chunk? b = chunks[Vector2(chunk.x.toDouble(), chunk.y + 1)];
    Chunk? br = chunks[Vector2(chunk.x + 1, chunk.y + 1)];
    Chunk? l = chunks[Vector2(chunk.x - 1, chunk.y.toDouble())];
    return NeighborChunkCluster(topLeft: tl, top: t, topRight: tr, right: r, bottomLeft: bl, bottom: b, bottomRight: br, left: l);
  }

  void render(Canvas canvas, Iterable<IsometricRenderable> components, Vector2 camPos, Vector2 viewportSize, [Offset offset = Offset.zero]){
    for (var value in chunks.entries) {
      Chunk chunk = value.value;
      Vector2 chunkPos = Vector2(
        ((chunk.x - chunk.y + 3) * (Chunk.chunkSize + CHUNK_SPACING)) * tilesize.x / 2,
        (chunk.x + chunk.y) * (Chunk.chunkSize + CHUNK_SPACING) * tilesize.z / 2 ,
      );
      chunkPos += offset.toVector2();
      chunkPos.y -= chunk.zHeightUsedPixels;
      Vector2 unPositionedChunkPos = chunkPos - camPos + viewportSize / 2;

      if(unPositionedChunkPos.x < 0){
        double chunkPosR = unPositionedChunkPos.x + Chunk.chunkSize * tilesize.x;
        if(chunkPosR < 0){
          continue;
        }
      }
      if(unPositionedChunkPos.y < 0){
        double chunkPosB = unPositionedChunkPos.y + Chunk.chunkSize * tilesize.z;
        if(chunkPosB < 0){
          continue;
        }
      }
      if(unPositionedChunkPos.x > viewportSize.x){
        continue;
      }
      if(unPositionedChunkPos.y > viewportSize.y){
        continue;
      }

      chunk.render(canvas, components, getNeighborChunkCluster(chunk), chunkPos.toOffset());
      //canvas.drawLine((chunkPos - Vector2(0, chunk.zHeightUsedPixels.toDouble())).toOffset(), chunkPos.toOffset(), Paint()..color = Colors.green);
    }
    components.where((element) => element.updatesNextFrame).forEach((element) {
      element.updatesNextFrame = false;
      //element.setDirty(false);
    });

    components.forEach((element) {
    },);

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
}