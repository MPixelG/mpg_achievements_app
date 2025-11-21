import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:mpg_achievements_app/core/rendering/textures/animated_game_texture.dart';
import 'package:mpg_achievements_app/core/rendering/textures/game_texture.dart';

class GameTextureBatch {
  final Map<String, Map<double?, GameTexture>> _textures = {};
  late String name;

  GameTextureBatch();
  GameTextureBatch.fromFile(String filePath) {
    loadFromFile(filePath);
  }

  bool ready = false;
  void loadFromFile(String filePath) async {
    final Map<String, dynamic> metadata = await Flame.assets
        .readJson(filePath);
    
    name = metadata['name'] ?? "UnnamedTextureBatch";
    final Vector2 size = Vector2(metadata['width']??32, metadata['height']??32); 
    
    assert(metadata['textures'] is List<Map<String, dynamic>>,
    "Texture batch metadata must contain a valid 'textures' field!");
    
    final List<Map<String, dynamic>> textures = metadata['textures'];
    
    for (final texture in textures) {
      final String textureName = texture['name'] ?? "unnamed Texture";
      final String path = texture['path'];
      final String depthPath = texture['depthMapPath'] ?? "${path.replaceAll(".png", "")}_depth.png";
      final List<double> positionList = texture['position'] ?? [0, 0];
      final Vector2 position = Vector2(positionList[0], positionList[1]);
      final double? rotation = texture['rotation'];
      final Map<String, dynamic>? animationOptions = texture['animation'];
      
      final Image spritesheet = Flame.images.containsKey(path) ? Flame.images.fromCache(path) : await Flame.images.load(path);
      final Image depthSpritesheet = Flame.images.containsKey(depthPath) ? Flame.images.fromCache(depthPath) : await Flame.images.load(depthPath);
      
      _textures[textureName] ??= {};
      if(animationOptions == null) {
        _textures[textureName]![rotation] = GameTexture(spritesheet, depthSpritesheet, textureName, position, size, rotation);
      } else {
        _textures[textureName]![rotation] = AnimatedGameTexture(spritesheet, depthSpritesheet, textureName, position, size, rotation, animationOptions['frames'], animationDirection: animationOptions['direction'], animationType: animationOptions['type']);
      }
    }
    
    
    
    ready = true;
  }
}