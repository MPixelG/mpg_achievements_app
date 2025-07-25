import 'package:flame/flame.dart';
import 'package:flutter/material.dart';
import 'package:mpg_achievements_app/components/GUI/Menus.dart';
import 'package:mpg_achievements_app/components/util/utils.dart';
// must be async because device loads fullScreen and setsLandscape and then at last the joystick
void main() async {
  //Wait until the Flutter Widget is initialised
  WidgetsFlutterBinding.ensureInitialized();
  //Game then runs in Fullscreen mode and Landscape
  await Flame.device.fullScreen();
  await Flame.device.setLandscape();
  //reference to our class where the game is programmed
  //just helps to not load the game every time you change something in the code only for development
  //later changed to only game when deploying

  runApp(MaterialApp(
    home: MainMenuScreen(),
    debugShowCheckedModeBanner: false
  ));
  

  
}
