import 'dart:async';

import 'package:flame/components.dart';
import 'package:mpg_achievements_app/components/background/Background.dart';
import 'package:mpg_achievements_app/components/background/background_tile.dart';
import 'package:mpg_achievements_app/components/camera/AdvancedCamera.dart';
import 'package:mpg_achievements_app/mpg_pixel_adventure.dart';

class ScrollingBackground extends Background with HasGameReference{

  AdvancedCamera? camera;

  late Vector2 size;

  Set<BackgroundTile> tiles = {};

  Vector2 tileSpeed = Vector2(tilesize.x, tilesize.z);

  double time = 0;

  String tileColor;
  ScrollingBackground({this.tileColor = "blue", this.camera});
  @override
  FutureOr<void> onLoad() {
    priority = -1;

    if (camera == null) { //if no camera is given, then use the game size.
      size = game.size;
    }
    else { //if a camera is given, then you can get the visible game size, with the zoom of it calculated.
      size = game.size * camera!.viewfinder.zoom;
    }
    size = game.size;

    updateTiles(size); //adds and positions the tiles

    return super.onLoad();
  }

  @override
  void update(double dt) {
    time+= dt; //increase the time variable

    double zoom = camera?.viewfinder.zoom ?? 1; //if a camera is given, then we take the zoom from it. otherwise it gets set to 1
    Vector2 cameraPos = camera?.viewfinder.position ?? Vector2.zero(); //the same for the position
    if(camera != null && camera?.viewfinder != null) {
      cameraPos -= camera!.viewfinder.anchor.toVector2(); //if the anchor is the centre of the screen for example, we need to subtract these coordinates
    }

    for (var value in tiles) { //for every tile
      value.position = calculateAbsoluteTilePosition(value.backgroundPos, cameraPos, zoom, Vector2.all(64)); //get the position of the tile without the animation
      value.position += tileSpeed * time; //add the animation
      value.position += Vector2(64, 64) - cameraPos + size / 2; //move to the side so that the modulo can work
      value.position %= size - size % Vector2.all(64); //modulo to reset the tile of its out of the screen
      value.position -= Vector2(64, 64) - cameraPos + size / 2; //move the tiles back
    }

    time %= double.maxFinite-1000; //if the time is close to the double limit, then reset it
  }

  Vector2 calculateAbsoluteTilePosition(Vector2 relativePos, Vector2 cameraPos, double zoom, Vector2 tileSize){ //relativePos is the coordinate of the tile, so 1|1, 2|1 3|1 usw.
    relativePos = relativePos.clone(); //clone so that no references will get created
    cameraPos = cameraPos.clone();
    tileSize = tileSize.clone();

    tileSize.x *= zoom; //tilesize is affected by zoom
    tileSize.y *= zoom;


    relativePos.x *= tileSize.x;
    relativePos.y *= tileSize.y;

    return relativePos + cameraPos;//add the cameraPos so that it moves with the camera
  }

  void updateTiles(Vector2 viewportSize, {double zoom = 1, double tileWidth = 64, double tileHeight = 64}){ //adds all of the tiles and positions them
    int tilesX = (viewportSize.x / (tileWidth * zoom)).floor() + 1; //calculates the optimal amount of tiles for the different axis
    int tilesY = (viewportSize.y / (tileHeight * zoom)).floor() + 1;

    for (int x = -1; x < tilesX-1; x++) {
      for (int y = -1; y < tilesY-1; y++) {
        BackgroundTile tile = BackgroundTile(color: tileColor, backgroundPos: Vector2(x.toDouble(), y.toDouble()));
        tiles.add(tile); //adds it to the list
        add(tile); //adds it to the component
      }
    }
  }
}