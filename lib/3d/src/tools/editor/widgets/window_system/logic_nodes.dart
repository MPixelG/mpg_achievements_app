import 'package:flutter/cupertino.dart';
import 'package:mpg_achievements_app/3d/src/tools/editor/widgets/window_system/window_type_registry.dart';

abstract class WindowNode {
  String toJson();
}

///a leaf node of the window system logic. contains the config of the child widget that will get shown via the [WindowPane] class
class WindowLeaf extends WindowNode {
  late final WindowConfig config;

  WindowLeaf({required this.config});

  @override
  String toJson() =>
      """
    {
      "windowType": "windowLeaf",
      "config": ${config.toJson()}
    }
  """;
}

class WindowSplit extends WindowNode {
  final Axis direction;
  final List<WindowNode> children;
  late List<double>? proportions;

  WindowSplit({required this.direction, required this.children, this.proportions}) {
    proportions ??= List.filled(children.length, 1.0 / children.length);
  }

  factory WindowSplit.equal({required Axis direction, required List<WindowNode> children}) {
    final equalProportion = 1.0 / children.length;
    return WindowSplit(direction: direction, children: children, proportions: List.filled(children.length, equalProportion));
  }

  WindowSplit copyWith({Axis? direction, List<WindowNode>? children, List<double>? proportions}) =>
      WindowSplit(direction: direction ?? this.direction, children: children ?? this.children, proportions: proportions ?? this.proportions);

  @override
  String toJson() =>
      """"
    {
      "windowType": "windowSplit"
      "direction": ${direction.name},
      "proportions": $proportions,
      "children": [
        ${children.join(",\n")}
      ]
    }
  """;
}

WindowNode loadNodeFromJson(Map<String, dynamic> json) {  
  final String? type = json["windowType"];
  assert(type != null, "invalid json format!");
  if (type == "windowLeaf") {
    return WindowLeaf(config: WindowConfig.fromType(json["config"]["id"]));
  } else if (type == "windowSplit") {
    return WindowSplit(
      direction: getAxisOfString(json["direction"]),
      children: (json["children"] as List<Map<String, dynamic>>).map((e) => loadNodeFromJson(e)).toList(),
      proportions: json["proportions"],
    );
  } else {
    throw FormatException("invalid window type '$type'!");
  }
}

Axis getAxisOfString(String name) => switch (name) {
  "horizontal" => Axis.horizontal,
  "vertical" => Axis.vertical,
  String() => throw UnimplementedError(),
};


