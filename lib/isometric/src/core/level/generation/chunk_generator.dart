import 'dart:async';

import '../rendering/chunk.dart';

abstract interface class ChunkGenerator {
  Future<Chunk> generateChunk(int chunkX, int chunkZ);
}