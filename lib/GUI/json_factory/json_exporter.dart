import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../menuCreator/components/dependencyViewer/layout_widget.dart';
import '../menuCreator/components/widget_declaration.dart';

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
      'children': widget.children
          .map((child) => _buildWidgetMap(child))
          .toList(),
    };
  }

  static dynamic convertProperties(dynamic input) {
    if (input is Map) {
      return input.map(
        (key, value) => MapEntry(key.toString(), convertProperties(value)),
      );
    } else if (input is List) {
      return input.map(convertProperties).toList();
    } else if (input is Color) {
      return colorToMap(input);
    } else if (input is EdgeInsets) {
      // Handle EdgeInsets properly
      return {
        '_type': 'EdgeInsets',
        'left': input.left,
        'top': input.top,
        'right': input.right,
        'bottom': input.bottom,
      };
    } else if (input is BorderRadius) {
      // Handle BorderRadius properly
      return {
        '_type': 'BorderRadius',
        'topLeft': input.topLeft.x,
        'topRight': input.topRight.x,
        'bottomLeft': input.bottomLeft.x,
        'bottomRight': input.bottomRight.x,
      };
    } else if (input is TextStyle) {
      // Handle TextStyle properly
      return {
        '_type': 'TextStyle',
        'color': input.color != null ? colorToMap(input.color!) : null,
        'fontSize': input.fontSize,
        'fontWeight': input.fontWeight?.index,
        'fontFamily': input.fontFamily,
      };
    } else {
      return input;
    }
  }

  static dynamic restoreProperties(dynamic input) {
    if (input is Map<String, dynamic>) {
      // Check for special types first
      if (input.containsKey('_type')) {
        switch (input['_type']) {
          case 'EdgeInsets':
            return EdgeInsets.fromLTRB(
              input['left']?.toDouble() ?? 0.0,
              input['top']?.toDouble() ?? 0.0,
              input['right']?.toDouble() ?? 0.0,
              input['bottom']?.toDouble() ?? 0.0,
            );
          case 'BorderRadius':
            return BorderRadius.circular(input['topLeft']?.toDouble() ?? 0.0);
          case 'TextStyle':
            return TextStyle(
              color: input['color'] != null ? mapToColor(input['color']) : null,
              fontSize: input['fontSize']?.toDouble(),
              fontWeight: input['fontWeight'] != null
                  ? FontWeight.values[input['fontWeight']]
                  : null,
              fontFamily: input['fontFamily'],
            );
        }
      }

      // Check for color format (improved detection)
      if (_isColorMap(input)) {
        return mapToColor(input);
      }

      // Recursively restore other properties
      return input.map(
        (key, value) => MapEntry(key.toString(), restoreProperties(value)),
      );
    } else if (input is List) {
      return input.map(restoreProperties).toList();
    } else {
      return input;
    }
  }

  // Better color detection
  static bool _isColorMap(Map<String, dynamic> input) {
    final expectedKeys = {'a', 'r', 'g', 'b'};
    return input.keys.toSet().containsAll(expectedKeys) &&
        input.length == 4 &&
        input.values.every((v) => v is num);
  }

  static Future<LayoutWidget> importScreen(
    String name) async {
    final jsonMap = await loadJson(name);
    return WidgetJsonUtils.importWidget(jsonMap);
  }

  static Future<Map<String, dynamic>> loadJson(String name) async {
    final jsonString = await rootBundle.loadString("assets/screens/$name.json");
    final jsonMap = json.decode(jsonString);
    return Map<String, dynamic>.from(jsonMap);
  }

  static LayoutWidget importWidget(
    Map<String, dynamic> data, {
    LayoutWidget? parent,
  }) {
    // Ensure properties are properly restored
    final restoredProps = restoreProperties(data['properties']);

    LayoutWidget? widget = WidgetDeclaration.declarationCache
        .where((element) => element.id == data["widgetType"])
        .first
        .builder(parent, properties: restoredProps);

    List<LayoutWidget> children = (data['children'] as List)
        .map(
          (child) => importWidget(
            Map<String, dynamic>.from(child),
            parent: widget,
          ),
        )
        .toList();

    assert(widget != null, "${data["widgetType"]} is not a supported type!");

    widget!.addChildren(children);

    return widget;
  }

  static String _formatJson(Map<String, dynamic> jsonMap) {
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(jsonMap);
  }
}

Map<String, dynamic> colorToMap(Color color) => {
  '_type': 'Color',
  'a': color.a,
  'r': color.r,
  'g': color.g,
  'b': color.b,
};

Color mapToColor(Map<String, dynamic> map) {
  try {
    return Color.from(
      alpha: (map['a'] as num).toDouble(),
      red: (map['r'] as num).toDouble(),
      green: (map['g'] as num).toDouble(),
      blue: (map['b'] as num).toDouble(),
    );
  } catch (e) {
    if (kDebugMode) {
      print("Error converting map to color: $e, map: $map");
    }
    return Colors.transparent; // Fallback color
  }
}
