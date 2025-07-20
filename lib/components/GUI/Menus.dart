import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:mpg_achievements_app/mpg_pixel_adventure.dart';

abstract class Screen extends StatelessWidget {

  final Map<String, Screen> children = {};

  Screen({super.key, children});
}

class MainMenuScreen extends Screen {
  MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/MPG_low_resolution_640_368.png'),
          colorFilter: ColorFilter.mode(Color.fromARGB(200, 0, 0, 0), BlendMode.srcOver),
          fit: BoxFit.cover,
        ),
      ),
      child: Center(
        child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => GameScreen(game: PixelAdventure())
                    )
                ),
                style: ButtonStyle(
                    alignment: Alignment.center,
                    backgroundColor: WidgetStatePropertyAll(Color.fromARGB(255, 44, 166, 12)),
                    elevation: WidgetStatePropertyAll(3),
                    textStyle: WidgetStatePropertyAll(TextStyle(fontFamily: "gameFont"))
                ),
                child: Text("PLAY"),
              )
            ]
        ),
      ),


    ),
    );
  }
}

class GameScreen extends StatelessWidget {
  final PixelAdventure game;

  const GameScreen({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return MaterialApp( // Wichtig: MaterialApp-Wrapper
      home: Scaffold(
        body: GameWidget(game: game),
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}