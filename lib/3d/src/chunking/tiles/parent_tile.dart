import 'package:thermion_flutter/thermion_flutter.dart';

class ParentTile {
  ThermionAsset asset;
  ParentTile(this.asset);
  
  Future<ThermionAsset> provideTile() => asset.createInstance();
}