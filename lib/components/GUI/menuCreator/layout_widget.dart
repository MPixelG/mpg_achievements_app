import 'package:flutter/cupertino.dart';
class LayoutWidget {
  final String id;
  final Widget Function(BuildContext context, List<Widget> children, Map<String, dynamic> properties) _builder;
  late final List<LayoutWidget> children;
  late Map<String, dynamic> properties;
  late void Function(LayoutWidget child) removeFromParent; // Function to remove this widget from its parent, if needed

  ContainerType type; //the amount of children this container can have, unlimited, sealed (no children can be added), single (only one child can be added)

  LayoutWidget(this._builder, {
      required this.id,
      List<LayoutWidget>? children,
      Map<String, dynamic>? properties,
      this.type = ContainerType.unlimited,
      required void Function(LayoutWidget child)? removeFromParent }){
    this.children = children ?? [];
    this.properties = properties ?? {};
    this.removeFromParent = removeFromParent ?? (child) {};
  }

  void addChild(LayoutWidget child) {
    children.add(child);
  }

  void removeChild(LayoutWidget child) {
    children.remove(child);
  }

  /// Checks if a child can be added to this widget based on its type.
  bool get canAddChild {
    if(type == ContainerType.sealed) {
      return false; // Cannot add children to a sealed container
    }
    else if(type == ContainerType.single && children.isEmpty) {
      return true; // Can add a single child if there are no children yet
    }
    else if(type == ContainerType.unlimited) {
      return true;// Unlimited containers can always accept children
    }

    return false; // Default case, should not happen
  }

  Widget build(BuildContext context) {
    return _builder(context, children.map((c) => c.build(context)).toList(), properties);
  }
}

/// The type of container this widget is.
/// - `unlimited`: Can have any number of children.
/// - `sealed`: Cannot have any children added.
/// - `single`: Can only have one child.
enum ContainerType {
  unlimited, sealed, single
}