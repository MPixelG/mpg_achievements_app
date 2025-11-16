import '../rendering/chunk.dart';

abstract interface class ChunkGenerator {
  Chunk generateChunk(int chunkX, int chunkZ);
}