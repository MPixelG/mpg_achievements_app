import 'dart:async';
import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/extensions.dart' as fe;
import 'package:flame/flame.dart';
import 'package:flame/input.dart' hide Vector2, Vector3;
import 'package:flame/palette.dart';
import 'package:flutter/material.dart' hide AnimationStyle, Image;
import 'package:mpg_achievements_app/core/base_game.dart';
import 'package:mpg_achievements_app/core/dialogue_utils/conversation_management.dart';
import 'package:mpg_achievements_app/core/dialogue_utils/dialogue_character.dart';
import 'package:mpg_achievements_app/core/dialogue_utils/dialogue_containing_game.dart';
import 'package:mpg_achievements_app/core/dialogue_utils/dialogue_screen.dart';
import 'package:mpg_achievements_app/core/dialogue_utils/text_overlay.dart';
import 'package:mpg_achievements_app/core/music/music_manager.dart';
import 'package:thermion_flutter/thermion_flutter.dart' hide Vector2, Vector3;
import 'package:vector_math/vector_math_64.dart' as v64;
import 'package:xml/xml.dart';
import 'components/camera/advanced_camera.dart';
import 'core/iso_component.dart';
import 'core/level/game_world.dart';
import '../../3d/src/level/tiled_level.dart';
import 'core/physics/hitbox3d/has_collision_detection.dart';
import 'core/physics/hitbox3d/iso_collision_callbacks.dart';


//DragCallbacks are imported for touch controls
class PixelAdventure extends BaseGame
    with
        HasKeyboardHandlerComponents,
        DragCallbacks,
        HasCollisionDetection3D,
        ScrollDetector,
        IsoCollisionCallbacks,
        DialogueContainingGame {
  static PixelAdventure? _currentInstance;
  static ThermionViewer? _3DGameViewer;

  static PixelAdventure get currentInstance {
    _currentInstance ??= PixelAdventure();

    return _currentInstance!;
  }

  @override
  Color backgroundColor() => const Color(0x00000000);


  void setThermionViewer(ThermionViewer viewer) {
    _3DGameViewer = viewer;
  }

  //Game components
  final Map<String, IsoPositionComponent> npcs = {};
  late final ConversationManager conversationManager;
  late final AdvancedCamera cam;
  late final GameWorld gameWorld;
  late JoystickComponent joystick;
  late String currentLevel = "Level_9";
  final musicManager = MusicManager();
  //bools for game logic
  //needs to go into the overlay_controller later
  bool showDialogue = false;
  //storage for the 3D Object
  dynamic helmetAsset;
  v64.Vector3 helmetPosition = v64.Vector3(0.0, 0.0, -5.0);
  double rotationAngle = 0.0;



  //Future is a value that is returned even thought a value of the method is not computed immediately, but later
  //FutureOr works same here either returns a Future or <void>
  @override
  FutureOr<void> onLoad() async {

    //test
    //add overlays
   // overlays.add('TextOverlay');
   // overlays.add('DialogueScreen');
    //addJoystick();
    //musicManager.playRandomMusic();
    //musicManager.setVolume(0.4);
    //final String tmxContent = await Flame.assets.readFile(levelPath);
    //final XmlDocument xmlDoc = XmlDocument.parse(tmxContent); //fails since the asset file is somehow not published to github, it cant find the file
    //final FutureOr<TiledLevel> levelData = TiledLevel.loadXML(xmlDoc, filename: '3D_prototype.tmx', fileReader: (String path) async => await Flame.assets.readFile(levelPath));
    //print('Level');
    //print(levelData);
    //super.onLoad();
    /*Removed for testing 3dThermionViewer, potentially keep the part for later usage in a separate game??
    //all images for the game are loaded into cache when the game start -> could take long at a later stage, but here it is fine for moment being
    await images.loadAllImages();
    conversationManager = ConversationManager(game: this);
    //parse("tiles/$currentLevel.tmx");

    //world is loaded after initialising all images
    final Vector2 tileSize = await getTilesizeOfLevel(currentLevel);

    gameWorld = IsometricWorld(
      levelName: currentLevel,
      calculatedTileSize: tileSize.xxy,
    ); //on the horizontal axis, the tile is rectangular. on the side its half the size (z-axis)

    cam = AdvancedCamera(world: gameWorld);
    cam.viewfinder.anchor = Anchor.center;
    await addAll([cam, gameWorld]);



    await add(
      _FollowCameraComponent(),
    ); //helper class to follow the player after the world and player are loaded
    return super.onLoad();*/
  }


//todo implement more here, at the moment only placehoilder
  @override
  void update(double dt) {
    super.update(dt);
    if (_3DGameViewer == null || helmetAsset == null) return;

    //Joystick Y (Up/Down) to 3D Y (Up/Down)
    //Joystick X (Left/Right) to 3D X (Left/Right)
    if (!joystick.delta.isZero()) {
      const moveSpeed = 5.0; // Meters per second

      //1 Update our local position state
      helmetPosition.x += joystick.relativeDelta.x * moveSpeed * dt;
      helmetPosition.y += -joystick.relativeDelta.y * moveSpeed *
          dt; // -Y is usually down in 2D, check directions

      // 2create empty matrix
      final matrix = v64.Matrix4.identity();
      //3set position
      matrix.setTranslation(helmetPosition);

      // 4Apply Rotation only x rotation for testing
      rotationAngle += joystick.relativeDelta.x * 5.0 * dt;
      matrix.rotateY(rotationAngle);

      //low-level FilamentApp is necessary because TViewer is only viewer
      final int entityID = (helmetAsset as dynamic).entity;
      FilamentApp.instance?.setTransform(entityID, matrix);

      //todo 5 Thermion, later in bridge class

      // Example: Rotate the camera every frame if the viewer is ready
      // if (_thermionViewer != null) {
      //    // game logic here
      // }
    }
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
        size: fe.Vector2(40, 40),
        paint: BasicPalette.red.withAlpha(200).paint(),
      ),
      position: fe.Vector2(500, size.y - 380),
      onPressed: () {
        print('Button Pressed');
      },
    );

    add(joystick);
    add(buttonComponent);
  }

  double scrollFactor = 1.0;
  double zoomFactor = 1.0;
  @override
  void onScroll(PointerScrollInfo info) {
    scrollFactor += info.scrollDelta.global.y;
    zoomFactor = math.pow(0.9, scrollFactor / 30).toDouble();
  }

  @override
  bool showingDialogue = false;

  @override
  DialogueCharacter? findCharacterByName(String name) {
    npcs[name];
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
  };

  @override
  Future<v64.Vector3?> calculateBubblePosition(v64.Vector3? position) {
    // TODO: implement calculateBubblePosition
    throw UnimplementedError();
  }

  @override
  Future<v64.Vector3?> clampedBubblePosition(v64.Vector3? position) {
    // TODO: implement clampedBubblePosition
    throw UnimplementedError();
  }

}

fe.Vector3 get tilesize =>
    PixelAdventure.currentInstance.gameWorld.calculatedTileSize;

fe.Vector2 get screenSize =>
    PixelAdventure.currentInstance.cam.viewport.virtualSize;

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


ThermionViewer? get thermion => PixelAdventure._3DGameViewer;