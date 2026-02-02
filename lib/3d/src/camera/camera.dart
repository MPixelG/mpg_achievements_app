import 'dart:async';
import 'package:flame/components.dart' hide Matrix4, Vector3, Matrix3;
import 'package:flutter/cupertino.dart';
import 'package:mpg_achievements_app/3d/src/camera/movement_modes/base_camera_mode.dart';
import 'package:mpg_achievements_app/3d/src/game.dart';
import 'package:thermion_flutter/thermion_flutter.dart';
import '../components/position_component_3d.dart';

class GameCamera<FollowMode extends CameraFollowMode> extends Component with HasGameReference<PixelAdventure3D>{
  Camera thermionCamera;
  Matrix4 modelMatrix;



  CameraFollowable? target;
  CameraRotationAxisMode rotationAxisMode;

  FollowMode? followMode;

  GameCamera(this.thermionCamera, {Matrix4? modelMatrix})
      : modelMatrix = modelMatrix ?? Matrix4.identity(),
        rotationAxisMode = const CameraRotationAxisMode();




  @override
  Future<void> update(double dt) async {
    if (target == null || followMode == null) return super.update(dt);

    followMode!.step(dt);
    updateMatrix();

    final currentPos = modelMatrix.getTranslation();

    final currentViewMatrix = Matrix4.copy(modelMatrix)..invert();
    //get camera position change updates to flutter widgets
    game.getCameraTransformNotifier().updateFromCamera(newPos: currentPos, newViewMatrix: currentViewMatrix);
    return super.update(dt);
  }

  void setFollowMode(FollowMode mode){
    followMode = mode;
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
        bool preserveZRotation = true,
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

mixin CameraFollowable on ReadOnlyPosition3DProvider, ReadOnlyRotation3DProvider {}