import 'dart:async';

import 'package:flame/camera.dart';
import 'package:flame/events.dart' hide PointerMoveEvent;
import 'package:flame/flame.dart';
import 'package:flutter/material.dart' hide AnimationStyle, Image, KeyEvent;
import 'package:flutter/services.dart';
import 'package:flutter_joystick/flutter_joystick.dart';
import 'package:mpg_achievements_app/3d/src/camera/camera.dart';
import 'package:mpg_achievements_app/3d/src/camera/movement_modes/locked_follow_mode.dart';
import 'package:mpg_achievements_app/3d/src/components/npc.dart';
import 'package:mpg_achievements_app/3d/src/components/player.dart';
import 'package:mpg_achievements_app/3d/src/level/entity_factory.dart';
import 'package:mpg_achievements_app/3d/src/level/tiled_level_loader.dart';
import 'package:mpg_achievements_app/3d/src/state_management/high_frequency_notifiers/camera_position_provider.dart';
import 'package:mpg_achievements_app/3d/src/state_management/high_frequency_notifiers/entity_position_notifier.dart';
import 'package:mpg_achievements_app/3d/src/tools/editor/editor_overlay.dart';
import 'package:mpg_achievements_app/3d/src/tools/editor/widgets/menuBar/menu_action.dart';
import 'package:mpg_achievements_app/3d/src/tools/editor/widgets/menuBar/menu_action_registry.dart';
import 'package:mpg_achievements_app/3d/src/tools/editor/widgets/window_system/window_type_registry.dart';
import 'package:mpg_achievements_app/core/base_game.dart';
import 'package:mpg_achievements_app/core/dialogue_utils/conversation_management.dart';
import 'package:mpg_achievements_app/core/dialogue_utils/dialogue_character.dart';
import 'package:mpg_achievements_app/core/dialogue_utils/dialogue_containing_game.dart';
import 'package:mpg_achievements_app/core/dialogue_utils/dialogue_screen.dart';
import 'package:mpg_achievements_app/core/dialogue_utils/text_overlay.dart';
import 'package:mpg_achievements_app/core/touch_controls/touch_controls.dart';
import 'package:mpg_achievements_app/isometric/src/core/physics/hitbox3d/has_collision_detection.dart';
import 'package:mpg_achievements_app/util/utils.dart';
import 'package:thermion_flutter/thermion_flutter.dart' hide KeyEvent, Vector3;
import 'package:vector_math/vector_math_64.dart' hide Colors;
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

  late Player player;


  //Singleton
  static PixelAdventure3D? _currentInstance;
  static PixelAdventure3D get currentInstance => _currentInstance!;
  PixelAdventure3D({
    required this.getTransformNotifier, required this.getCameraTransformNotifier
    }) {
    //sigleton only set when game was initialised
    _currentInstance = this;
  }

  //Map for entities
  final Map<int, Entity> entityMap = {};
  final Map<String, DialogueCharacter> dCharacterMap = {};


  //reference to ThermionViewer
  static late ThermionViewer? _3DGameViewer;
  //reference to camera
  late GameCamera? camera3D;

  void setThermionViewer(ThermionViewer viewer) {
    _3DGameViewer = viewer;
  }

  //Managers and stuff for speechBubble
  late final ConversationManager conversationManager;
  final TransformNotifierAccessor getTransformNotifier;
  final CameraNotifierAccessor getCameraTransformNotifier;


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
    camera3D = GameCamera<LockedFollowMode>(await thermion!.getActiveCamera());
    camera3D!.setPosition(Vector3(0, 2, 0));
    add(camera3D!);

    final followMode = LockedFollowMode(camera3D!);
    camera3D!.setFollowMode(followMode);
    camera3D!.setFollowEntity(player);
    
    WindowTypeRegistry.register("test1", WindowTypeDefinition(id: "test1", title: "test 1 (green)", builder: () => Container(color: Colors.green)));
    WindowTypeRegistry.register("test2", WindowTypeDefinition(id: "test2", title: "test 2 (blue)", builder: () => Container(color: Colors.blue)));
    MenuActionRegistry.register(MenuAction(path: "file", displayName: "File", action: () {}));
    MenuActionRegistry.register(MenuAction(path: "file/save", displayName: "Save", action: () {}));
    MenuActionRegistry.register(MenuAction(path: "file/save_as", displayName: "Save As", action: () {}));
    MenuActionRegistry.register(MenuAction(path: "file/save_as/json", displayName: "JSON", action: () {}));
    MenuActionRegistry.register(MenuAction(path: "file/save_as/png", displayName: "PNG", action: () {}));
    MenuActionRegistry.register(MenuAction(path: "file/save_as/bf", displayName: "BF", action: () {}));
    MenuActionRegistry.register(MenuAction(path: "file/open", displayName: "Open", action: () {}));
    MenuActionRegistry.register(MenuAction(path: "view", displayName: "View", action: () {}));
    MenuActionRegistry.register(MenuAction(path: "view/fullscreen", displayName: "Fullscreen", action: () {}));

    super.onLoad();
  }

  @override
  void onMount() {
    conversationManager = ConversationManager(game: this);
    overlays.toggle('touchControls');
    super.onMount();
  }


  @override
  void update(double dt) {
    super.update(dt);
    if (_3DGameViewer == null) return;
    //Joystick Y (Up/Down) to 3D Y (Up/Down)
    //Joystick X (Left/Right) to 3D X (Left/Right)
    if (currentJoystickMoveX == 0 && currentJoystickMoveY == 0) return;
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
            ),
        'editor': (BuildContext context, BaseGame game) => const Editor3DOverlay(id: "main")
      };


  @override
  KeyEventResult onKeyEvent(KeyEvent event,
      Set<LogicalKeyboardKey> keysPressed) {

    if (keysPressed.contains(LogicalKeyboardKey.f3)) { //toggle debug mode
      overlays.toggle('editor');
      print("toggled editor visibility to ${overlays.isActive("editor")}");
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
  Future<Vector3?> calculateBubblePosition(Vector3? position) async {
    final size = Size(this.size.x, this.size.y);
   final Vector3? bubblePosition =  worldToScreen(worldPosition: position!, viewMatrix: await camera3D!.thermionCamera.getViewMatrix(), projectionMatrix:await camera3D!.thermionCamera.getProjectionMatrix(), screenSize: size);

  return bubblePosition;

  }

  @override
  Future<Vector3?> clampedBubblePosition(Vector3? position) async {
    final size = Size(this.size.x, this.size.y);
    final Vector3 arrowPosition =  getClampedScreenPos(worldPosition: position!, viewMatrix: await camera3D!.thermionCamera.getViewMatrix(), projectionMatrix: await camera3D!.thermionCamera.getProjectionMatrix(), screenSize: size);

    return arrowPosition;

  }

  @override
  void onRemove() {
    entityMap.clear();
    super.onRemove();
  }

  Entity? getEntityById(int id) => entityMap[id];

}

ThermionViewer? get thermion => PixelAdventure3D._3DGameViewer;