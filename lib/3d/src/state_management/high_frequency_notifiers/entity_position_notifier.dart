import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vector_math/vector_math_64.dart';


// <return type, Entity id> -> we use the entityID for refering to an object
final entityTransformProvider = ChangeNotifierProvider.family<EntityTransformNotifier, int?>((ref, id) => EntityTransformNotifier());

//helper function for accessingf only one entity
typedef TransformNotifierAccessor = EntityTransformNotifier Function(int? entityId);


// Logic class
class EntityTransformNotifier extends ChangeNotifier {
  //track position and rotation
  final Vector3 position = Vector3.zero();
  //there to check if there has been change
  late int changeCount = 0;
  double rotationZ = 0;


  void updateTransform(Vector3 newPos, {double? newRotZ}) {
    bool hasChanged = false;
    // position check if there is a new postion, then update
    if (position.distanceToSquared(newPos) > 0.001) {
      position.setFrom(newPos);
      hasChanged = true;
      }

    // rotation check ca. größer 0,5°
    if (newRotZ != null && (rotationZ - newRotZ).abs() > 0.01) {
      rotationZ = newRotZ;
      hasChanged = true;
      }

    //if changes happened notify the listeners
    if (hasChanged) {
      changeCount++;
      Future.microtask(() {
        notifyListeners();
      });
                      }
  }
}

