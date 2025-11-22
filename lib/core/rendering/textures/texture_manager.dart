import 'package:mpg_achievements_app/core/rendering/textures/game_texture_batch.dart';

class TextureManager {
  final Map<String, GameTextureBatch> _textures = {};

  void loadTexture(String id, String path) async{
    // Load texture from path and store it in the map
    _textures[id] = await loadTextureBatchFromFile(path);
  }

  GameTextureBatch? getTexture(String id) => _textures[id];

  void unloadTexture(String id) {
    _textures.remove(id)?.dispose();
  }
}