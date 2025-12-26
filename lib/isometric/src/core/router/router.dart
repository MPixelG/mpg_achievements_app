import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mpg_achievements_app/mpg_pixel_adventure.dart';
import 'package:mpg_achievements_app/tools/GUI/gamescreen_3d.dart';
import 'package:mpg_achievements_app/tools/GUI/menuCreator/components/gui_editor.dart';
import 'package:mpg_achievements_app/tools/GUI/menus.dart';


// This key will be used to access the NavigatorState of the root router
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();


class AppRouter {
  static GameScreen gameScreen = GameScreen(
    game: PixelAdventure.currentInstance,
  );
  static GuiEditor guiEditor = const GuiEditor();
  //static ThermionViewer thermionViewer = thermionViewer;

  static final GoRouter router = GoRouter(
    navigatorKey: rootNavigatorKey,
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
      GoRoute(
        path: "/thermionViewer",
        name: "thermionViewer",
        builder: (context,state) => const GameScreen3d(title: "test"),
      ),
    ],
  );
}

