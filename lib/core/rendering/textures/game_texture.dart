import 'dart:ui';

import 'package:flutter/cupertino.dart' show mustCallSuper;


class GameTexture {
  late final String assetPath;
  late final String? depthMapPath;
  late final String name;
  late final int width;
  late final int height;

  Image? _albedoMap;
  Image? _depthMap;

  GameTexture.fromPath({
    required this.assetPath,
  });


  GameTexture.fromMetadata(Map<String, dynamic> metadata, String basePath){
    name = metadata['name'];
    assetPath = "$basePath/name";
    depthMapPath = metadata['depthMap']?['customPath'] ?? "${assetPath}_depth.png";

    registerExtra(metadata);
  }

  /// can be overridden to add extra metadata fields
  void registerExtra(Map<String, dynamic> metadata){}

  @mustCallSuper
  void dispose(){
    _albedoMap?.dispose();
    _depthMap?.dispose();
  }
}