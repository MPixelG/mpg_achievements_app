import 'dart:async';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'levels/level.dart';

class PixelAdventure extends FlameGame {

  late final CameraComponent cam;
  final world = Level();
  //Future is a value that is returned even thought a value of the method is not computed immediately, but later
  //FutureOr works same here either returns a Future or <void>
  @override
  FutureOr<void> onLoad() {

    cam = CameraComponent.withFixedResolution(world: world, width: 640, height: 360);
    cam.viewfinder.anchor = Anchor.topLeft;
    addAll([cam,world]);
    return super.onLoad();
  }
}