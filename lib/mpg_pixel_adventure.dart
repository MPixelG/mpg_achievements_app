import 'dart:async';
import 'dart:io' show Platform;
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/cupertino.dart' hide AnimationStyle, Image;
import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'package:mpg_achievements_app/components/camera/AdvancedCamera.dart';
import 'package:mpg_achievements_app/components/level/isometric/isometric_level.dart';
import 'package:mpg_achievements_app/components/level/orthagonal/orthogonal_level.dart';
import 'package:mpg_achievements_app/components/player.dart';
import 'package:mpg_achievements_app/components/util/utils.dart';
import 'components/GUI/menuCreator/gui_editor.dart';
import 'components/level_components/enemy.dart';
import 'components/level/level.dart';
//DragCallbacks are imported for touch controls
class PixelAdventure extends FlameGame
    with
        HasKeyboardHandlerComponents,
        DragCallbacks,
        HasCollisionDetection,
        ScrollDetector,
        CollisionCallbacks {
  late final AdvancedCamera cam;

  //Player variable
  Player player = Player(playerCharacter: 'Pink Man');

  late Enemy enemy = Enemy(enemyCharacter: 'Virtual Guy');
  //can be added for touch support
  late String platform;
  bool showJoystick = false;
  late JoystickComponent joystick;

  late final Level level;

  final GuiEditor guiEditor = GuiEditor();

  //needs to go into the overlay_controller later
  bool showDialogue = true;

  //Future is a value that is returned even thought a value of the method is not computed immediately, but later
  //FutureOr works same here either returns a Future or <void>
  @override
  FutureOr<void> onLoad() async {
    //all images for the game are loaded into cache when the game start -> could take long at a later stage, but here it is fine for moment being
    showJoystick = _getPlatform();
    await images.loadAllImages();
    //world is loaded after initialising all images

    String levelName = "level_8";

    String orientation = await getOrientationOfLevel(levelName);

    if(orientation == "orthogonal"){
      level = OrthogonalLevel(levelName: levelName, player: player);
    } else if(orientation == "isometric"){
      level = IsometricLevel(levelName: levelName, player: player);
    } else {
      throw UnimplementedError(
          "an orientation of $orientation isnt implemented! please use either orthagonal or isometric!");
    }


    cam = AdvancedCamera(world: level);
    cam.player = player;
    cam.viewfinder.anchor = Anchor.center;
    addAll([cam, level]);

    //add overlays
    overlays.add('TextOverlay');

    cam.setFollowPlayer(
      true,
      player: player,
      accuracy: 50,
    ); //follows the player.
    if (showJoystick == true) {
      addJoystick();
    } else {
      if (kDebugMode) {}
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

  //check which platform is used and if the touch controls must be shown, TODO right settings must be set here
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
