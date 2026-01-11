import 'dart:math';

import 'package:flame/components.dart' hide Matrix4, Vector3;
import 'package:thermion_flutter/thermion_flutter.dart';

class GameCamera extends Component{
  Camera thermionCamera;
  Matrix4 modelMatrix;


  GameCamera(this.thermionCamera, {Matrix4? modelMatrix}) : modelMatrix = modelMatrix ?? Matrix4.identity();
  double time = 0;
  
  @override
  Future<void> update(double dt) async {
    time += dt;

    final Vector3 newPos = Vector3(sin(time) * 10, 20, cos(time) * 10);
    setPosition(newPos);
    final Vector3 target = Vector3(0, 0, 0);
    lookAt(newPos, target, distance: sin(time)*20 + 30);

    if(matrixUpdated){
      thermionCamera.setTransform(modelMatrix);
      matrixUpdated = false;
    }
    
    return super.update(dt);
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
  
  bool matrixUpdated = false;
  void onMatrixUpdate(){
    matrixUpdated = true;
  }

  
  void lookAt(Vector3 position, Vector3 target, {Vector3? up, double? distance}) {
    up ??= Vector3(0, 1, 0);

    final Vector3 forward = (position - target)..normalize();
    final Vector3 right = up.cross(forward)..normalize();
    final Vector3 realUp = forward.cross(right);

    if (distance != null) {
      // Richtung vom Ziel zur gewünschten Position
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