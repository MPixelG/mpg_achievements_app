import 'dart:convert';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mpg_achievements_app/components/GUI/menuCreator/layout_widget.dart';
import 'package:mpg_achievements_app/components/GUI/menuCreator/widget_builder.dart';
import 'package:mpg_achievements_app/components/GUI/widgets/nine_patch_button.dart';

class WidgetJsonUtils {
  static String exportWidgetToJson(LayoutWidget widget) {
    Map<String, dynamic> widgetData = _buildWidgetMap(widget);
    return _formatJson(widgetData);
  }

  static Map<String, dynamic> _buildWidgetMap(LayoutWidget widget) {
    return {
      'id': widget.id,
      'widgetType': widget.widgetType.toString(),
      'properties': convertProperties(widget.properties),
      'children': widget.children.map((child) => _buildWidgetMap(child)).toList(),
    };
  }


  static dynamic convertProperties(dynamic input) {
    if (input is Map) {
      return input.map((key, value) => MapEntry(
        key.toString(),
        convertProperties(value),
      ));
    } else if (input is List) {
      return input.map(convertProperties).toList();
    } else if (input is Color) {
      return colorToMap(input);
    } else {
      return input;
    }
  }
  static dynamic restoreProperties(dynamic input) {
    if (input is Map<String, dynamic>) {
      if (input.keys.toSet().containsAll(['a', 'r', 'g', 'b']) &&
          input.length == 4 &&
          input.values.every((v) => v is double)) {
        return mapToColor(input);
      }

      return input.map((key, value) => MapEntry(
        key.toString(),
        restoreProperties(value),
      ));
    } else if (input is List) {
      return input.map(restoreProperties).toList();
    } else {
      return input;
    }
  }

  static Future<LayoutWidget> importScreen(String name) async {
    final jsonMap = await loadJson(name);
    return WidgetJsonUtils.importWidget(jsonMap);
  }
  static Future<Map<String, dynamic>> loadJson(String name) async {
    final jsonString = await rootBundle.loadString("assets/screens/$name.json");
    final jsonMap = json.decode(jsonString);
    return Map<String, dynamic>.from(jsonMap);
  }



  static LayoutWidget importWidget(Map<String, dynamic> data, {LayoutWidget? parent}) {
    final restoredProps = restoreProperties(data['properties']);

    Type widgetType = parseWidgetType(data['widgetType']);


    LayoutWidget widget = switch(widgetType){
      Container => addContainer(parent, properties: restoredProps),
      Row => addRow(parent, properties: restoredProps),
      Column => addColumn(parent, properties: restoredProps),
      Text => addText(restoredProps["text"], parent, properties: restoredProps),
      Stack => addStack(parent, properties: restoredProps),
      Positioned => addPositioned(parent, properties: restoredProps)!,
      Expanded => addExpanded(parent, properties: restoredProps)!,
      NinePatchButton => addNinepatchButton(parent, properties: restoredProps),
      FittedBox => addFittedBox(parent, properties: restoredProps),
      Transform => addTransform(parent, properties: restoredProps),
      Opacity => addOpacity(parent, properties: restoredProps),
      Card => addCard(parent, properties: restoredProps),
      GridView => addGridView(parent, properties: restoredProps),

      _ => throw UnimplementedError("the widget type $widgetType cant be created yet! please add it first!")
    };


    List<LayoutWidget> children = (data['children'] as List)
        .map((child) => importWidget(Map<String, dynamic>.from(child), parent: widget))
        .toList();

    widget.addChildren(children);

    return widget;
  }

  static Type parseWidgetType(String widgetType) {
    switch (widgetType) {
      case 'Container':
        return Container;
      case 'Text':
        return Text;
        case 'Row': return Row;
      case 'Column': return Column;
      case 'Stack': return Stack;
      case 'Image':
        return Image;
      case 'Button':
        return ElevatedButton;
      case 'Icon':
        return Icon;
      case 'ListView':
        return ListView;
      case 'GridView':
        return GridView;
      case 'Expanded':
        return Expanded;
      case 'NinePatchButton':
        return NinePatchButton;
      case 'Scaffold':
        return Scaffold;
      case 'AppBar':
        return AppBar;
      case 'Drawer':
        return Drawer;
      case 'BottomNavigationBar':
        return BottomNavigationBar;
      case 'TabBar':
        return TabBar;
      case 'TabBarView':
        return TabBarView;
      case 'Form':
        return Form;
      case 'TextField':
        return TextField;
      case 'Checkbox':
        return Checkbox;
      case 'Radio':
        return Radio;
      case 'Switch':
        return Switch;
      case 'Slider':
        return Slider;
      case 'ProgressIndicator':
        return CircularProgressIndicator;
      case 'LinearProgressIndicator':
        return LinearProgressIndicator;
      case 'AlertDialog':
        return AlertDialog;
      case 'SnackBar':
        return SnackBar;
      case 'Tooltip':
        return Tooltip;
      case 'MaterialApp':
        return MaterialApp;

      default:
        throw Exception('Unknown widget type: $widgetType');
    }
  }




  static String _formatJson(Map<String, dynamic> jsonMap) {
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(jsonMap);
  }

}

Map<String, double> colorToMap(Color color) => {
  'a': color.a,
  'r': color.r,
  'g': color.g,
  'b': color.b,
};

Color mapToColor(Map<String, dynamic> map) {
  return Color.from(alpha: map['a'],red: map['r'], green: map['g'], blue: map['b']);
}