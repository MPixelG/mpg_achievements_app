import 'dart:async';
import 'dart:math' as math;

import 'package:flame/components.dart' hide Matrix4, Vector3;
import 'package:thermion_flutter/thermion_flutter.dart';

import 'components/position_component_3d.dart';

class GameCamera extends Component {
  Camera thermionCamera;
  Matrix4 modelMatrix;
  ReadOnlyPosition3DProvider? positionProvider;
  double cameraDistance = 5.0;
  double cameraHeight = 2.0;
  double lookAtHeight = 1.5;

  double positionLerpSpeed = 5.0;
  double rotationLerpSpeed = 8.0;
  double minMovementThreshold = 0.05;

  Vector3 currentPosition;
  Vector3 currentLookAt;
  Vector3 targetCameraPosition;
  Vector3 targetLookAtPosition;

  Vector3? lastTargetPosition;
  Vector3? smoothedTargetDirection;

  GameCamera(this.thermionCamera, {Matrix4? modelMatrix})
      : modelMatrix = modelMatrix ?? Matrix4.identity(),
        currentPosition = Vector3(0, 2, 5),
        currentLookAt = Vector3(0, 1.5, 0),
        targetCameraPosition = Vector3(0, 2, 5),
        targetLookAtPosition = Vector3(0, 1.5, 0);

  @override
  Future<void> update(double dt) async {
    if (positionProvider == null) return super.update(dt);

    final Vector3 targetEntityPosition = positionProvider!.position;

    Vector3? movementDirection;
    if (lastTargetPosition != null) {
      movementDirection = targetEntityPosition - lastTargetPosition!;

      if (movementDirection.length < minMovementThreshold) {
        movementDirection = null;
      }
    }

    Vector3 cameraDirection;
    if (movementDirection != null && movementDirection.length > 0) {
      final Vector3 newDirection = movementDirection.clone()..normalize();

      if (smoothedTargetDirection != null) {
        smoothedTargetDirection = _slerpVectors(
          smoothedTargetDirection!,
          newDirection,
          dt * rotationLerpSpeed,
        );
      } else {
        smoothedTargetDirection = newDirection;
      }

      cameraDirection = smoothedTargetDirection!;
    } else if (smoothedTargetDirection != null) {
      cameraDirection = smoothedTargetDirection!;
    } else {
      cameraDirection = Vector3(0, 0, -1);
    }

    targetLookAtPosition = targetEntityPosition + Vector3(0, lookAtHeight, 0);
    targetCameraPosition = targetEntityPosition -
        (cameraDirection * cameraDistance) +
        Vector3(0, cameraHeight, 0);

    currentLookAt = _lerpVector3(
      currentLookAt,
      targetLookAtPosition,
      dt * positionLerpSpeed,
    );

    currentPosition = _lerpVector3(
      currentPosition,
      targetCameraPosition,
      dt * positionLerpSpeed,
    );

    lookAt(currentPosition, currentLookAt);

    if (matrixUpdated) {
      thermionCamera.setTransform(modelMatrix);
      matrixUpdated = false;
    }

    lastTargetPosition = targetEntityPosition.clone();
    return super.update(dt);
  }

  Vector3 _lerpVector3(Vector3 start, Vector3 end, double t) {
    t = t.clamp(0.0, 1.0);
    return start + (end - start) * t;
  }

  Vector3 _slerpVectors(Vector3 start, Vector3 end, double t) {
    t = t.clamp(0.0, 1.0);

    final double dot = start.dot(end).clamp(-1.0, 1.0);
    final double theta = math.acos(dot) * t;

    if (theta.abs() < 0.001) {
      return _lerpVector3(start, end, t);
    }

    final Vector3 relative = (end - start * dot)..normalize();
    return (start * math.cos(theta)) + (relative * math.sin(theta));
  }

  void setFollowEntity([ReadOnlyPosition3DProvider? provider]) {
    positionProvider = provider;
    if (provider != null) {
      lastTargetPosition = null;
      smoothedTargetDirection = null;
    }
  }

  void setCameraSettings({
    double? distance,
    double? height,
    double? lookAtHeight,
    double? positionSmoothing,
    double? rotationSmoothing,
  }) {
    if (distance != null) cameraDistance = distance;
    if (height != null) cameraHeight = height;
    if (lookAtHeight != null) this.lookAtHeight = lookAtHeight;
    if (positionSmoothing != null) positionLerpSpeed = positionSmoothing;
    if (rotationSmoothing != null) rotationLerpSpeed = rotationSmoothing;
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