import 'dart:async';

import 'package:mpg_achievements_app/3d/src/components/position_component_3d.dart';
import 'package:thermion_flutter/thermion_flutter.dart';

import '../game.dart';

mixin ThermionAssetContainer on PositionComponent3d {
  late ThermionAsset _asset;
  int? get entityId => asset.entity;
  String get modelPath;
  
  @override
  FutureOr<void> onLoad() async{
    asset = await (await thermion?.loadGltf(modelPath, keepData: true))!.createInstance();
    print("asset entity id: ${asset.entity}");
    thermion?.addToScene(asset);
    return super.onLoad();
  }


  ThermionAsset get asset => _asset;

  set asset(ThermionAsset newAsset) {
    //? maybe we need to remove and re-add it to the scene if we change it
    //thermion?.removeFromScene(asset!); 
    _asset = newAsset;
    //thermion?.addToScene(newAsset);
  }
}  