import 'dart:async';

import 'package:flame/events.dart';
import 'package:flutter/material.dart' hide AnimationStyle, Image;
import 'package:flutter_joystick/flutter_joystick.dart';
import 'package:mpg_achievements_app/core/base_game.dart';
import 'package:mpg_achievements_app/core/dialogue_utils/dialogue_character.dart';
import 'package:mpg_achievements_app/core/dialogue_utils/dialogue_screen.dart';
import 'package:mpg_achievements_app/core/dialogue_utils/text_overlay.dart';
import 'package:mpg_achievements_app/core/touch_controls/touch_controls.dart';
import 'package:mpg_achievements_app/isometric/src/core/physics/hitbox3d/has_collision_detection.dart';
import 'package:mpg_achievements_app/isometric/src/core/physics/hitbox3d/iso_collision_callbacks.dart';
import 'package:thermion_flutter/thermion_flutter.dart';
import 'package:vector_math/vector_math_64.dart' as v64;


//DragCallbacks are imported for touch controls
class PixelAdventure3D extends BaseGame
    with
        HasKeyboardHandlerComponents,
        DragCallbacks,
        HasCollisionDetection3D,
        ScrollDetector,
        IsoCollisionCallbacks{
  static ThermionViewer? _3DGameViewer;
  
  static PixelAdventure3D? _currentInstance;
  
  static PixelAdventure3D get currentInstance {
    _currentInstance ??= PixelAdventure3D();
    return _currentInstance!;
  }


  void setThermionViewer(ThermionViewer viewer) {
    _3DGameViewer = viewer;
    print("🔌 3D Engine linked to Flame Game!");
  }
  
  //storage for the 3D Object
  dynamic helmetAsset;
  v64.Vector3 helmetPosition = v64.Vector3(0.0, 0.0, -5.0);
  double rotationAngle = 0.0;



  //Future is a value that is returned even thought a value of the method is not computed immediately, but later
  //FutureOr works same here either returns a Future or <void>
  @override
  FutureOr<void> onLoad() async {
    musicManager.playRandomMusic();
    musicManager.setVolume(0.4);
    super.onLoad();
  }
  
  @override
  void onMount() {
    overlays.toggle('touchControls');
    super.onMount();
  }


//todo implement more here, at the moment only placehoilder
  @override
  void update(double dt) {
    super.update(dt);
    if (_3DGameViewer == null || helmetAsset == null) return;

    //Joystick Y (Up/Down) to 3D Y (Up/Down)
    //Joystick X (Left/Right) to 3D X (Left/Right)

    if (currentJoystickMoveX == 0 && currentJoystickMoveY == 0) return;
  
    const moveSpeed = 5.0; // Meters per second

    //1 Update our local position state
    helmetPosition.x += currentJoystickMoveX * moveSpeed * dt;
    helmetPosition.y += -currentJoystickMoveY * moveSpeed *
        dt; // -Y is usually down in 2D, check directions

    // 2create empty matrix
    final matrix = v64.Matrix4.identity();
    //3set position
    matrix.setTranslation(helmetPosition);

    //low-level FilamentApp is necessary because TViewer is only viewer
    final int entityID = (helmetAsset as dynamic).entity;
    FilamentApp.instance?.setTransform(entityID, matrix);

    //todo 5 Thermion, later in bridge class

    // Example: Rotate the camera every frame if the viewer is ready
    // if (_thermionViewer != null) {
    //    // game logic here
    // }
  }
  double currentJoystickMoveX = 0;
  double currentJoystickMoveY = 0;
  void onJoystickMove(StickDragDetails details){
    currentJoystickMoveX = details.x;
    currentJoystickMoveY = details.y;
  }

  @override
  Map<String, Widget Function(BuildContext, BaseGame)>? buildOverlayMap() => {
    'TextOverlay': (BuildContext context, BaseGame game) => TextOverlay(
      game: game,
      onTextOverlayDone: () {
        game.overlays.remove("TextOverlay");
      },
    ),
    'DialogueScreen': (BuildContext context, BaseGame game) => DialogueScreen(
      game: game,
      //when Dialogue is finishes screen is removed form map
      onDialogueFinished: () {
        game.overlays.remove('DialogueScreen');
      },
      yarnFilePath:
      'assets/yarn/test.yarn', //todo connect to state management and trigger method, make more customizable not static as atm
    ),
    'touchControls': (BuildContext context, BaseGame game) => TouchControls(
        onJoystickMove: (game as PixelAdventure3D).onJoystickMove,
    )
  };

    // TODO: implement findCharacterByName
  @override
  DialogueCharacter? findCharacterByName(String name) => null;
  
  
}
ThermionViewer? get thermion => PixelAdventure3D._3DGameViewer;