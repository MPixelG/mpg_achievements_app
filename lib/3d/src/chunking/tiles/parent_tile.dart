import 'package:thermion_flutter/thermion_flutter.dart';

class ParentTile {
  final ThermionAsset _asset;
  ParentTile(this._asset);
  
  Future<ThermionAsset> provideTileAsset() => _asset.createInstance();
}