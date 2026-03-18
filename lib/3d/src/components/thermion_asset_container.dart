import 'dart:async';
import 'package:mpg_achievements_app/3d/src/components/position_component_3d.dart';
import 'package:mpg_achievements_app/core/physics/hitbox3d/shapes/rectangle_hitbox3d.dart';
import 'package:thermion_flutter/thermion_flutter.dart';

import '../game.dart';

mixin ThermionAssetContainer on PositionComponent3d {
  ThermionAsset? _asset;
  int? get entityId => asset.entity;
  String get modelPath;
  //auto adjust to model size -> yesorno
  bool get autoResizeToModel => true;
  double get modelScale => 0.01;
  bool get useFixedGameplaySize => false; //todo define sizes for specific objects respectively approach

  @override
  FutureOr<void> onLoad() async {
    final sourceAsset = await thermion?.loadGltf(
      modelPath,
      keepData: true,
    );
    //todo in the future a manager could load assets from here withou loading it from disk every time for now I destroy the asset after instantiating itr

    final instance = await sourceAsset!.createInstance();
    _asset = instance;
    thermion?.addToScene(_asset!);

    print("asset entity id: ${_asset!.entity}");
    print("SOURCE entity: ${sourceAsset.entity}");
    print("INSTANCE entity: ${instance.entity}");
    print("Same entity? ${sourceAsset.entity == instance.entity}");

    if (modelScale != 1.0) {
      // Skalierung auf das Entity anwenden (x, y, z)
      await _asset!.setTransform(
        Matrix4.diagonal3Values(modelScale, modelScale, modelScale), entity: _asset!.entity
      );
    }
    //adjust component3D to model size
    if (autoResizeToModel) {
      await _updateComponentSizeFromAsset();
    }
    return super.onLoad();
  }

  Future<void> _updateComponentSizeFromAsset() async {
    //ask for aabb
    final aabb = await _asset!.getBoundingBox();
    //calculate size normally y is height, but model seems to treat z as up -> chekc Blender
    final rx = aabb.max.x - aabb.min.x;
    final ry = aabb.max.y - aabb.min.y;
    final rz = aabb.max.z - aabb.min.z;

    final width = rx * modelScale;
    final height = rz * modelScale;
    final depth = ry * modelScale;

    if (useFixedGameplaySize) {
      size.setValues(0.6, 1.8, 0.6);
      print(
        "Resized PositionComponent3D to Player(swapped Y/Z):'$modelPath' to: $width $height $depth",
      );

    } else {
      size.setValues(width, height, depth);
      print(
        "Resized PositionComponent3D(swapped Y/Z):'$modelPath' to: $width $height $depth",
      );
    }

    for (final child in children) {
      if (child is RectangleHitbox3D) {
        // If you implemented 'fillParent' in your Hitbox class:
        child.fillParent();
        print(child.size);

        print("Updated Hitbox size to match parent.");
        child.refreshDebugVisual();
      }
    }
  }

  ThermionAsset get asset => _asset!;

  set asset(ThermionAsset newAsset) {
    //? maybe we need to remove and re-add it to the scene if we change it
    //thermion?.removeFromScene(asset!);
    _asset = newAsset;
    //thermion?.addToScene(newAsset);
  }

  @override
  void onRemove() {
    // clean up
    thermion?.removeFromScene(_asset!);
    thermion?.destroyAsset(_asset!);
    super.onRemove();
  }
}
