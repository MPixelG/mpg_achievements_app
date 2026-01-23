import 'dart:async';

import 'package:flame/camera.dart';
import 'package:flame/events.dart' hide PointerMoveEvent;
import 'package:flame/flame.dart';
import 'package:flutter/material.dart' hide AnimationStyle, Image, KeyEvent;
import 'package:flutter/services.dart';
import 'package:flutter_joystick/flutter_joystick.dart';
import 'package:mpg_achievements_app/3d/src/camera.dart';
import 'package:mpg_achievements_app/3d/src/components/npc.dart';
import 'package:mpg_achievements_app/3d/src/components/player.dart';
import 'package:mpg_achievements_app/3d/src/level/entity_factory.dart';
import 'package:mpg_achievements_app/3d/src/level/tiled_level_loader.dart';
import 'package:mpg_achievements_app/core/base_game.dart';
import 'package:mpg_achievements_app/core/dialogue_utils/conversation_management.dart';
import 'package:mpg_achievements_app/core/dialogue_utils/dialogue_character.dart';
import 'package:mpg_achievements_app/core/dialogue_utils/dialogue_containing_game.dart';
import 'package:mpg_achievements_app/core/dialogue_utils/dialogue_screen.dart';
import 'package:mpg_achievements_app/core/dialogue_utils/text_overlay.dart';
import 'package:mpg_achievements_app/core/touch_controls/touch_controls.dart';
import 'package:mpg_achievements_app/isometric/src/core/physics/hitbox3d/has_collision_detection.dart';
import 'package:thermion_flutter/thermion_flutter.dart' hide KeyEvent;
import 'package:xml/xml.dart';

import 'components/entity.dart';
import 'level/tiled_level.dart';


