import 'package:go_router/go_router.dart';
import 'package:mpg_achievements_app/mpg_pixel_adventure.dart';

import '../../GUI/menuCreator/components/gui_editor.dart';
import '../../GUI/menus.dart';

class AppRouter {
  static GameScreen gameScreen = GameScreen(
    game: PixelAdventure.currentInstance,
  );
  static GuiEditor guiEditor = const GuiEditor();

  static final GoRouter router = GoRouter(
    routes: [
      GoRoute(
        path: "/",
        name: "main_menu",
        builder: (context, state) => const MainMenuScreen(),
      ),
      GoRoute(
        path: "/game",
        name: "game",
        builder: (context, state) => gameScreen,
      ),
      GoRoute(
        path: "/settings",
        name: "settings", // Settings
        builder: (context, state) => const SettingsScreen(),
      ),

      GoRoute(
        path: "/widgetBuilder",
        name: "widgetBuilder",
        builder: (context, state) => guiEditor,
      ),
    ],
  );
}

