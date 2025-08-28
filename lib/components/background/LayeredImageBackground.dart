import 'dart:async';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:mpg_achievements_app/components/background/Background.dart';
import 'package:mpg_achievements_app/components/camera/AdvancedCamera.dart';
import 'package:mpg_achievements_app/components/level/level.dart';
import 'package:mpg_achievements_app/mpg_pixel_adventure.dart';

class LayeredImageBackground extends Background with HasGameReference<PixelAdventure>{

  AdvancedCamera camera;
  Set<TiledImage> tiledImages;

  late Set<Image> loadedImages = {};
  bool imagesLoaded = false;
  late List<Vector2>? parallaxFactors = [];

  List<Vector2> startPositions;

  LayeredImageBackground(this.tiledImages, this.camera, {this.parallaxFactors, required this.startPositions});

  Paint _paint = Paint();

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    priority = -1;


    for (var tiledImage in tiledImages) {
      if (tiledImage.source != null) {
        int lastSlash = tiledImage.source!.lastIndexOf("/");
        String newString = tiledImage.source!.substring(lastSlash+1);

        loadedImages.add(await game.images.load("sky/$newString"));
        imagesLoaded = true;
      }
    }

  }

  @override
  void render(Canvas canvas) {
    if (imagesLoaded) {


      for (int i = 0; i < loadedImages.length; i++) {
        final loadedImage = loadedImages.elementAt(i);

        Vector2 parralaxFactor = parallaxFactors?.elementAt(i) ?? Vector2.all(1);

        final cameraOffset = (startPositions[i] + ((camera.viewfinder.position.clone()..multiply(Vector2.all(1) - parralaxFactor))));

        canvas.drawImage(loadedImage, cameraOffset.toOffset(), _paint);
        canvas.drawImage(loadedImage, cameraOffset.toOffset() - Offset(loadedImage.size.x-1, 0), _paint);
        canvas.drawImage(loadedImage, cameraOffset.toOffset() + Offset(loadedImage.size.x-1, 0), _paint);
      }

    }

    super.render(canvas);
  }


  factory LayeredImageBackground.ofLevel(Level level, AdvancedCamera cam){

    int amountOfBackgroundImages =
        (level.level.tileMap
            .getLayer("Level")
            ?.properties
            .byName["BackgroundImages"]
            ?.value
        as int);

    // Lists to store background images and their corresponding parallax factors.
    // Lists (not Sets) are used to preserve the order — each image must match its parallax factor by index.
    Set<TiledImage> images = {};
    List<Vector2> parralaxFactors = [];
    List<Vector2> startPositions = [];
    ImageLayer? imageLayer;

    // Loop through all background image layers defined in Tiled.
    // Background image layers are expected to be named "background1", "background2", etc.
    for (int i = 1; i <= amountOfBackgroundImages; i++) {
      // Try to get the image layer from the Tiled map.
      imageLayer = level.level.tileMap.getLayer("background$i") as ImageLayer;
      imageLayer.visible =
      false; // Disable visibility in the Tiled layer — we’ll render it manually for the parallax effect.
      images.add(imageLayer.image);
      // Retrieve the custom parallax factor property from the image layer.
      // If not found, default to 0.3.
      parralaxFactors.add(
        Vector2(
          imageLayer.parallaxX.toDouble(),
          imageLayer.parallaxY.toDouble(),
        ),
      );
      startPositions.add(
        Vector2(imageLayer.offsetX.toDouble(), imageLayer.offsetY.toDouble()),
      );
    }


    // Add a custom LayeredImageBackground component that will handle rendering
    // parallax background images with different scrolling speeds.
    // Pass in the camera and the start position for background rendering.


    return LayeredImageBackground(
        images,
        cam,
        parallaxFactors: parralaxFactors,
        startPositions: startPositions,
      );
  }
}