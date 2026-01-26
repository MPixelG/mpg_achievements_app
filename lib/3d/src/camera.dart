import 'dart:async';

import 'package:flame/components.dart' hide Matrix4, Vector3;
import 'package:flutter/cupertino.dart';
import 'package:mpg_achievements_app/core/math/lerping.dart';
import 'package:thermion_flutter/thermion_flutter.dart';

import 'components/position_component_3d.dart';

class GameCamera extends Component {
  Camera thermionCamera;
  Matrix4 modelMatrix;
  
  CameraFollowable? target;
  
  
  CameraRotationAxisMode rotationAxisMode;

  Vector3? initialCameraPosition;
  Vector3? initialRotation;
  
  Vector3? targetCameraPosition;
  Vector3? targetRotation;
  
  double initialGivenMoveTime = 0;
  double initialGivenRotationTime = 0;
  
  double moveTimeLeft = 0;
  double rotationTimeLeft = 0;
  
  AnimationStyle? _style;
  
  GameCamera(this.thermionCamera, {Matrix4? modelMatrix})
      : modelMatrix = modelMatrix ?? Matrix4.identity(),
        targetCameraPosition = Vector3(0, 2, 5),
        targetRotation = Vector3(0, 1.5, 0),
        rotationAxisMode = const CameraRotationAxisMode();
  
  
  void moveTo(Vector3 givenPosition, {
    AnimationStyle? style,
    double time = 1,
  }) {
    initialCameraPosition = position;
    targetCameraPosition = givenPosition.clone();
    initialGivenMoveTime = time;
    moveTimeLeft = initialGivenMoveTime;
    _style = style ?? _style ?? const AnimationStyle(curve: Curves.easeIn);
  }

  void moveStep(double dt){
    if(moveTimeLeft <= 0){
      moveTimeLeft = 0;
      if(targetCameraPosition != null) setPosition(targetCameraPosition!);
      return;
    }
    moveTimeLeft -= dt;
    
    if(initialCameraPosition == null || targetCameraPosition == null) return;
    
    final double progress = 1 - (moveTimeLeft / initialGivenMoveTime).clamp(0, 1);
    final double lerpedProgress = _style!.curve!.transform(progress);
    
    final Vector3 lerpedVector = lerp(initialCameraPosition!, targetCameraPosition!, lerpedProgress);
    
    setPosition(lerpedVector);
  }

  void rotationStep(double dt){
    if(rotationTimeLeft <= 0){
      rotationTimeLeft = 0;
      if(targetRotation != null) {
        setRotation(
          x: rotationAxisMode.x ? targetRotation!.x : null,
          y: rotationAxisMode.y ? targetRotation!.y : null,
          z: rotationAxisMode.z ? targetRotation!.z : null,
        );
      }
      return;
    }
    
    

    rotationTimeLeft -= dt;
  }
  
  

  @override
  Future<void> update(double dt) async {
    if (target == null) return super.update(dt);
    moveStep(dt);
    rotationStep(dt);
    
    if(target != null && (targetCameraPosition == null || targetCameraPosition!.distanceTo(target!.position) > .1)){
      moveTo(target!.position);
    }
    
    updateMatrix();
    return super.update(dt);
  }
  
  void updateMatrix(){
    if (matrixUpdated) {
      thermionCamera.setTransform(modelMatrix);
      matrixUpdated = false;
    }
  }

  void setFollowEntity([CameraFollowable? provider]) {
    target = provider;
  }

  void setRotation({double? x, double? y, double? z}) {
    final Matrix4 rotationMatrix = Matrix4.identity();

    if (y != null) {
      rotationMatrix.multiply(Matrix4.rotationY(y));
    }
    if (x != null) {
      rotationMatrix.multiply(Matrix4.rotationX(x));
    }
    if (z != null) {
      rotationMatrix.multiply(Matrix4.rotationZ(z));
    }

    modelMatrix.setRotation(rotationMatrix.getRotation());
    onMatrixUpdate();
  }
  
  void rotateZ(double val) {
    modelMatrix.rotateZ(val);
    onMatrixUpdate();
  }

  void setPosition(Vector3 position) {
    modelMatrix.setTranslation(position);
    onMatrixUpdate();
  }
  
  Vector3 get position => modelMatrix.getTranslation();

  bool matrixUpdated = false;
  void onMatrixUpdate() {
    matrixUpdated = true;
  }

  void lookAt(
      Vector3 position,
      Vector3 target, {
        Vector3? up,
        double? distance,
      }) {
    up ??= Vector3(0, 1, 0);

    final Vector3 forward = (position - target)..normalize();
    final Vector3 right = up.cross(forward)..normalize();
    final Vector3 realUp = forward.cross(right);

    if (distance != null) {
      final Vector3 dir = (position - target)..normalize();
      position = target + dir * distance;
    }

    final Matrix4 m = Matrix4.identity();

    m.setEntry(0, 0, right.x);
    m.setEntry(1, 0, right.y);
    m.setEntry(2, 0, right.z);

    m.setEntry(0, 1, realUp.x);
    m.setEntry(1, 1, realUp.y);
    m.setEntry(2, 1, realUp.z);

    m.setEntry(0, 2, forward.x);
    m.setEntry(1, 2, forward.y);
    m.setEntry(2, 2, forward.z);

    m.setTranslation(position);

    modelMatrix = m;

    onMatrixUpdate();
  }
}

@immutable
class CameraRotationAxisMode {
  final bool x;
  final bool y;
  final bool z;
  const CameraRotationAxisMode({this.x = false, this.y = false, this.z = true});
}

mixin CameraFollowable on ReadOnlyPosition3DProvider, ReadOnlyRotation3DProvider{}