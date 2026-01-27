import 'dart:math' as math;

import 'package:flutter/animation.dart';
import 'package:mpg_achievements_app/3d/src/camera/movement_modes/base_camera_mode.dart';
import 'package:vector_math/vector_math_64.dart';

class LockedFollowMode extends CameraFollowMode {
  Vector3 currentTargetedPos = Vector3.zero();
  double distance = 5;

  double yRotation = 0;
  double targetYRotation = 0;

  double xRotation = -0.3;
  double targetXRotation = -0.3;
  
  double currentRotationSpeedX = 0;
  double currentRotationSpeedY = 0;

  double height = 2.0;

  bool followTargetRotation = true;

  static const AnimationStyle _style = AnimationStyle(curve: Curves.ease);

  LockedFollowMode(super.camera);

  @override
  void step(double dt) {
    if (target == null) return;

    currentTargetedPos = target!.position;

    if (followTargetRotation && target != null) {
      targetXRotation = -target!.rotationZ - radians(90);
    }

    if ((targetYRotation - yRotation).abs() > 0.001) {
      double rotationDelta = targetYRotation - yRotation;

      if (rotationDelta > math.pi) {
        rotationDelta -= 2 * math.pi;
      } else if (rotationDelta < -math.pi) {
        rotationDelta += 2 * math.pi;
      }

      currentRotationSpeedY = (rotationDelta / 1.05) * dt;
      yRotation += currentRotationSpeedY;
    }

    if ((targetXRotation - xRotation).abs() > 0.001) {
      final double rotationDelta = targetXRotation - xRotation;

      currentRotationSpeedX = (rotationDelta * 1.5) * dt;
      xRotation += currentRotationSpeedX;
    }

    updateCameraPosition();
  }


  void updateCameraPosition() {
    if (target == null) return;

    final Vector3 targetPos = target!.position;
    final double horizontalDistance = distance * math.cos(xRotation);

    final double x = horizontalDistance * math.cos(yRotation);
    final double y = horizontalDistance * math.sin(yRotation) + height;
    final double z = distance * math.sin(xRotation);
 
    final Vector3 offset = Vector3(x, y, z);
    final Vector3 cameraPos = targetPos + offset;

    camera.lookAt(cameraPos, targetPos);
  }
}