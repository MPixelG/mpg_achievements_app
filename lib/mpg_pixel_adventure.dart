import 'dart:async';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flame/palette.dart';
import 'package:flame_riverpod/flame_riverpod.dart';
import 'package:flutter/cupertino.dart' hide AnimationStyle, Image;
import 'package:mpg_achievements_app/components/camera/AdvancedCamera.dart';
import 'package:mpg_achievements_app/components/entity/isometricPlayer.dart';
import 'package:mpg_achievements_app/components/level/isometric/isometric_level.dart';
import 'package:mpg_achievements_app/components/level/orthagonal/orthogonal_level.dart';
import 'package:mpg_achievements_app/components/entity/player.dart';
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
        CollisionCallbacks,
        RiverpodGameMixin
        {


  ///Game components
  late final AdvancedCamera cam;
  late final Player player;
  late Enemy enemy = Enemy(enemyCharacter: 'Virtual Guy');
  late final Level level;
  final GuiEditor guiEditor = GuiEditor();
  late JoystickComponent joystick;

  //bools for game logic
  //needs to go into the overlay_controller later
  bool showDialogue = true;

  //can be added for touch support
  late String platform;

  //Future is a value that is returned even thought a value of the method is not computed immediately, but later
  //FutureOr works same here either returns a Future or <void>
  @override
  FutureOr<void> onLoad() async {
    //all images for the game are loaded into cache when the game start -> could take long at a later stage, but here it is fine for moment being
    await images.loadAllImages();
    //world is loaded after initialising all images

    String levelName = "level_7";

    String orientation = await getOrientationOfLevel(levelName);

    if(orientation == "orthogonal"){
      player = Player(playerCharacter: 'Pink Man');
      level = OrthogonalLevel(levelName: levelName, player: player);
    } else if(orientation == "isometric"){
      player = IsometricPlayer(playerCharacter: 'Pink Man');
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

    return super.onLoad();
  }

  @override
  void onMount() {
    super.onMount();
  }

  @override
  void update(double dt) {
    super.update(dt);
  }


  ///Joystick Component
  //Making a Joystick if the platform is not web or desktop
  void addJoystick() async {
    final knobPaint = BasicPalette.blue.withAlpha(200).paint();
    final backgroundPaint = BasicPalette.blue.withAlpha(100).paint();
    joystick = JoystickComponent(
      knob: CircleComponent(radius: 20, paint: knobPaint),
      background: CircleComponent(radius: 80, paint: backgroundPaint),
      margin: const EdgeInsets.only(left: 40, bottom: 40),
    );

    final buttonComponent = ButtonComponent(
      button: CircleComponent(radius: 20, paint: knobPaint),
      buttonDown: RectangleComponent(
        size: Vector2(40, 40),
        paint: BasicPalette.red.withAlpha(200).paint(),
      ),
      position: Vector2(500, size.y - 380),
      onPressed: () {
      print('Button Pressed');
      },
    );

    /*oystick = JoystickComponent(
      knob: SpriteComponent(sprite: await Sprite.load('HUD/Knob.png'),
          size: Vector2(40, 40)),
      background: SpriteComponent(
        sprite: await Sprite.load('HUD/Joystick.png'),
        size: Vector2(128, 128),
      ),
      margin: const EdgeInsets.only(left: 32, bottom: 32),
    );*/
    cam.viewport.add(joystick);
    cam.viewport.add(buttonComponent);
  }
  Vector2 get tilesizeIso => Vector2.all(level.tileSize.x);
  Vector2 get tilesizeOrtho => level.tileSize;
}

