import 'dart:async';

import 'package:flame/events.dart';
import 'package:flame/flame.dart';
import 'package:flutter/material.dart' hide AnimationStyle, Image;
import 'package:flutter_joystick/flutter_joystick.dart';
import 'package:mpg_achievements_app/3d/src/camera.dart';
import 'package:mpg_achievements_app/3d/src/components/player.dart';
import 'package:mpg_achievements_app/core/base_game.dart';
import 'package:mpg_achievements_app/core/dialogue_utils/dialogue_character.dart';
import 'package:mpg_achievements_app/core/dialogue_utils/dialogue_screen.dart';
import 'package:mpg_achievements_app/core/dialogue_utils/text_overlay.dart';
import 'package:mpg_achievements_app/core/touch_controls/touch_controls.dart';
import 'package:mpg_achievements_app/isometric/src/core/level/tiled_level_loader.dart';
import 'package:mpg_achievements_app/isometric/src/core/physics/hitbox3d/has_collision_detection.dart';
import 'package:mpg_achievements_app/isometric/src/core/physics/hitbox3d/iso_collision_callbacks.dart';
import 'package:thermion_flutter/thermion_flutter.dart';
import 'package:xml/xml.dart';

import '../../isometric/src/core/level/tiled_level.dart';


//DragCallbacks are imported for touch controls
class PixelAdventure3D extends BaseGame
    with
        HasKeyboardHandlerComponents,
        DragCallbacks,
        HasCollisionDetection3D,
        ScrollDetector,
        IsoCollisionCallbacks{


  //Singleton
  static PixelAdventure3D? _currentInstance;
  static PixelAdventure3D get currentInstance {
  _currentInstance ??= PixelAdventure3D();
  return _currentInstance!;
  }

  //reference to ThermionViewer
  static ThermionViewer? _3DGameViewer;
  void setThermionViewer(ThermionViewer viewer) {
    _3DGameViewer = viewer;
    print("🔌 3D Engine linked to Flame Game!");
    }

  //level attributes
  TiledLevel? _levelData;
  late String levelPath = 'tiles/3D_prototype.tmx';

  //gameworld -> purely for logic no visuals
  //late final GameWorld gameWorld;

  //storage for the 3D Object
  dynamic helmetAsset;
  Vector3 helmetPosition = Vector3(0.0, 0.0, -5.0);
  double rotationAngle = 0.0;



  //Future is a value that is returned even thought a value of the method is not computed immediately, but later
  //FutureOr works same here either returns a Future or <void>
  @override
  FutureOr<void> onLoad() async {
    final String tmxContent = await Flame.assets.readFile(levelPath);
    final XmlDocument xmlDoc = XmlDocument.parse(tmxContent); //fails since the asset file is somehow not published to github, it cant find the file
    _levelData = await TiledLevel.loadXML(xmlDoc, filename: 'tiles/3D_prototype.tmx', fileReader: (String path) async => await Flame.assets.readFile(path));

    loadAmbientLighting("assets/3D/default_env_ibl.ktx");
    setSkybox("assets/3D/default_env_skybox.ktx");
    
    print('Level');
    print(_levelData!.layers.length);
    print(_levelData!.tilesetData.keys.toList());
    await _trySpawnTest();
    
    add(GameCamera(await thermion!.getActiveCamera()));
    
    add(Player(size: Vector3.all(1)));
    


    super.onLoad();
  }
  
  @override
  void onMount() {
    overlays.toggle('touchControls');
    super.onMount();
  }


//todo implement more here, at the moment only placeholder
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
    helmetPosition.y += -currentJoystickMoveY * moveSpeed * dt; // -Y is usually down in 2D, check directions

    // 2create empty matrix
    final matrix = Matrix4.identity();
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
  
  Future<void> _trySpawnTest() async{
    final loader = LevelLoader(levelData: _levelData!, viewer: _3DGameViewer!);
    await loader.spawnTiles();
    await loader.spawnObjects();
  }
  
  Future<void> setSkybox(String skyboxPath) async{
    await thermion!.loadSkybox(skyboxPath);
  }
  Future<void> loadAmbientLighting(String iblPath, [double intensity = 30000]) async{
    assert(thermion != null, "thermion isn't initialized yet!");
    await thermion?.loadIbl(iblPath, intensity: intensity);
    print("loaded lighting");
  }
  
}
ThermionViewer? get thermion => PixelAdventure3D._3DGameViewer;