import 'dart:convert';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mpg_achievements_app/components/dialogue_utils/dialogue_screen.dart';
import 'package:mpg_achievements_app/components/shaders/shader_manager.dart';
import 'package:mpg_achievements_app/components/GUI/menuCreator/gui_editor.dart';
import 'package:mpg_achievements_app/components/dialogue_utils/text_overlay.dart';
import 'package:mpg_achievements_app/mpg_pixel_adventure.dart';
import '../dialogue_utils/text_overlay.dart';
import 'json_factory/widgetFactory.dart';

abstract class Screen extends StatelessWidget {

  final Map<String, Screen> children = {};

  Screen({super.key, children});
}

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: FutureBuilder<Widget>(
        future: WidgetFactory.loadFromJson('assets/screens/test.json', context),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return snapshot.data!;
          }
          return Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}
class GameScreen extends StatelessWidget {
  final PixelAdventure game;

  const GameScreen({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Stack(
        children: [GameWidget(game: game,
          overlayBuilderMap: {
            "guiEditor": (BuildContext context, PixelAdventure game){
              return game.guiEditor;
              },
            //Overlay is registered in overlayBuilderMap
            'TextOverlay':(BuildContext context, PixelAdventure game){
              return TextOverlay(game: game);
            },
            'DialogueScreen':(BuildContext context, PixelAdventure game){
              return DialogueScreen(game: game,
                onDialogueFinished: () {
                game.overlays.remove('DialogueScreen'); },);
            }
          },

        ),]
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