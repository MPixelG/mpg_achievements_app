import 'dart:async';
import 'dart:math';
import 'package:flame/components.dart' show KeyboardHandler;
import 'package:flutter/services.dart';
import 'package:mpg_achievements_app/3d/src/chunking/chunk.dart';
import 'package:mpg_achievements_app/3d/src/components/animated_game_character.dart';
import 'package:mpg_achievements_app/3d/src/state_management/models/entity/player_data.dart';
import 'package:mpg_achievements_app/core/controllers/character_controller.dart';
import 'package:mpg_achievements_app/core/controllers/control_action_bundle.dart';
import 'package:mpg_achievements_app/core/controllers/keyboard_character_controller.dart';
import 'package:mpg_achievements_app/isometric/src/core/math/iso_anchor.dart';
import 'package:mpg_achievements_app/util/utils.dart';
import 'package:vector_math/vector_math_64.dart';

class Player extends AnimatedGameCharacter<PlayerData> with KeyboardHandler {
  late KeyboardCharacterController<Player> controller;
  final Vector3 moveInput = Vector3.zero();

  bool controllable;
  Player({
    super.children,
    super.priority,
    super.key,
    super.position,
    required super.size,
    super.anchor,
    super.modelPath = "assets/3D/character/character_animated_v1.glb",
    super.name,
    this.controllable = true,
  });

  @override
  PlayerData initState() => PlayerData();

  //update is called in the superclass entity first which then calls the tickClient method in the player, the player updates it's postition
  //then the entity class calls it's own tickClient()-method which updates the position of the player
  @override
  void tickClient(double dt) {
    game.getTransformNotifier(entityId).updateTransform(positionOfAnchor(Anchor3D.topLeftLeft), newRotZ: rotationZ);

    if(abs(moveInput.z) > 0.2 * dt){
      playAnimation("walking", loop: true, speed: moveInput.z.isNegative ? 10 : 1);
    } else if(moveInput.x > 0.2) {
      playAnimation("turnLeft", playAmount: 0.8);
    }else if(moveInput.x < -0.2) {
      playAnimation("turnRight", playAmount: 0.8);
    } else {
      playAnimation("idle", loop: true);
      //stopAnimation("walking");
    }


    applyCameraRelativeMovement(dt);
    //updateDirection();






    //rotationZ = atan2(vz, vx) + pi / 2; // oder -pi/2
    super.tickClient(dt);
  }

  Vector3? lastPosition;
  void updateDirection(){
    final velocity = position - (lastPosition ?? position);

    if (velocity.length2 > 0.0001) {

      final dx = velocity.x;
      final dz = velocity.z;

      final targetYaw = atan2(dx, dz);
      final diff = (targetYaw - rotationZ + pi) % (2 * pi) - pi;

      rotationZ += diff * 0.1;
    }

    lastPosition = position.clone();
  }
  
  @override
  FutureOr<void> onLoad() async {
    await super.onLoad();

    if(controllable) {
      controller = KeyboardCharacterController<Player>(buildControlBundle());
      add(controller);
    }
    
    Chunk.onLoad();
    
    
    print("animations: ${await getAnimationNames()}");
    return;
  }
  
  static const movementSpeed = 0.01;
  ControlActionBundle<Player> buildControlBundle() =>
      ControlActionBundle<Player>({
        ControlAction(
          "moveForward",
          key: LogicalKeyboardKey.keyW,
          run: (p) => p.moveInput.z += 1,
        ),
        ControlAction(
          "moveBackward",
          key: LogicalKeyboardKey.keyS,
          run: (p) => p.moveInput.z -= 1,
        ),
        ControlAction(
          "moveLeft",
          key: LogicalKeyboardKey.keyA,
          run: (p) => p.moveInput.x += 1,
        ),
        ControlAction(
          "moveRight",
          key: LogicalKeyboardKey.keyD,
          run: (p) => p.moveInput.x -= 1,
        ),
        ControlAction(
          "jump",
          key: LogicalKeyboardKey.space,
          run: (p) => p.velocity.y = 1,
        ),
      });

  static const double cameraMoveSpeed = 0.03;
  void applyCameraRelativeMovement(double dt) {
    if (moveInput.length2 == 0) return;

    moveInput.normalize();

    rotationZ += moveInput.x * cameraMoveSpeed;

    velocity.x +=
        (-moveInput.z * sin(-rotationZ)) *
            movementSpeed;

    velocity.z +=
        (moveInput.z * cos(-rotationZ)) *
            movementSpeed;
    
    //moveInput.scale(pow(1.1, dt).toDouble()); // epilepsy warning
    moveInput.setZero();
  }

  double getYawFromRotation(Matrix3 r) {
    final forwardX = -r.entry(2, 0);
    final forwardZ = -r.entry(2, 2);

    return atan2(forwardX, forwardZ);
  }




  void addCameraRelativeVelocity(
      Vector3 localDir,
      double speed,
      double cameraYaw,
      ) {
    if (localDir.length2 == 0) return;

    localDir.normalize();

    final sinYaw = sin(cameraYaw);
    final cosYaw = cos(cameraYaw);

    velocity.x += (localDir.x * cosYaw - localDir.z * sinYaw) * speed;
    velocity.z += (localDir.x * sinYaw + localDir.z * cosYaw) * speed;
  }
  
  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    if(event is! KeyDownEvent) return super.onKeyEvent(event, keysPressed);
    return super.onKeyEvent(event, keysPressed);
  }
}