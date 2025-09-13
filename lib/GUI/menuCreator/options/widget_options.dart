import 'package:flutter/material.dart';

import '../components/propertyEditor/button_action.dart';

class WidgetOptions {
  final Type widgetType; // The type of the widget these options are for

  final List<WidgetOption> options;

  WidgetOptions(this.widgetType, {required this.options});

  WidgetOptions.from(WidgetOptions other, this.widgetType)
    : options = List<WidgetOption>.from(other.options);

  WidgetOption? getOptionByName(String name) {
    return options
        .where((option) => option.name == name)
        .cast<WidgetOption?>()
        .firstOrNull; // Using firstOrNull to avoid exceptions if nothing is found
  }

  bool hasOption(String name) {
    return options.any((option) => option.name == name);
  }

  dynamic getDefaultValue(String name) {
    final option = getOptionByName(name);
    return option?.defaultValue;
  }

  dynamic getValue(String name, dynamic value) {
    final option = getOptionByName(name);
    if (option != null) {
      return option.parser(value);
    }
    throw ArgumentError('No option found with name: $name');
  }

  /// Cache to store widget options by type to avoid redundant lookups
  static final Map<Type, WidgetOptions> _widgetOptionsCache = {};

  /// Register widget options for a specific widget type
  factory WidgetOptions.fromType(Type widgetType) {
    if (_widgetOptionsCache.containsKey(widgetType)) {
      return _widgetOptionsCache[widgetType]!;
    }

    throw ArgumentError(
      'No widget options defined for type: $widgetType. Please define them before using.',
    );
  }

  static bool isRegistered(Type widgetType) {
    return _widgetOptionsCache.containsKey(widgetType);
  }

  void register() {
    if (_widgetOptionsCache.containsKey(widgetType)) {
      throw ArgumentError(
        'Widget options for type $widgetType are already registered.',
      );
    }
    _widgetOptionsCache[widgetType] = this;
  }
}

class WidgetOption<T> {
  final String name;
  final String? description;

  final dynamic defaultValue;

  final Type type = T;

  final T? Function(dynamic type)
  parser; // Optional parser function to convert string input to the desired type

  final Map<String, dynamic>?
  options; // For dropdowns or multiple choice options but only if there are a limited set of options

  WidgetOption(
    this.parser, {
    required this.name,
    this.description,
    required this.defaultValue,
    this.options,
  });
}

double? parseDouble(dynamic value) {
  if (value is double) {
    return value;
  } else if (value is String) {
    return double.tryParse(value) ?? 0.0; // Default to 0.0 if parsing fails
  }
  return null; // Default to 0.0 for any other type
}

bool? parseBoolean(dynamic value) {
  if (value is bool) {
    return value;
  } else if (value is String) {
    return bool.tryParse(value) ?? false; // Default to 0.0 if parsing fails
  }
  return null; // Default to 0.0 for any other type
}

Color? parseColor(dynamic value) {
  if (value is Color) return value;

  if (value is Map<String, dynamic>) {
    double r = parseDouble(value['r']) ?? 0;
    double g = parseDouble(value['g']) ?? 0;
    double b = parseDouble(value['b']) ?? 0;
    double a =
        parseDouble(value['a']) ?? 1.0; // Default alpha to 1.0 if not provided

    return Color.fromRGBO(
      (r * 255).toInt(),
      (g * 255).toInt(),
      (b * 255).toInt(),
      a,
    );
  }
  return null; // Return null if the value cannot be parsed
}

EdgeInsetsGeometry? parseEdgeInsets(dynamic value) {
  if (value is Map<String, dynamic>) {
    double left = parseDouble(value['left']) ?? 0.0;
    double top = parseDouble(value['top']) ?? 0.0;
    double right = parseDouble(value['right']) ?? 0.0;
    double bottom = parseDouble(value['bottom']) ?? 0.0;

    return EdgeInsets.fromLTRB(left, top, right, bottom);
  }
  return null; // Return null if the value cannot be parsed
}

Alignment parseAlignment(dynamic value) {
  if (value is String) {
    value = value.replaceAll(
      "Alignment.",
      "",
    ); //remove the enum prefix if present
    switch (value.toLowerCase()) {
      case 'topleft':
        return Alignment.topLeft;
      case 'topcenter':
        return Alignment.topCenter;
      case 'topright':
        return Alignment.topRight;
      case 'centerleft':
        return Alignment.centerLeft;
      case 'center':
        return Alignment.center;
      case 'centerright':
        return Alignment.centerRight;
      case 'bottomleft':
        return Alignment.bottomLeft;
      case 'bottomcenter':
        return Alignment.bottomCenter;
      case 'bottomright':
        return Alignment.bottomRight;
      default:
        return Alignment.center; // Default to center if no match
    }
  }
  return Alignment.center; // Default to center for any other type
}

PanAxis parsePanAxis(dynamic value) {
  if (value is String) {
    value = value.replaceAll(
      "PanAxis.",
      "",
    ); //remove the enum prefix if present
    switch (value.toLowerCase()) {
      case 'vertical':
        return PanAxis.vertical;
      case 'horizontal':
        return PanAxis.horizontal;
      case 'aligned':
        return PanAxis.aligned;
      case 'free':
        return PanAxis.free;
    }
  }
  return PanAxis.free;
}

