import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vector_math/vector_math_64.dart';
import 'package:flutter/material.dart';

final cameraTransformProvider = ChangeNotifierProvider<CameraTransformNotifier>((ref) => CameraTransformNotifier());

typedef CameraNotifierAccessor = CameraTransformNotifier Function();

class CameraTransformNotifier extends ChangeNotifier {
  //track position and rotation
  final Vector3 _position = Vector3.zero();
  final Matrix4 _viewMatrix = Matrix4.identity();
  //there to check if there has been change
  late int _changeCount = 0;
  int get changeCount => _changeCount;
  Vector3 get position => _position;
  bool hasChanged = false;

  void updateFromCamera({
    required Vector3 newPos,
    required Matrix4 newViewMatrix,
  }) {
    final bool shifted = position.distanceToSquared(newPos) > 0.0001;

    // we check if Matrix changes significantly
    // check all 16 values of the matrix and compare -> better way?
    final bool rotated = !_matrixEquals(_viewMatrix, newViewMatrix);

    if (shifted || rotated) {
      _position.setFrom(newPos);
      _viewMatrix.setFrom(newViewMatrix);
      _changeCount++;
      print("Camercc:$_changeCount");
      //no collision bewtween UI rebuild and Notifier update
      Future.microtask(() {
        notifyListeners();
      });
     }
  }

  // compare matrix
  bool _matrixEquals(Matrix4 a, Matrix4 b) {
    final storageA = a.storage;
    final storageB = b.storage;
    for (int i = 0; i < 16; i++) {
      if ((storageA[i] - storageB[i]).abs() > 0.0001) return false;
    }
    return true;
  }
}
