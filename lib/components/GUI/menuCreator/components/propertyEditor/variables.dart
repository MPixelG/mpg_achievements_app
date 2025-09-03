import 'package:flutter/foundation.dart';

class GuiVariableManager {
  Map<String, GuiVariable> variables = {};

  void add(String name, Type type, [dynamic initialValue]){
    variables[name] = GuiVariable(name, type, initialValue);
  }


  void set(String variable, dynamic value) {
    variables[variable] ??= GuiVariable(variable, value.runtimeType, value);

    variables[variable]?.value = value;
  }

  dynamic get(String name){
    return variables[name]?.value;
  }

}

class GuiVariable {

  String name;

  dynamic _value;
  dynamic get value => _value;
  final Type type;

  GuiVariable(this.name, this.type, [this._value]);


  set value(dynamic newVal) {

    if(newVal.runtimeType == type || type == dynamic) {
      _value = newVal;
    } else {
      if (kDebugMode) {
        print("couldnt set variable $name from $value to $newVal because it is of type ${newVal.runtimeType} and it doesnt match the variable type of $type!");
      }
    }

  }




}