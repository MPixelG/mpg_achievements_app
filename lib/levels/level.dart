import 'dart:async';
import 'package:flame/components.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:mpg_achievements_app/actors/player.dart';

class Level extends World {
  late TiledComponent level;
  //loads when the class instantiated
  //In dart, late keyword is used to declare a variable or field that will be initialized at a later time.e.g. late String name
  //
  @override
  FutureOr<void> onLoad() async {
    //await need to be there because it takes some time to load, that's why the method needs to be async
    //otherwise the rest of the programme would stop
    //16 is 16x16 of our tileset
     level = await TiledComponent.load('Level_0.tmx', Vector2.all(16));
     add(level);
     add(Player());
     //runs all the other onLoad-events the method is referring to, now not important
     return super.onLoad();
  }
}