//DragCallbacks are imported for touch controls
class PixelAdventure3D extends BaseGame
    with
        HasKeyboardHandlerComponents,
        DragCallbacks,
        HasCollisionDetection3D,
        ScrollDetector,
        DialogueContainingGame {
  
  @override
  @Deprecated("This camera is only for 2D!")
  CameraComponent get camera;

  @override
  @Deprecated("This camera is only for 2D!")
  set camera(CameraComponent newCamera);
  
  late GameCamera camera3D; 
  
  late Player player;


  //Singleton
  static PixelAdventure3D? _currentInstance;

  static PixelAdventure3D get currentInstance {
    _currentInstance ??= PixelAdventure3D();
    return _currentInstance!;
  }

  //Map for entities
  final Map<int, Entity> entityMap = {};
  final Map<String, DialogueCharacter> dCharacterMap = {};

  //reference to ThermionViewer
  static late ThermionViewer? _3DGameViewer;
  //reference to camera
  static late GameCamera? _gameCamera;

  void setThermionViewer(ThermionViewer viewer) {
    _3DGameViewer = viewer;
  }

  //Managers and stuff for speechBubble
  late final ConversationManager conversationManager;
  final ValueNotifier<Offset?> speechBubblePos = ValueNotifier(null);

  //level attributes
  TiledLevel? _levelData;
  late String levelPath = 'tiles/3D_prototype.tmx';

  //gameworld -> purely for logic no visuals
  //late final GameWorld gameWorld;


  //Future is a value that is returned even thought a value of the method is not computed immediately, but later
  //FutureOr works same here either returns a Future or <void>
  @override
  FutureOr<void> onLoad() async {
    //Registering factories for different types of entities, they are stored in the _builders-map
    EntityFactory.register('Npc', (Vector3 pos, Vector3 size, String name,
        Map<String, dynamic> props) {
      final String assetPath = props['model_path'].toString();

      return Npc(
        position: pos,
        size: size,
        name: name ?? 'Unknown',
        modelPath: assetPath,
      );
    });

    EntityFactory.register('Player', (Vector3 pos, Vector3 size, String name,
        Map<String, dynamic> props) {
      final String assetPath = props['model_path'].toString();
      return Player(
        position: pos,
        size: size,
        modelPath: assetPath,
        name: name ?? 'Unknown',
      );
    });

    //
    final String tmxContent = await Flame.assets.readFile(levelPath);
    final XmlDocument xmlDoc = XmlDocument.parse(
        tmxContent); //fails since the asset file is somehow not published to github, it cant find the file
    _levelData = await TiledLevel.loadXML(
        xmlDoc, filename: 'tiles/3D_prototype.tmx',
        fileReader: (String path) async => await Flame.assets.readFile(path));
    loadAmbientLighting("assets/3D/default_env_ibl.ktx");
    setSkybox("assets/3D/default_env_skybox.ktx");

    await _trySpawnTest();
    //get Camera
    _gameCamera = GameCamera(await thermion!.getActiveCamera());
    add(_gameCamera!);
    //_gameCamera?.setFollowEntity(player);
    //add(Player(size: Vector3.all(1)));

    super.onLoad();
  }

  @override
  void onMount() {
    conversationManager = ConversationManager(game: this);
    overlays.toggle('touchControls');
    super.onMount();
  }


//todo implement more here, at the moment only placeholder
  @override
  void update(double dt) {
    super.update(dt);
    if (_3DGameViewer == null) return;

    //Joystick Y (Up/Down) to 3D Y (Up/Down)
    //Joystick X (Left/Right) to 3D X (Left/Right)

    if (currentJoystickMoveX == 0 && currentJoystickMoveY == 0) return;

    const moveSpeed = 5.0; // Meters per second


   /*
    //1 Update our local position state
    .x += currentJoystickMoveX * moveSpeed * dt;
    helmetPosition.y += -currentJoystickMoveY * moveSpeed * dt; // -Y is usually down in 2D, check directions

    // 2create empty matrix
    final matrix = Matrix4.identity();
    //3set position
    matrix.setTranslation(PixelAdventure3D.currentInstance.);
        .setTransform(entityID, matrix);
    //low-level FilamentApp is necessary because TViewer is only viewer
    final int entityID = (helmetAsset as dynamic).entity;
    FilamentApp.instance?*/

    //todo 5 Thermion, later in bridge class

    // Example: Rotate the camera every frame if the viewer is ready
    // if (_thermionViewer != null) {
    //    // game logic here
    // }
  }

  double currentJoystickMoveX = 0;
  double currentJoystickMoveY = 0;

  void onJoystickMove(StickDragDetails details) {
    currentJoystickMoveX = details.x;
    currentJoystickMoveY = details.y;
  }

  @override
  Map<String, Widget Function(BuildContext, BaseGame)>? buildOverlayMap() =>
      {
        'TextOverlay': (BuildContext context, BaseGame game) =>
            TextOverlay(
              game: game,
              onTextOverlayDone: () {
                game.overlays.remove("TextOverlay");
              },
            ),
        'DialogueScreen': (BuildContext context, BaseGame game) =>
            DialogueScreen(
              game: game,
              //when Dialogue is finishes screen is removed form map
              onDialogueFinished: () {
                game.overlays.remove('DialogueScreen');
              },
              yarnFilePath:
              'assets/yarn/test.yarn', //todo connect to state management and trigger method, make more customizable not static as atm
            ),
        'touchControls': (BuildContext context, BaseGame game) =>
            TouchControls(
              onJoystickMove: (game as PixelAdventure3D).onJoystickMove,
            )
      };


  @override
  KeyEventResult onKeyEvent(KeyEvent event,
      Set<LogicalKeyboardKey> keysPressed) {

    if (keysPressed.contains(LogicalKeyboardKey.f3)) { //toggle debug mode

    }

    // Debug test for SpeechBubble
    if (keysPressed.contains(LogicalKeyboardKey.keyB)) {
      // A method to toggle the speech bubble
      conversationManager.startConversation(
          'assets/yarn/speechbubble_test.yarn');
    }

    //overlay debug
    if (keysPressed.contains(LogicalKeyboardKey.keyO)) {
      final registeredOverlays = overlays.registeredOverlays;
      print('--- Overlay Status ---');
      if (registeredOverlays.isEmpty) {
        print('Registered (static) Overlays: None');
      } else {
        print('Registered (static) Overlays: $registeredOverlays');
      }

      // 2. Get the keys of all currently active (visible) overlays.
      // This includes static overlays that are "on" and any dynamic
      // overlays added with addEntry().
      final activeOverlays = overlays.activeOverlays;
      if (activeOverlays.isEmpty) {
        print('Active (visible) Overlays: None');
      } else {
        print('Active (visible) Overlays: $activeOverlays');
      }
      print('----------------------');
    }

    // Debug test for Dialogue
    if (keysPressed.contains(LogicalKeyboardKey.keyQ)) {
      // A method to toggle the speech bubble
      overlays.add('DialogueScreen');
    }
    return super.onKeyEvent(event, keysPressed);
  }


  @override
  DialogueCharacter? findCharacterByName(String name) {
    final DialogueCharacter? dCharacter = dCharacterMap[name];
    return dCharacter;
  }

  Future<void> _trySpawnTest() async {
    final loader = LevelLoader(levelData: _levelData!, viewer: _3DGameViewer!);
    await loader.spawnTiles();
    await loader.spawnObjects();
  }

  Future<void> setSkybox(String skyboxPath) async {
    await thermion!.loadSkybox(skyboxPath);
  }

  Future<void> loadAmbientLighting(String iblPath,
      [double intensity = 30000]) async {
    assert(thermion != null, "thermion isn't initialized yet!");
    await thermion?.loadIbl(iblPath, intensity: intensity);
    print("loaded lighting");
  }

  void registerEntity(int id, Entity entity) {
    entityMap[id] = entity;
    if (entity.name != null) {
      dCharacterMap[entity.name!] = entity as DialogueCharacter;
      print(dCharacterMap.keys);
    }
  }

  @override
  void onRemove() {
    entityMap.clear();
    super.onRemove();
  }

  Entity? getEntityById(int id) => entityMap[id];

}

ThermionViewer? get thermion => PixelAdventure3D._3DGameViewer;