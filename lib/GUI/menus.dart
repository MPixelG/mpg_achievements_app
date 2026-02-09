import 'package:flame_riverpod/flame_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mpg_achievements_app/core/base_game.dart';
import 'package:mpg_achievements_app/main.dart';

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

      final widget = await WidgetJsonUtils.importScreen("test");

      setState(() {
        loadedWidget = widget;
        isLoading = false;
      });
    } catch (e, stackTrace) {
      if (kDebugMode) {
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
            const Text(
              "Error loading GUI:",
              style: TextStyle(color: Colors.red, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage!,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadScreen, child: const Text("Retry")),
          ],
        ),
      );
    }

    if (loadedWidget == null) {
      return const Center(
        child: Text("No widget loaded", style: TextStyle(color: Colors.white)),
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
          style: const TextStyle(color: Colors.red),
          textAlign: TextAlign.center,
        ),
      );
    }
  }
}

class GameScreen extends StatelessWidget {
  final BaseGame game;

  const GameScreen({super.key, required this.game});

  @override
  Widget build(BuildContext context) => RiverpodAwareGameWidget<BaseGame>(
      key: gameWidgetKey,
      game: game,
      overlayBuilderMap: game.buildOverlayMap()
    );
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
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

      // kleine Verzögerung, damit Widget-Baum bereit ist
      await Future.delayed(const Duration(milliseconds: 100));

      final widget = await WidgetJsonUtils.importScreen(
        "settings", // Settings Widget
      );

      setState(() {
        loadedWidget = widget;
        isLoading = false;
      });
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print("Error loading settings screen: $e");
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
      body: Container(
        width: screenSize.width,
        height: screenSize.height,
        padding: EdgeInsets.zero,
        margin: EdgeInsets.zero,
        child: _buildContent(context, screenSize),
      ),
    );
  }

  Widget _buildContent(BuildContext context, Size screenSize) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage != null) {
      return Center(
        child: Text(
          "Error loading settings: $errorMessage",
          style: const TextStyle(color: Colors.red),
          textAlign: TextAlign.center,
        ),
      );
    }

    if (loadedWidget == null) {
      return const Center(
        child: Text("No widget loaded", style: TextStyle(color: Colors.white)),
      );
    }

    return SizedBox(
      width: screenSize.width,
      height: screenSize.height,
      child: loadedWidget!.build(context),
    );
  }
}


