import 'dart:async';

import 'package:flame/components.dart';

//HasGameReference to load images from Cache
class BackgroundTile extends SpriteComponent with HasGameReference {
  //Background color is set in Tiled builder for each level in the property backgroundColor
  final String color;

  //sets how fast the backlground scrolls
  final double scrollSpeed = 0.4;

  Vector2 backgroundPos = Vector2.zero();


  BackgroundTile({required this.color, required this.backgroundPos});
  @override
  FutureOr<void> onLoad() {
    //background priority can be set to change order in layers
    priority = -10;

    //64.6 so we do not see gaps between the tiles
    size = Vector2.all(64.6);
    sprite = Sprite(game.images.fromCache('Background/$color.png'));

    return super.onLoad();
  }
}
