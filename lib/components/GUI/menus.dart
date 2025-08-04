import 'dart:convert';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mpg_achievements_app/components/GUI/menuCreator/json_exporter.dart';
import 'package:mpg_achievements_app/components/dialogue_utils/dialogue_screen.dart';
import 'package:mpg_achievements_app/components/shaders/shader_manager.dart';
import 'package:mpg_achievements_app/components/GUI/menuCreator/gui_editor.dart';
import 'package:mpg_achievements_app/components/dialogue_utils/text_overlay.dart';
import 'package:mpg_achievements_app/mpg_pixel_adventure.dart';
import '../dialogue_utils/text_overlay.dart';
import 'json_factory/widgetFactory.dart';
import 'menuCreator/layout_widget.dart';

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
      print("Error loading screen: $e");
      print("Stack trace: $stackTrace");

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
      print("Error building widget: $e");
      print("Stack trace: $stackTrace");
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
    return MaterialApp(
      home: Stack(
          children: [
            GameWidget(
              game: game,
              overlayBuilderMap: {
                "guiEditor": (BuildContext context, PixelAdventure game) {
                  return game.guiEditor;
                },
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
                }
              },
            ),
          ]
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}

class JsonScreenBuilder {
  static Future<Widget> buildScreen(String jsonPath, BuildContext context) async {
    try {
      final jsonString = await rootBundle.loadString(jsonPath);
      final screenData = json.decode(jsonString);

      return _buildWidgetsFromData(screenData, context);
    } catch (e) {
      return Container(child: Text('Error loading screen: $e', style: TextStyle(color: Colors.red, fontSize: 20)));
    }
  }

  static Widget _buildWidgetsFromData(Map<String, dynamic> screenData, BuildContext context) {
    return Stack(
      children: screenData['widgets'].map<Widget>((widgetData) {
        final widget = WidgetFactory.buildWidget(widgetData, context);
        final position = widgetData['position'];

        return Positioned(
          left: position['x'].toDouble(),
          top: position['y'].toDouble(),
          child: widget,
        );
      }).toList(),
    );
  }
}