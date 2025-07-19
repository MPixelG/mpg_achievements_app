import 'dart:async';
import 'dart:io' show Platform;
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/cupertino.dart' hide AnimationStyle;
import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'package:mpg_achievements_app/components/camera/AdvancedCamera.dart';
import 'package:mpg_achievements_app/components/player.dart';
import 'components/enemy.dart';
import 'components/level.dart';

//DragCallbacks are imported for touch controls
class PixelAdventure extends FlameGame
    with HasKeyboardHandlerComponents, DragCallbacks, HasCollisionDetection, ScrollDetector{

  late final AdvancedCamera cam;

  //Player variable
  Player player = Player(playerCharacter: 'Pink Man');

  late Enemy enemy = Enemy(enemyCharacter: 'Virtual Guy');
  //can be added for touch support
  late String platform;
  bool showJoystick = false;
  late JoystickComponent joystick;

  //Future is a value that is returned even thought a value of the method is not computed immediately, but later
  //FutureOr works same here either returns a Future or <void>
  @override
  FutureOr<void> onLoad() async {
    //all images for the game are loaded into cache when the game start -> could take long at a later stage, but here it is fine for moment being
    showJoystick = _getPlatform();
    await images.loadAllImages();
    //world is loaded after initialising all images

    final world = Level(levelName: 'Level_2', player: player, enemy);

    cam = AdvancedCamera(world: world);
    cam.player = player;
    cam.viewfinder.anchor = Anchor.center;
    addAll([cam, world]);


    cam.setFollowPlayer(true, player: player, accuracy: 50); //follows the player.
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
      player.jump();
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
