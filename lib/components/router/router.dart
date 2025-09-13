
import 'package:go_router/go_router.dart';
import 'package:mpg_achievements_app/components/GUI/menuCreator/components/gui_editor.dart';
import 'package:mpg_achievements_app/components/GUI/menus.dart';
import 'package:mpg_achievements_app/mpg_pixel_adventure.dart';

class AppRouter {

  static GameScreen gameScreen = GameScreen(game: PixelAdventure.currentInstance);
  static GuiEditor guiEditor = GuiEditor();

  static final GoRouter router = GoRouter(
      routes: [
        GoRoute(path: "/", name: "main_menu", builder: (context, state) => MainMenuScreen()),
        GoRoute(path: "/game", name: "game", builder: (context, state) => gameScreen),
        GoRoute(path: "/settings", builder: (context, state) => MainMenuScreen()),
        GoRoute(path: "/widgetBuilder", name: "widgetBuilder", builder: (context, state) => guiEditor),
      ]
  );




}