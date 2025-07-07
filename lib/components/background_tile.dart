import 'dart:async';

import 'package:flame/components.dart';

//HasGameReference to load images from Cache
class BackgroundTile extends SpriteComponent with HasGameReference {
  //Background color is set in Tiled builder for each level in the property backgroundColor
  final String color;
  BackgroundTile({required this.color, super.position});

  //sets how fast the backlground scrolls
  final double scrollSpeed = 0.4;

  @override
  FutureOr<void> onLoad() {
    //64.6 so we do not see gaps between the tiles
    //background priority can be set to change order in layers

    priority = -1;
    size = Vector2.all(64.6);
    sprite = Sprite(game.images.fromCache('Background/$color.png'));
    return super.onLoad();
  }

  @override
  void update(double dt) {
    //constantly increasing the BackgroundTiles positions to simulate a scrolling background
    position.y += scrollSpeed;
    double tileSize = 64;
    //calculating the total height of all BackgroundTiles
    int scrollHeight = (game.size.y / tileSize).floor();
    //resetting position if out of set border / - tileSize = -64 which means that the tile is set to y out of our window to hide the tile when it is repeating
    if (position.y > scrollHeight * tileSize){ position.y = -tileSize;}
    super.update(dt);
  }
}
