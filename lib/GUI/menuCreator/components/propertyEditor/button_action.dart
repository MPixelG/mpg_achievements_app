import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart' show GoRouterHelper;

class ButtonAction {
  late final String actionType; // Default action type for button actions

  ButtonAction() {
    init();
  }
  void init() {
    actionType = "default";
  }

  void press(BuildContext context) {}

  factory ButtonAction.fromJson(Map<String, dynamic> json) {
    switch (json["actionType"]) {
      case "debug":
        return DebugButtonAction(json);
      case "screenChange":
        return ScreenChangeButtonAction(json);
      default:
        return ButtonAction();
    }
  }

  Map<String, dynamic> toJson() {
    return {"actionType": actionType};
  }
}

class DebugButtonAction extends ButtonAction {
  late String printText;

  DebugButtonAction([Map<String, dynamic>? properties]) {
    properties ??= {};

    properties.removeWhere(
      (key, value) => key != "printText" && key != "actionType",
    );

    properties["printText"] ??= "Debug button pressed!";

    printText = properties["printText"];
  }

  @override
  void press(BuildContext context) {
    if (kDebugMode) {
      print(printText);
    }
  }

  @override
  void init() {
    actionType = "debug";
  }

  @override
  Map<String, dynamic> toJson() {
    return {"printText": printText, "actionType": actionType};
  }
}

class ScreenChangeButtonAction extends ButtonAction {
  late String screen;

  ScreenChangeButtonAction([Map<String, dynamic>? properties]) {
    properties ??= {};

    properties.removeWhere(
      (key, value) => key != "screen" && key != "actionType",
    );

    properties["screen"] ??= "";

    screen = properties["screen"];
  }

  @override
  void press(BuildContext context) {
    context.goNamed(screen);
  }

  @override
  void init() {
    actionType = "screenChange";
  }

  @override
  Map<String, dynamic> toJson() {
    return {"screen": screen, "actionType": actionType};
  }
}
