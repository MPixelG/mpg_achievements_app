import 'package:go_router/go_router.dart';
import 'package:mpg_achievements_app/components/GUI/menus.dart';
import 'package:mpg_achievements_app/mpg_pixel_adventure.dart';

class AppRouter {

  static final GoRouter router = GoRouter(
      routes: [

        GoRoute(path: "/", name: "main_menu", builder: (context, state) => MainMenuScreen()),
        GoRoute(path: "/play", name: "game", builder: (context, state) => GameScreen(game: PixelAdventure())),
        GoRoute(path: "/settings", builder: (context, state) => MainMenuScreen())
      ]
  );




}