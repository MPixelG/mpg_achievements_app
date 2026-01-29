
import 'package:flame_tiled/flame_tiled.dart';
import 'package:thermion_flutter/thermion_flutter.dart';

//just a test of whats possible with filament / thermion

Future<ThermionAsset?> getMeshOfChunk(Chunk chunk) async {

  (await (FilamentApp.instance!.renderableManager.createVertexBufferBuilder()..attribute(VertexAttribute.POSITION, 0, VertexAttributeType.BYTE)).build());
  
  
}