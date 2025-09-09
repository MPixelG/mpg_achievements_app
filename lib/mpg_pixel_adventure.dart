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
import 'package:mpg_achievements_app/components/entity/player.dart';
import 'package:mpg_achievements_app/components/util/utils.dart';
import 'components/GUI/menuCreator/components/gui_editor.dart';
import 'components/level/orthogonal/orthogonal_world.dart';
import 'components/level_components/enemy.dart';
import 'components/level/game_world.dart';
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
  late final GameWorld gameWorld;
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
    Vector2 tileSize = await getTilesizeOfLevel(levelName);
    String orientationOfLevel = await getOrientationOfLevel(levelName);

    if(orientationOfLevel == "orthogonal"){
      player = Player(playerCharacter: 'Pink Man');
      gameWorld = OrthogonalWorld(levelName: levelName, player: player, tileSize: tileSize);
    } else if(orientationOfLevel == "isometric"){
      player = IsometricPlayer(playerCharacter: 'Pink Man');
      gameWorld = IsometricWorld(levelName: levelName, player: player, tileSize: tileSize );
    } else {
      throw UnimplementedError(
          "an orientation of $orientationOfLevel isn't implemented! please use either orthogonal or isometric!");
    }


    cam = AdvancedCamera(world: gameWorld);
    cam.player = player;
    cam.viewfinder.anchor = Anchor.center;
    await addAll([cam, gameWorld]);

    //add overlays
    overlays.add('TextOverlay');

    cam.setFollowPlayer(
      true,
      player: player,
      accuracy: 50,
    ); //follows the player.

    return super.onLoad();
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

    cam.viewport.add(joystick);
    cam.viewport.add(buttonComponent);
  }
  Vector2 get tilesizeIso => Vector2.all(gameWorld.tileSize.x);
  Vector2 get tilesizeOrtho => gameWorld.tileSize;
}

