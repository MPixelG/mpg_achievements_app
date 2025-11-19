import 'package:mpg_achievements_app/core/rendering/textures/game_texture.dart';

class TextureManager {
  final Map<String, GameTexture> _textures = {};

  void loadTexture(String id, String path) {
    // Load texture from path and store it in the map
    _textures[id] = GameTexture.fromPath(assetPath: path);
  }

  GameTexture? getTexture(String id) => _textures[id];

  void unloadTexture(String id) {
    _textures.remove(id)?.dispose();
  }
}