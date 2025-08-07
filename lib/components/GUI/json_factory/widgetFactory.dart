import 'dart:convert';

import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mpg_achievements_app/components/GUI/widgets/nine_patch_button.dart';
import 'package:mpg_achievements_app/components/shaders/shader_manager.dart';

import '../../../mpg_pixel_adventure.dart';
import '../menus.dart';

class WidgetFactory{

  static Future<Widget>? loadFromJson(String jsonName, BuildContext context) async{
    final jsonString = await rootBundle.loadString(jsonName);
    final Map<String, dynamic> screenData = json.decode(jsonString);

    Widget widget = buildWidget(screenData, context);

    return widget;
  }

  static Widget buildWidget(Map<String, dynamic> json, BuildContext context){
    String type = json["type"];


    Map<String, dynamic>? properties = json["properties"];
    List<dynamic> children = json["children"];

    return switch (type) {
      "Container" => _buildContainer(properties, children, context),
      "Column" => _buildColumn(properties, children, context),
      "Row" => _buildRow(properties, children, context),
      "Button" => _buildButton(properties, children, context),
      //"SpeechBubble" => _buildSpeechBubble(properties, children, context),

      _ => throw UnimplementedError("Component $type not implemented!")
    };
  }


  static Container _buildContainer(Map<String, dynamic>? properties, List<dynamic> children, BuildContext context){

    Vector2 position = getPositionProperty(properties, context.size!);
    double? width = properties?["width"];
    double? height = properties?["height"];
    EdgeInsetsGeometry padding = getPaddingProperty(properties);


    return Container(
      alignment: Alignment(position.x, position.y),
      width: width,
      height: height,
      padding: padding,
      child: buildWidget(children.first, context),
    );
  }

  static NinePatchButton _buildButton(Map<String, dynamic>? properties, List<dynamic> children, BuildContext context){

    Map<String, dynamic> borders = getOrDefault(properties, "textureBorders", {"x": 2, "x2": 2, "y": 2, "y2": 2});

    int borderX = borders["x"] ?? 2;
    int borderX2 = borders["x2"] ?? 2;
    int borderY = borders["y"] ?? 2;
    int borderY2 = borders["y2"] ?? 2;

    String imageName = properties?["texture"] ?? "button_0";

    String text = properties?["text"] ?? "";

    Map<String, dynamic> actionProperties = properties?["action"] ?? {"type": ""};

    callback() {
      final actionType = actionProperties["type"];
      final action = actions[actionType];

      if (action != null) {
        action(actionProperties, context);
      } else {
        print("unknown action: $actionType");
      }
    }


    return NinePatchButton(
      text: text,
      onPressed: callback,
    );
  }


  static Widget _buildColumn(Map<String, dynamic>? properties, List<dynamic> children, BuildContext context) {
    final mainAxisAlignment = parseMainAxisAlignment(properties?["mainAxisAlignment"]);
    final crossAxisAlignment = parseCrossAxisAlignment(properties?["crossAxisAlignment"]);

    return Column(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      children: children.map<Widget>((childJson) => buildWidget(childJson, context)).toList(),
    );
  }

  static Widget _buildRow(Map<String, dynamic>? properties, List<dynamic> children, BuildContext context) {
    final mainAxisAlignment = parseMainAxisAlignment(properties?["mainAxisAlignment"]);
    final crossAxisAlignment = parseCrossAxisAlignment(properties?["crossAxisAlignment"]);

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      children: children.map<Widget>((childJson) => buildWidget(childJson, context)).toList(),
    );
  }


  static MainAxisAlignment parseMainAxisAlignment(String? value) {
    switch (value) {
      case "start":
        return MainAxisAlignment.start;
      case "end":
        return MainAxisAlignment.end;
      case "center":
        return MainAxisAlignment.center;
      case "spaceBetween":
        return MainAxisAlignment.spaceBetween;
      case "spaceAround":
        return MainAxisAlignment.spaceAround;
      case "spaceEvenly":
        return MainAxisAlignment.spaceEvenly;
      default:
        return MainAxisAlignment.start;
    }
  }

  static CrossAxisAlignment parseCrossAxisAlignment(String? value) {
    switch (value) {
      case "start":
        return CrossAxisAlignment.start;
      case "end":
        return CrossAxisAlignment.end;
      case "center":
        return CrossAxisAlignment.center;
      case "stretch":
        return CrossAxisAlignment.stretch;
      case "baseline":
        return CrossAxisAlignment.baseline;
      default:
        return CrossAxisAlignment.center;
    }
  }




  static Map<String, Function> actions = {
    "": (){print("empty action!");},
    "start_game": _handleStartGame,
    "screen_change": _handleScreenChange
  };


  static void _handleStartGame(
      Map<String, dynamic>? params,
      BuildContext context,
      ) {
    final PixelAdventure game = PixelAdventure();


    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => GameScreen(game: game)),
    );
  }

  static void _handleScreenChange(
      Map<String, dynamic>? params,
      BuildContext context,
      ) {
    final targetScreen = params?['val'];
    Navigator.pushNamed(context, '/$targetScreen');
  }



  static Vector2 getPositionProperty(Map<String, dynamic>? properties, Size size){
    Map<String, dynamic> pos = getOrDefault(properties, "position", {"x": 0.5.toDouble(), "y": 0.5.toDouble()});

    double? x = pos["x"];
    double? y = pos["y"];

    if(x == null || y == null) return (size / 2).toVector2(); //in the middle of the screen if no val is given

    return Vector2(x * size.width, y * size.height);
  }

  static EdgeInsetsGeometry getPaddingProperty(Map<String, dynamic>? properties){
    Map<String, dynamic> padding = getOrDefault(properties, "padding", {"l": 0.0, "t": 0.0, "r": 0.0, "b": 0.0});

    if(padding["l"] == null) padding["l"] = 0.0;
    if(padding["t"] == null) padding["t"] = 0.0;
    if(padding["r"] == null) padding["r"] = 0.0;
    if(padding["b"] == null) padding["b"] = 0.0;

    return EdgeInsetsGeometry.fromLTRB(padding["l"]!, padding["t"]!, padding["r"]!, padding["b"]!);
  }



  static dynamic getOrDefault(Map<String, dynamic>? json, String key, dynamic defaultVal){
    if(json == null) return defaultVal;

    dynamic val = json[key];


    return (val ?? defaultVal);
  }


  // Converts a hex color string (e.g. "#FFAA00") to a [Color] object.
  // If alpha is missing (e.g. 6-digit hex), assumes full opacity (FF).
  static Color? parseHexColor(String? hex) {
    if (hex == null) return null;
    hex = hex.replaceAll("#", "");
    if (hex.length == 6) hex = "FF$hex"; // Add full alpha if missing
    return Color(int.parse("0x$hex"));
  }


  /// Converts a string like "top", "bottom", or "center" into an [Alignment] constant.
  static Alignment? parseAlignment(String? value) {
    switch (value) {
      case "top":
        return Alignment.topCenter;
      case "bottom":
        return Alignment.bottomCenter;
      case "center":
        return Alignment.center;
      case "left":
        return Alignment.centerLeft;
      case "right":
        return Alignment.centerRight;
      default:
        return Alignment.center;
    }
  }



}