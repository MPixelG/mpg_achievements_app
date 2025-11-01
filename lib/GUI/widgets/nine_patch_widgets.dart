import 'dart:ui' as ui;

import 'package:flame/flame.dart';
import 'package:flutter/cupertino.dart';

class NinePatchContainer extends Container {
  NinePatchContainer({super.key});
}

class NinePatchTexture {
  ui.Image? texture;
  String imageName = "";

  final int borderX;
  final int borderY;
  final int borderX2;
  final int borderY2;

  bool isLoaded = false;

  NinePatchTexture(
    this.imageName,
    this.borderX,
    this.borderY,
    this.borderX2,
    this.borderY2,
  ) {
    Flame.images.load('Menu/Buttons/$imageName.png').then((image) {
      texture = image;
      isLoaded = true;
    });

    _cache[imageName] = this;
  }

  static final Map<String, NinePatchTexture> _cache = {};

  factory NinePatchTexture.loadFromCache(String imageName) {
    if (_cache.containsKey(imageName)) {
      // If the texture is already in the cache, return it
      return _cache[imageName]!;
    }

    throw Exception(
      'NinePatchTexture for $imageName not found in cache. Please create it first.',
    );
  }

  static bool existsInCache(String name) => _cache[name] != null;

  static List<String> getLoadedTextureNames() => _cache.keys.toList();

  static bool currentlyLoading = false;
  static void loadTextures() async {
    final List<NinePatchTexture> textures = [
      NinePatchTexture("button_0", 3, 3, 3, 3),
      NinePatchTexture("test_button", 3, 3, 3, 3),
      NinePatchTexture("test_button_2", 3, 3, 3, 3),
    ];
    currentlyLoading = true;
    await Future.doWhile(() async {
      await Future.delayed(
        const Duration(milliseconds: 10),
      ); // Check every 100ms

      bool allLoaded = true;
      for (var texture in textures) {
        if (texture.texture == null) {
          allLoaded = false;
          break;
        }
      }

      return allLoaded;
    });

  }
}
