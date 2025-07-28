import 'dart:async';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:mpg_achievements_app/components/camera/AdvancedCamera.dart';
import 'package:mpg_achievements_app/mpg_pixel_adventure.dart';

class LayeredImageBackground extends Component with HasGameReference<PixelAdventure>{

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
}