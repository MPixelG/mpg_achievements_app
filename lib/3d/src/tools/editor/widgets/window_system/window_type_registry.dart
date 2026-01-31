import 'package:flutter/cupertino.dart';

//Registry for registering different window types.
class WindowTypeRegistry {
  static final Map<String, WindowTypeDefinition> _types = {}; //the different stored window types.

  ///registers a new window type
  static void register(String id, WindowTypeDefinition definition) {
    _types[id] = definition;
  }

  static WindowTypeDefinition? get(String id) => _types[id];

  static List<String> getAllIds() => _types.keys.toList();

  static List<WindowTypeDefinition> getAll() => _types.values.toList();
}

///a template of a window type. only one per window type
class WindowTypeDefinition {
  final String id;
  final String title;
  final IconData? icon;
  final Color? headerColor;
  final Widget Function() builder;

  const WindowTypeDefinition({required this.id, required this.title, required this.builder, this.icon, this.headerColor});
}

///a specific instance of a Window type.
class WindowConfig {
  final String title;
  final Widget child;
  final Color? headerColor;
  final IconData? icon;
  final String? typeId;

  const WindowConfig._new({required this.title, required this.child, this.headerColor, this.icon, this.typeId});

  WindowConfig copyWith({String? title, Widget? child, Color? headerColor, IconData? icon, String? typeId}) => WindowConfig._new(
    title: title ?? this.title,
    child: child ?? this.child,
    headerColor: headerColor ?? this.headerColor,
    icon: icon ?? this.icon,
    typeId: typeId ?? this.typeId,
  );

  factory WindowConfig.fromType(String typeId) {
    final type = WindowTypeRegistry.get(typeId);
    if (type == null) {
      throw Exception('Window type $typeId not registered');
    }
    return WindowConfig._new(title: type.title, child: type.builder(), headerColor: type.headerColor, icon: type.icon, typeId: typeId);
  }

  factory WindowConfig.create({required String title, required Widget child, Color? headerColor, IconData? icon, String? typeId}) {
    WindowTypeRegistry.register(
      typeId ?? title,
      WindowTypeDefinition(id: typeId ?? title, title: title, builder: () => child, headerColor: headerColor, icon: icon),
    );

    return WindowConfig.fromType(typeId ?? title);
  }

  @override
  String toString() => "[Config for $title (id: $typeId) with child widget: ${child.runtimeType}";
}