MainAxisAlignment parseMainAxisAlignment(dynamic value) {
  if (value is String) {
    value = value.replaceAll(
      "MainAxisAlignment.",
      "",
    ); //remove the enum prefix if present
    switch (value.toLowerCase()) {
      case 'start':
        return MainAxisAlignment.start;
      case 'end':
        return MainAxisAlignment.end;
      case 'center':
        return MainAxisAlignment.center;
      case 'spacebetween':
        return MainAxisAlignment.spaceBetween;
      case 'spacearound':
        return MainAxisAlignment.spaceAround;
      case 'spaceevenly':
        return MainAxisAlignment.spaceEvenly;
      default:
        return MainAxisAlignment.start;
    }
  }
  return MainAxisAlignment.start; // Default to start for any other type
}

CrossAxisAlignment parseCrossAxisAlignment(dynamic value) {
  if (value is String) {
    value = value.replaceAll(
      "CrossAxisAlignment.",
      "",
    ); //remove the enum prefix if present
    switch (value.toLowerCase()) {
      case 'start':
        return CrossAxisAlignment.start;
      case 'end':
        return CrossAxisAlignment.end;
      case 'center':
        return CrossAxisAlignment.center;
      case 'stretch':
        return CrossAxisAlignment.stretch;
      case 'baseline':
        return CrossAxisAlignment.baseline;
      default:
        return CrossAxisAlignment.start; // Default to start for any other type
    }
  }
  return CrossAxisAlignment.start; // Default to start for any other type
}

Axis parseAxis(dynamic value) {
  if (value is String) {
    value = value.replaceAll("Axis.", ""); //remove the enum prefix if present
    switch (value.toLowerCase()) {
      case 'horizontal':
        return Axis.horizontal;
      case 'vertical':
        return Axis.vertical;
    }
  }
  return Axis.vertical;
}

MainAxisSize parseMainAxisSize(dynamic value) {
  if (value is String) {
    value = value.replaceAll(
      "MainAxisSize.",
      "",
    ); //remove the enum prefix if present
    switch (value.toLowerCase()) {
      case 'min':
        return MainAxisSize.min;
      case 'max':
        return MainAxisSize.max;
      default:
        return MainAxisSize.max; // Default to max for any other type
    }
  }
  return MainAxisSize.max; // Default to max for any other type
}

TextAlign parseTextAlign(dynamic value) {
  if (value is String) {
    value = value.replaceAll(
      "TextAlign.",
      "",
    ); //remove the enum prefix if present
    switch (value.toLowerCase()) {
      case 'left':
        return TextAlign.left;
      case 'right':
        return TextAlign.right;
      case 'center':
        return TextAlign.center;
      case 'justify':
        return TextAlign.justify;
      case 'start':
        return TextAlign.start;
      case 'end':
        return TextAlign.end;
      default:
        return TextAlign.start; // Default to start for any other type
    }
  }
  return TextAlign.start; // Default to start for any other type
}

TextStyle parseTextStyle(dynamic value) {
  if (value is Map<String, dynamic>) {
    return TextStyle(
      color: parseColor(value['color']) ?? Colors.black,
      backgroundColor: parseColor(value['backgroundColor']),
      fontSize: parseDouble(value['fontSize']) ?? 14.0,
      fontWeight: FontWeight.values.firstWhere(
        (e) => e.toString().split('.').last == value['fontWeight'],
        orElse: () => FontWeight.normal,
      ),
      fontFamily: value['fontFamily'] as String? ?? 'gameFont',
      letterSpacing: parseDouble(value['letterSpacing']),
      wordSpacing: parseDouble(value['wordSpacing']),
    );
  }
  return const TextStyle(); // Return an empty TextStyle if the value cant be parsed
}

int? parseInt(dynamic value) {
  if (value is int) {
    return value;
  } else if (value is String) {
    return int.tryParse(value) ?? 0; // Default to 0 if parsing fails
  }
  return null; // Default to 0 for any other type
}

ButtonAction? parseButtonAction(dynamic value) {
  if (value is Map<String, dynamic>) {
    return ButtonAction.fromJson(value);
  }
  return null;
}

BoxFit parseBoxFit(dynamic value) {
  if (value is String) {
    value = value.replaceAll("BoxFit.", ""); //remove the enum prefix if present
    switch (value.toLowerCase()) {
      case 'fill':
        return BoxFit.fill;
      case 'contain':
        return BoxFit.contain;
      case 'cover':
        return BoxFit.cover;
      case 'fitwidth':
        return BoxFit.fitWidth;
      case 'fitheight':
        return BoxFit.fitHeight;
      case 'none':
        return BoxFit.none;
      case 'scale-down':
        return BoxFit.scaleDown;
      default:
        return BoxFit.contain; // Default to contain for any other type
    }
  }
  return BoxFit.contain; // Default to contain for any other type
}
