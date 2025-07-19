import 'dart:async';

import 'package:flame/components.dart';
import 'package:mpg_achievements_app/components/background/Background.dart';
import 'package:mpg_achievements_app/components/camera/AdvancedCamera.dart';
import 'package:mpg_achievements_app/mpg_pixel_adventure.dart';

class LayeredImageBackground extends Background with HasGameReference<PixelAdventure>{

  AdvancedCamera? camera;

  LayeredImageBackground();

  @override
  FutureOr<void> onLoad() {
    camera = game.cam;

    return super.onLoad();
  }


}