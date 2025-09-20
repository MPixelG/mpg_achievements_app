import 'package:flame/game.dart';
import 'package:flame_riverpod/flame_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mpg_achievements_app/components/dialogue_utils/dialogue_screen.dart';
import 'package:mpg_achievements_app/components/dialogue_utils/text_overlay.dart';
import 'package:mpg_achievements_app/main.dart';
import 'package:mpg_achievements_app/mpg_pixel_adventure.dart';

import '../components/dialogue_utils/speechbubble.dart';
import 'json_factory/json_exporter.dart';
import 'menuCreator/components/dependencyViewer/layout_widget.dart';

abstract class Screen extends StatelessWidget {
  final Map<String, Screen> children = {};
  Screen({super.key, children});
}

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  LayoutWidget? loadedWidget;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadScreen();
  }

  Future<void> _loadScreen() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      // Add a small delay to ensure the widget tree is fully built
      await Future.delayed(const Duration(milliseconds: 100));

      final widget = await WidgetJsonUtils.importScreen("test", context: context);

      setState(() {
        loadedWidget = widget;
        isLoading = false;
      });

    } catch (e, stackTrace) {
      if(kDebugMode) {
        print("Error loading screen: $e");
        print("Stack trace: $stackTrace");
      }

      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      // Remove any default padding from Scaffold
      body: Container(
        width: screenSize.width,
        height: screenSize.height,
        // Explicitly remove all padding and margin
        padding: EdgeInsets.zero,
        margin: EdgeInsets.zero,
        child: _buildContent(context, screenSize),
      ),
    );
  }

  Widget _buildContent(BuildContext context, Size screenSize) {
    if (isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text("Loading GUI...", style: TextStyle(color: Colors.white)),
          ],
        ),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Error loading GUI:",
              style: TextStyle(color: Colors.red, fontSize: 18),
            ),
            SizedBox(height: 8),
            Text(
              errorMessage!,
              style: TextStyle(color: Colors.white, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadScreen,
              child: Text("Retry"),
            ),
          ],
        ),
      );
    }

    if (loadedWidget == null) {
      return const Center(
        child: Text(
          "No widget loaded",
          style: TextStyle(color: Colors.white),
        ),
      );
    }


    try {
      return SizedBox(
        width: screenSize.width,
        height: screenSize.height,
        child: loadedWidget!.build(context),
      );
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print("Error building widget: $e");
        print("Stack trace: $stackTrace");
      }
      return Center(
        child: Text(
          "Error building GUI: $e",
          style: TextStyle(color: Colors.red),
          textAlign: TextAlign.center,
        ),
      );
    }
  }
}

class GameScreen extends StatelessWidget {
  final PixelAdventure game;



  const GameScreen({super.key, required this.game});


  @override
  Widget build(BuildContext context) {
    return RiverpodAwareGameWidget<PixelAdventure>(
      key: gameWidgetKey,
      game: game,
      overlayBuilderMap: {
        'TextOverlay': (BuildContext context, PixelAdventure game) {
          return TextOverlay(
            game: game, onTextOverlayDone: () {game.overlays.remove("TextOverlay");},
          );
        },
        'DialogueScreen': (BuildContext context, PixelAdventure game) {
          return DialogueScreen(
            game: game,
            //when Dialogue is finishes screen is removed form map
            onDialogueFinished: () {
              game.overlays.remove('DialogueScreen');
            },
          );
        },
        'SpeechBubble': (BuildContext context, PixelAdventure game) {
          return SpeechBubble(
            game: game,
            characterName: game.gameWorld.player.playerCharacter,
            targetPosition: game.gameWorld.player.position.toOffset(),
            currentPosition: game.gameWorld.player.position.toOffset(),
            onComplete: () {
              game.overlays.remove('SpeechBubble');
            },
            onDismiss: () {
              game.overlays.remove('SpeechBubble');
            },
          );
        },
      },
    );
  }
}