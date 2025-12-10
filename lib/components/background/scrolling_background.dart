import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:mpg_achievements_app/mpg_pixel_adventure.dart';

class ScrollingBackground extends Component with HasGameReference<PixelAdventure> {
  //Background color is set in Tiled builder for each level in the property backgroundColor
  final String color;
  //sets how fast the background scrolls
  double scrollSpeed = 0.04;
  Vector2 size = Vector2.all(64.8);

  ScrollingBackground({this.color = "blue"}) : super(priority: -32000);


  @override
  void render(Canvas canvas) {
    final Image? img = image;
    if(img == null) return;

    final double zoom = game.cam.viewfinder.zoom;

    //calculate the position of the tile
    final double distance = ((DateTime.now().millisecondsSinceEpoch) * scrollSpeed) % size.y;
    final Vector2 pos = Vector2.all(distance) - size*2; //start just above the screen with a bit of offset to give the effect of movement

    //tile the image to fill the screen

    final Vector2 startPos = pos + (game.cam.viewfinder.position - (game.cam.viewport.virtualSize / 2) / zoom);
    final Vector2 endPos = startPos + (screenSize / zoom) + size*2;
    
    final double sizeExtend = 0.5/CameraComponent.currentCamera!.viewfinder.zoom;
    
    for(double x = startPos.x; x < endPos.x; x += size.x) {
      for(double y = startPos.y; y < endPos.y; y += size.y) {
        canvas.drawImageRect(
          img,
          Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()),
          Rect.fromLTWH(x, y, size.x+sizeExtend, size.y+sizeExtend),
          Paint(),
        );
      }
    }
  }


  Image? get image {
    if(!tileImages.containsKey(color)) {
      loadImage(color);
      return null;
    }
    return tileImages[color];
  }
  static Map<String, Image> tileImages = {};

  Set<String> currentlyLoadingImages = {};

  void loadImage(String color) {
    if(currentlyLoadingImages.contains(color)) return;
    currentlyLoadingImages.add(color);
    Flame.images.load('Background/$color.png').then((img) {
      tileImages[color] = img;
      currentlyLoadingImages.remove(color);
    });
  }
}
