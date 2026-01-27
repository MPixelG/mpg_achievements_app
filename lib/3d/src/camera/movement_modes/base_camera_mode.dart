

import 'package:mpg_achievements_app/3d/src/camera/camera.dart';
import 'package:vector_math/vector_math_64.dart';

abstract class CameraFollowMode {
  GameCamera camera;
  void step(double dt);
  CameraFollowMode(this.camera);

  Vector3 get position => camera.position;
  CameraFollowable? get target => camera.target;
  CameraRotationAxisMode get rotationAxisMode => camera.rotationAxisMode;
}