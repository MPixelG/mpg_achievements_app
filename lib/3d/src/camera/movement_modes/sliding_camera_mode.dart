import 'package:flutter/animation.dart';
import 'package:mpg_achievements_app/3d/src/camera/movement_modes/base_camera_mode.dart';
import 'package:mpg_achievements_app/core/math/lerping.dart';
import 'package:vector_math/vector_math_64.dart';

class SlidingCameraMode extends CameraFollowMode {
  AnimationStyle? _style;
  
  Vector3? initialCameraPosition;
  Vector3? initialRotation;

  Vector3? targetCameraPosition;
  Vector3? targetRotation;

  double initialGivenMoveTime = 0;
  double initialGivenRotationTime = 0;

  double moveTimeLeft = 0;
  double rotationTimeLeft = 0;  
  
  SlidingCameraMode(super.camera);
  
  @override
  void moveTo(Vector3 givenPosition, double time, {AnimationStyle? style}) {
    initialCameraPosition = position;
    targetCameraPosition = givenPosition.clone();
    initialGivenMoveTime = time;
    moveTimeLeft = initialGivenMoveTime;
    _style = style ?? _style ?? const AnimationStyle(curve: Curves.easeIn);
  }

  @override
  void rotateTo(Vector3 givenRotation, double time, {AnimationStyle? style}) {
    //todo
  }

  @override
  void step(double dt) {
    moveStep(dt);
    rotationStep(dt);
    if(target != null && (targetCameraPosition == null || targetCameraPosition!.distanceTo(target!.position) > .1)){
      moveTo(target!.position, 1);
    }
  }
  
  void moveStep(double dt){
    if(moveTimeLeft <= 0){
      moveTimeLeft = 0;
      if(targetCameraPosition != null) camera.setPosition(targetCameraPosition!);
      return;
    }
    moveTimeLeft -= dt;

    if(initialCameraPosition == null || targetCameraPosition == null) return;

    final double progress = 1 - (moveTimeLeft / initialGivenMoveTime).clamp(0, 1);
    final double lerpedProgress = _style!.curve!.transform(progress);

    final Vector3 lerpedVector = lerp(initialCameraPosition!, targetCameraPosition!, lerpedProgress);

    camera.setPosition(lerpedVector);
  }

  void rotationStep(double dt){
    if(rotationTimeLeft <= 0){
      rotationTimeLeft = 0;
      if(targetRotation != null) {
        camera.setRotation(
          x: camera.rotationAxisMode.x ? targetRotation!.x : null,
          y: camera.rotationAxisMode.y ? targetRotation!.y : null,
          z: camera.rotationAxisMode.z ? targetRotation!.z : null,
        );
      }
      return;
    }



    rotationTimeLeft -= dt;
  }
  
  
}