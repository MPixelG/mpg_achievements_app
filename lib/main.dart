import 'package:flame/flame.dart';
import 'package:flame_riverpod/flame_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mpg_achievements_app/components/router/router.dart';
import 'package:mpg_achievements_app/mpg_pixel_adventure.dart';
import 'GUI/menuCreator/components/widget_declaration.dart';
import 'GUI/widgets/nine_patch_widgets.dart';

//a global key to access the game widget state from outside the RiverPodAwareGameWidget or services that live outside the game, but when Riverpod ref logic is available use the standard way of accessing the game via ref.read(gameProvider)
// because our game is of type game you would normally not need a type specifier, but here the RiverpodAwareGameWidget needs it to know which game it is dealing with
final GlobalKey<RiverpodAwareGameWidgetState<PixelAdventure>> gameWidgetKey = GlobalKey<RiverpodAwareGameWidgetState<PixelAdventure>>();

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

  NinePatchTexture.loadTextures();
  declareWidgets();

  runApp(const ProviderScope(child: MainApp(),));
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: AppRouter.router,
      debugShowCheckedModeBanner: false,
    );
  }
}
