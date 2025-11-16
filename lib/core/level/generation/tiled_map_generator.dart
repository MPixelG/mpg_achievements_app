import 'package:mpg_achievements_app/core/level/generation/chunk_generator.dart';
import 'package:mpg_achievements_app/core/level/rendering/chunk.dart';
import 'package:mpg_achievements_app/core/level/rendering/game_tile_map.dart';

class TiledMapGenerator implements ChunkGenerator {
  final GameTileMap tileMap;
  TiledMapGenerator(this.tileMap);
  @override
  Chunk generateChunk(int chunkX, int chunkZ) => Chunk.fromGameTileMap(tileMap, chunkX, 0, chunkZ);



}