import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:mpg_achievements_app/components/level/isometric/isometric_renderable.dart';
import 'package:mpg_achievements_app/components/level/rendering/chunk.dart';

import '../../../mpg_pixel_adventure.dart';
import 'game_tile_map.dart';

class ChunkGrid {
  Map<Vector2, Chunk> chunks = {};

  GameTileMap gameTileMap;
  ChunkGrid(this.gameTileMap){
    generateChunks();
  }

  void render(Canvas canvas, Iterable<IsometricRenderable> components, Vector2 camPos, Vector2 viewportSize, [Offset offset = Offset.zero]){
    for (var value in chunks.entries) {
      Chunk chunk = value.value;
      Vector2 chunkPos = Vector2(
        (chunk.x - chunk.y + 3) * Chunk.chunkSize * tilesize.x / 2,
        (chunk.x + chunk.y) * Chunk.chunkSize * tilesize.z / 2 ,
      );
      chunkPos += offset.toVector2();
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

      chunk.render(canvas, components, chunkPos.toOffset());
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
}