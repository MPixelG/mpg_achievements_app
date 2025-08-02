class ButtonAction {
  late final String actionType; // Default action type for button actions

  ButtonAction() {init();}
  void init(){
    actionType = "default";
  }

  void press() {}

  factory ButtonAction.fromJson(Map<String, dynamic> json) {
    switch (json["actionType"]) {
      case "debug":
        return DebugButtonAction(json);
      default:
        return ButtonAction();
    }
  }

  Map<String, dynamic> toJson() {
    return {
      "actionType": actionType,
    };
  }

}

class DebugButtonAction extends ButtonAction {

  late String printText;


  DebugButtonAction([Map<String, dynamic>? properties]){
    properties ??= {};

    properties.removeWhere((key, value) => key != "printText" && key != "actionType");

    properties["printText"] ??= "Debug button pressed!";

    printText = properties["printText"];
  }

  @override
  void press() {
    print(printText);
  }

  @override
  void init() {
    actionType = "debug";
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      "printText": printText,
      "actionType": actionType,
    };
  }
}