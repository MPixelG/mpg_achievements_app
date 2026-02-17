import 'dart:async';

import 'package:mpg_achievements_app/3d/src/components/game_character.dart';
import 'package:mpg_achievements_app/3d/src/components/player.dart';
import 'package:mpg_achievements_app/3d/src/components/position_component_3d.dart';
import 'package:mpg_achievements_app/core/physics/hitbox3d/shapes/rectangle_hitbox3d.dart';
import 'package:thermion_flutter/thermion_flutter.dart';

import '../game.dart';

mixin ThermionAssetContainer on PositionComponent3d {
  late ThermionAsset _asset;
  int? get entityId => asset.entity;
  String get modelPath;
  //auto adjust to model size -> yesorno
  bool get autoResizeToModel => true;
  double get modelScale => 0.01;
  bool get useFixedGameplaySize => false; //todo define sizes for specific objects respectively approach

  @override
  FutureOr<void> onLoad() async {
    final sourceAsset = (await thermion?.loadGltf(
      modelPath,
      keepData: true,
    ));
    _asset = await sourceAsset!.createInstance();
    print("asset entity id: ${_asset.entity}");
    thermion?.addToScene(_asset);

    if (modelScale != 1.0) {
      // Skalierung auf das Entity anwenden (x, y, z)
      await FilamentApp.instance!.setTransform(
        _asset.entity,
        Matrix4.diagonal3Values(modelScale, modelScale, modelScale),
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
    final aabb = await _asset.getBoundingBox();
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

  ThermionAsset get asset => _asset;

  set asset(ThermionAsset newAsset) {
    //? maybe we need to remove and re-add it to the scene if we change it
    //thermion?.removeFromScene(asset!);
    _asset = newAsset;
    //thermion?.addToScene(newAsset);
  }

  @override
  void onRemove() {
    // clean up
    thermion?.removeFromScene(_asset);
    thermion?.destroyAsset(_asset);
    super.onRemove();
  }
}
