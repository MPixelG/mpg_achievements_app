import 'dart:async';

import 'package:flame/components.dart';
//HasGameReference to load images from Cache
class BackgroundTile extends SpriteComponent with HasGameReference{
  final String color;
  BackgroundTile({this.color = "Gray", position}):
        super(position: position);
@override
  FutureOr<void> onLoad() {
  //64.6 so we do not see gaps between the tiles
  //background priority can be set to change order in layers
  //Todo make obstacles visible
    priority = 0;
    size = Vector2.all(64.6);
    sprite = Sprite(game.images.fromCache('Background/$color.png'));
    return super.onLoad();
  }
  }




