import 'dart:async';
import 'dart:io' show Platform;
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'package:mpg_achievements_app/components/player.dart';
import 'components/level.dart';

//DragCallbacks are imported for touch controls
class PixelAdventure extends FlameGame
    with HasKeyboardHandlerComponents, DragCallbacks, HasCollisionDetection {
  late final CameraComponent cam;

  //Player variable
  Player player = Player(character: 'Ninja Frog');
  late JoystickComponent joystick;
  //can be added for touch support
  late String platform;
  bool showJoystick = false;

  //Future is a value that is returned even thought a value of the method is not computed immediately, but later
  //FutureOr works same here either returns a Future or <void>
  @override
  FutureOr<void> onLoad() async {
    //all images for the game are loaded into cache when the game start -> could take long at a later stage, but here it is fine for moment being
    showJoystick = _getPlatform();
    await images.loadAllImages();
    //world is loaded after initialising all images
    final world = Level(levelName: 'Level_0', player: player);
    cam = CameraComponent.withFixedResolution(
      world: world,
      width: 640,
      height: 360,
    );
    cam.viewfinder.anchor = Anchor.topLeft;
    addAll([cam, world]);
    if (showJoystick == true) {
      addJoystick();
    } else {
      if (kDebugMode) {
        print("Kein Joystick");
      }
    }

    return super.onLoad();
  }

  @override
  void update(double dt) {
    if (showJoystick == true) {
      updateJoystick();
    }

    super.update(dt);
  }

  //Making a Joystick
  void addJoystick() async {
    joystick = JoystickComponent(
      knob: SpriteComponent(sprite: Sprite(images.fromCache('HUD/Knob.png'))),
      background: SpriteComponent(
        sprite: Sprite(images.fromCache('HUD/Joystick.png')),
      ),
      //Joystick needs a margin
      margin: const EdgeInsets.only(left: 32, bottom: 32),
    );
    add(joystick);
  }

  void updateJoystick() {
    switch (joystick.direction) {
      case JoystickDirection.left:
        player.velocity.x += -1;
        break;
      case JoystickDirection.upLeft:
      case JoystickDirection.downLeft:
      case JoystickDirection.right:
        player.horizontalMovement = 1;
        break;
      case JoystickDirection.downRight:
      case JoystickDirection.upRight:
      case JoystickDirection.up:
      default:
        player.horizontalMovement = 0;
    }
  }

  //check which platform is used and if the touch controls must be shown, TODO right settings must be set here;
  bool _getPlatform() {
    bool os = false;
    if (kIsWeb) {
      os = false;
    } else if (Platform.isAndroid) {
      os = true;
    } else if (Platform.isIOS) {
      os = true;
    }
    return os;
  }
}
