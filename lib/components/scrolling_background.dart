
import 'dart:async';

import 'package:flame/components.dart';
import 'package:mpg_achievements_app/components/background_tile.dart';
import 'package:mpg_achievements_app/components/camera/AdvancedCamera.dart';

class ScrollingBackground extends Component with HasGameReference{

  AdvancedCamera? camera;

  late Vector2 size;

  Set<BackgroundTile> tiles = {};

  Vector2 tileSpeed = Vector2.all(40);

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

    updateTiles(size);

    return super.onLoad();
  }

  @override
  void update(double dt) {
    time+= dt;
    double zoom = camera?.viewfinder.zoom ?? 1;
    Vector2 cameraPos = camera?.viewfinder.position ?? Vector2.zero();
    if(camera != null && camera?.viewfinder != null) {
      cameraPos -= camera!.viewfinder.anchor.toVector2();
    }

    for (var value in tiles) {
      value.position = calculateAbsoluteTilePosition(value.backgroundPos, cameraPos, zoom, Vector2.all(64));
      value.position += tileSpeed * time;
      value.position += Vector2(64, 64) - cameraPos + size / 2;
      value.position %= size - size % Vector2.all(64);
      value.position -= Vector2(64, 64) - cameraPos + size / 2;
    }
  }

  Vector2 calculateAbsoluteTilePosition(Vector2 relativePos, Vector2 cameraPos, double zoom, Vector2 tileSize){
    relativePos = relativePos.clone();
    cameraPos = cameraPos.clone();
    tileSize = tileSize.clone();

    tileSize.x *= zoom;
    tileSize.y *= zoom;


    relativePos.x *= tileSize.x;
    relativePos.y *= tileSize.y;




    return relativePos + cameraPos;
  }

  void updateTiles(Vector2 viewportSize, {double zoom = 1, double tileWidth = 64, double tileHeight = 64}){
    int tilesX = (viewportSize.x / (tileWidth * zoom)).floor() + 1;
    int tilesY = (viewportSize.y / (tileHeight * zoom)).floor() + 1;

    for (int x = -1; x < tilesX-1; x++) {
      for (int y = -1; y < tilesY-1; y++) {
        BackgroundTile tile = BackgroundTile(color: tileColor, backgroundPos: Vector2(x.toDouble(), y.toDouble()));
        tiles.add(tile);
        add(tile);
      }
    }
  }
}