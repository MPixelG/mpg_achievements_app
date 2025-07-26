import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../mpg_pixel_adventure.dart';
import '../Menus.dart';

class WidgetFactory {

  static Widget buildFromJson(Map<String, dynamic> json, BuildContext context) {
    final type = json['type'];

    switch (type) {
      case 'ElevatedButton':
        return _buildElevatedButton(json, context);
      case 'TextButton':
        return _buildTextButton(json, context);
      default:
        throw Exception('Unknown widget type: $type');
    }
  }

  static Widget _buildElevatedButton(Map<String, dynamic> json, BuildContext context) {
    final properties = json['properties'];
    final action = json['action'];

    return SizedBox(
      width: properties['width']?.toDouble(),
      height: properties['height']?.toDouble(),
      child: ElevatedButton(
        onPressed: action != null
            ? () => executeAction(
            action['type'],
            action['params'],
            context
        )
            : null,
        child: Text(properties['text'] ?? ''),
      ),
    );
  }

  static Widget _buildTextButton(Map<String, dynamic> json, BuildContext context) {
    final properties = json['properties'];
    final action = json['action'];

    return SizedBox(
      width: properties['width']?.toDouble(),
      height: properties['height']?.toDouble(),
      child: TextButton(
        onPressed: action != null
            ? () => executeAction(
            action['type'],
            action['params'],
            context
        )
            : null,
        style: TextButton.styleFrom(
          foregroundColor: properties['textColor'] != null
              ? Color(int.parse(properties['textColor'].substring(1), radix: 16))
              : null,
          backgroundColor: properties['backgroundColor'] != null
              ? Color(int.parse(properties['backgroundColor'].substring(1), radix: 16))
              : null,
          textStyle: TextStyle(
            fontSize: properties['fontSize']?.toDouble() ?? 14.0,
            fontWeight: properties['fontWeight'] == 'bold'
                ? FontWeight.bold
                : FontWeight.normal,
          ),
          padding: EdgeInsets.all(properties['padding']?.toDouble() ?? 8.0),
        ),
        child: Text(
          properties['text'] ?? '',
          textAlign: properties['textAlign'] == 'center'
              ? TextAlign.center
              : TextAlign.left,
        ),
      ),
    );
  }

  static void switchMenu(String menuName) {}

  static final Map<String, Function> _actions = {
    'screen_change': _handleScreenChange,
    'start_game': _handleStartGame,
    'pause_game': _handlePauseGame,
    'restart_game': _handleRestartGame,
    'show_settings': _handleShowSettings,
    'back_to_menu': _handleBackToMenu,
  };

  static void executeAction(
    String actionType,
    Map<String, dynamic>? params,
    BuildContext context,
  ) {
    final action = _actions[actionType];
    if (action != null) {
      action(params, context);
    } else {
      print('Unbekannte Action: $actionType');
    }
  }

  static void _handleStartGame(
    Map<String, dynamic>? params,
    BuildContext context,
  ) {
    final game = PixelAdventure();

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => GameScreen(game: game)),
    );
  }

  static void _handlePauseGame(
    Map<String, dynamic>? params,
    BuildContext context,
  ) {} //TODO

  static void _handleBackToMenu(
    Map<String, dynamic>? params,
    BuildContext context,
  ) {
    Navigator.pop(context);
  }

  static void _handleRestartGame(
    Map<String, dynamic>? params,
    BuildContext context,
  ) {
    Navigator.pop(context);
    final newGame = PixelAdventure();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => GameScreen(game: newGame)),
    );
  }

  static void _handleScreenChange(
    Map<String, dynamic>? params,
    BuildContext context,
  ) {
    final targetScreen = params?['target_screen'];
    Navigator.pushNamed(context, '/$targetScreen');
  }

  static void _handleShowSettings(
    Map<String, dynamic>? params,
    BuildContext context,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('SETTINGS'),
        content: Text('Settings Dialog hier'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Schließen'),
          ),
        ],
      ),
    );
  }
}
