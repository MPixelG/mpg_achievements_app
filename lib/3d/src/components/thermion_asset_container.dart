import 'dart:async';

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


  @override
  FutureOr<void> onLoad() async{
    final asset = await (await thermion?.loadGltf(modelPath, keepData: true))!.createInstance();
    _asset = await asset.createInstance();
    print("asset entity id: ${_asset.entity}");
    thermion?.addToScene(_asset);

    if (modelScale != 1.0) {
      // Skalierung auf das Entity anwenden (x, y, z)
      await FilamentApp.instance!.setTransform(
          _asset.entity,
          Matrix4.diagonal3Values(modelScale, modelScale, modelScale)
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
    //calculate size
    final rwidth = aabb.max.x - aabb.min.x;
    final rheight = aabb.max.y - aabb.min.y;
    final rdepth = aabb.max.z - aabb.min.z;


    final width = rwidth * modelScale;
    final height = rheight * modelScale;
    final depth = rdepth * modelScale;

    size.setValues(width, height, depth);
    print("Resized PositionComponent3D:'$modelPath' to: $width $height $depth");

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
