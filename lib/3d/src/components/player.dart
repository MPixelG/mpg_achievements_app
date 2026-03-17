import 'dart:async';
import 'dart:math';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart' show KeyboardHandler;
import 'package:flutter/services.dart';
import 'package:mpg_achievements_app/3d/src/components/animated_game_character.dart';
import 'package:mpg_achievements_app/3d/src/components/position_component_3d.dart';
import 'package:mpg_achievements_app/3d/src/state_management/models/entity/player_data.dart';
import 'package:mpg_achievements_app/core/controllers/character_controller.dart';
import 'package:mpg_achievements_app/core/controllers/control_action_bundle.dart';
import 'package:mpg_achievements_app/core/controllers/keyboard_character_controller.dart';
import 'package:mpg_achievements_app/core/physics/hitbox3d/collision_callbacks3D.dart';
import 'package:mpg_achievements_app/isometric/src/core/math/iso_anchor.dart';
import 'package:mpg_achievements_app/util/utils.dart';
import 'package:vector_math/vector_math_64.dart';


enum _AnimState { idle, walking, turnLeft, turnRight }



class Player extends AnimatedGameCharacter<PlayerData> with KeyboardHandler, CollisionCallbacks3D {
  late KeyboardCharacterController<Player> controller;
  final Vector3 moveInput = Vector3.zero();

  @override
  bool get useFixedGameplaySize => true;

  bool controllable;

  Player({
    super.children,
    super.priority,
    super.key,
    super.position,
    required super.size,
    super.anchor,
    required super.modelPath,
    super.name,
    this.controllable = true,
  });

  @override
  PlayerData initState() => PlayerData();

  _AnimState? _currentAnimState;


  //update is called in the superclass entity first which then calls the tickClient method in the player, the player updates it's postition
  //then the entity class calls it's own tickClient()-method which updates the position of the player
  @override
  void tickClient(double dt) {
    game.getTransformNotifier(entityId).updateTransform(
        positionOfAnchor(Anchor3D.topCenter) + Vector3(0, size.y / 2, 0),
        newRotZ: rotationZ);

    //no playAnimatoin calls in tickMethod
    if (abs(moveInput.z) > 0.2 * dt) {
      _setAnimationState(_AnimState.walking);
    } else if (moveInput.x > 0.2) {
      _setAnimationState(_AnimState.turnLeft);
    } else if (moveInput.x < -0.2) {
      _setAnimationState(_AnimState.turnRight);
    } else {
      _setAnimationState(_AnimState.idle);
    }


    applyCameraRelativeMovement(dt);
    //updateDirection();


    //rotationZ = atan2(vz, vx) + pi / 2; // oder -pi/2
    super.tickClient(dt);
  }

  Vector3? lastPosition;

  void updateDirection() {
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

  void _setAnimationState(_AnimState state) {
    if (_currentAnimState == state) return;
    _currentAnimState = state;

    switch (state) {
      case _AnimState.walking:
        playAnimation("walking", loop: true, reverse: moveInput.z.isNegative);
      case _AnimState.turnLeft:
        playAnimation("turnLeft", playAmount: 0.8);
      case _AnimState.turnRight:
        playAnimation("turnRight", playAmount: 0.8);
      case _AnimState.idle:
        playAnimation("idle", loop: true);
    }
  }


  @override
  Future<void> onLoad() async {
    await super.onLoad();

    if (controllable) {
      controller = KeyboardCharacterController<Player>(buildControlBundle());
      add(controller);
    }
    hitbox.collisionType = CollisionType.active;

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


  @override
  void onCollisionStart(Set<Vector3> intersectionPoints, PositionComponent3d other) {
    super.onCollisionStart(intersectionPoints, other);

    print("BONK! Player hit: ${other.runtimeType}");

    // Simple test: Stop movement on impact
    // velocity.setZero();
  }

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
    if(event.logicalKey.keyLabel == "G") playAnimation("turn180");
    return super.onKeyEvent(event, keysPressed);
  }
}