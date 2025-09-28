import 'dart:async';
import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/extensions.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flame/palette.dart';
import 'package:flame_riverpod/flame_riverpod.dart';
import 'package:flutter/material.dart' hide AnimationStyle, Image;
import 'package:mpg_achievements_app/components/camera/AdvancedCamera.dart';
import 'package:mpg_achievements_app/components/util/utils.dart';
import 'components/level_components/enemy.dart';
import 'core/level/game_world.dart';
import 'core/level/isometric/isometric_world.dart';
import 'core/level/orthogonal/orthogonal_world.dart';

//DragCallbacks are imported for touch controls
class PixelAdventure extends FlameGame
    with
        HasKeyboardHandlerComponents,
        DragCallbacks,
        HasCollisionDetection,
        ScrollDetector,
        CollisionCallbacks,
        RiverpodGameMixin {
  static PixelAdventure? _currentInstance;

  static PixelAdventure get currentInstance {
    _currentInstance ??= PixelAdventure();

    return _currentInstance!;
  }

  ///Game components
  late final AdvancedCamera cam;
  late Enemy enemy = Enemy(enemyCharacter: 'Virtual Guy');
  late final GameWorld gameWorld;
  late JoystickComponent joystick;
  late String currentLevel = "Level_8";

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
    Vector2 tileSize = await getTilesizeOfLevel(currentLevel);
    String orientationOfLevel = await getOrientationOfLevel(currentLevel);

    if (orientationOfLevel == "orthogonal") {
      gameWorld = OrthogonalWorld(
        levelName: currentLevel,
        calculatedTileSize: tileSize.xyy,
      );
    } else if (orientationOfLevel == "isometric") {
      gameWorld = IsometricWorld(
        levelName: currentLevel,
        calculatedTileSize: tileSize.xxy,
      ); //on the horizontal axis, the tile is rectangular. on the side its half the size (z-axis)
    } else {
      throw UnimplementedError(
        "an orientation of $orientationOfLevel isn't implemented! please use either orthogonal or isometric!",
      );
    }

    cam = AdvancedCamera(world: gameWorld);
    cam.viewfinder.anchor = Anchor.center;
    await addAll([cam, gameWorld]);

    //add overlays
    overlays.add('TextOverlay');

   await add(_FollowCameraComponent()); //helper class to follow the player after the world and player are loaded
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

  double scrollFactor = 1.0;
  double zoomFactor = 1.0;
  @override
  void onScroll(PointerScrollInfo info) {
    scrollFactor += info.scrollDelta.global.y;
    zoomFactor = pow(0.9, scrollFactor / 30).toDouble();
  }
}

Vector3 get tilesize =>
    PixelAdventure.currentInstance.gameWorld.calculatedTileSize;

Vector2 get screenSize =>
    PixelAdventure.currentInstance.cam.visibleWorldRect.toVector2();

//helper class to follow the player after the world and player are loaded
class _FollowCameraComponent extends Component
    with HasGameReference<PixelAdventure> {
  @override
  void onMount() {
    super.onMount();
    // Now that the world is mounted, we know its player exists.
    game.cam.player = game.gameWorld.player;
    game.cam.setFollowPlayer(true, player: game.gameWorld.player, accuracy: 50);
    // This component's only job is to run once, so we remove it immediately.
    removeFromParent();
  }
}
