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
  late Set<double>? parallaxFactors = {};

  late Vector2? startPos;

  LayeredImageBackground(this.tiledImages, this.camera, {this.parallaxFactors, this.startPos});

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    priority = -1;

    startPos ??= Vector2.zero();

    for (var tiledImage in tiledImages) {
      if (tiledImage.source != null) {
        int lastSlash = tiledImage.source!.lastIndexOf("/");
        String newString = tiledImage.source!.substring(lastSlash+1);

        print(newString);
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

        double parralaxFactor = parallaxFactors?.elementAt(i) ?? 1 / (loadedImages.length-i);

        final cameraOffset = startPos! + (camera.viewfinder.position.clone() + startPos!) * parralaxFactor;

        canvas.drawImage(loadedImage, cameraOffset.toOffset(), Paint());
        canvas.drawImage(loadedImage, cameraOffset.toOffset()- Offset(loadedImage.size.x-1, 0), Paint());
        canvas.drawImage(loadedImage, cameraOffset.toOffset()+ Offset(loadedImage.size.x-1, 0), Paint());
      }

    }

    super.render(canvas);
  }
}