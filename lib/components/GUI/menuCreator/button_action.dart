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
        return DebugButtonAction(printText: json["text"] ?? "Debug Button Pressed!");
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

  String printText;


  DebugButtonAction({this.printText = "Debug Button Pressed!"});

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
      "text": printText,
      "actionType": actionType,
    };
  }
}