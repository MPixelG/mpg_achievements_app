import 'dart:async';

import 'package:mpg_achievements_app/isometric/src/core/level/generation/chunk_generator.dart';
import 'package:mpg_achievements_app/isometric/src/core/level/rendering/chunk.dart';
import 'package:mpg_achievements_app/isometric/src/core/level/rendering/game_tile_map.dart';


class TiledMapGenerator implements ChunkGenerator {
  final GameTileMap tileMap;
  TiledMapGenerator(this.tileMap);
  @override
  Future<Chunk> generateChunk(int chunkX, int chunkZ) async => Chunk.fromGameTileMap(tileMap, chunkX, 0, chunkZ);



}