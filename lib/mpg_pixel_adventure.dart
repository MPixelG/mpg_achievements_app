import 'dart:async';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'levels/level.dart';

class PixelAdventure extends FlameGame {

  late final CameraComponent cam;
  @override
  final world = Level(levelName: 'Level_1');
  //Future is a value that is returned even thought a value of the method is not computed immediately, but later
  //FutureOr works same here either returns a Future or <void>
  @override
  FutureOr<void> onLoad() async{
    //all images for the game are loaded into cache when the game start -> could take long at a later stage, but here it is fine for moment being
    await images.loadAllImages();
    cam = CameraComponent.withFixedResolution(world: world, width: 640, height: 360);
    cam.viewfinder.anchor = Anchor.topLeft;
    addAll([cam,world]);

    return super.onLoad();
  }
}