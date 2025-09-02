import 'package:flutter/cupertino.dart';

class LayoutWidget {
  final String id;
  final Widget Function(
    BuildContext context,
    List<Widget> children,
    Map<String, dynamic> properties,
  ) _builder;

  late final List<LayoutWidget> children;
  late Map<String, dynamic> properties;
  late void Function(LayoutWidget child) removeFromParent; // Function to remove this widget from its parent, if needed
  LayoutWidget? parent; // Reference to the parent widget, if any

  late bool Function(LayoutWidget other)? dropCondition; // Function to drop a prerequisite widget, if needed

  Type widgetType; // The type of the widget this LayoutWidget represents

  ContainerType type; //the amount of children this container can have, unlimited, sealed (no children can be added), single (only one child can be added)

  LayoutWidget(
    this._builder, {
    required this.id,
    List<LayoutWidget>? children,
    Map<String, dynamic>? properties,
    required this.type,
    required void Function(LayoutWidget child)? removeFromParent,
        required this.parent,
        required this.widgetType,
        this.dropCondition
  }) {
    this.children = children ?? [];
    this.properties = properties ?? {};
    this.removeFromParent = removeFromParent ?? (child) {};
  }

  void addChild(LayoutWidget child) {
    children.add(child);
    child.parent = this;
    child.removeFromParent = removeChild;
  }

  void addChildren(List<LayoutWidget> newChildren) {
    for (var child in newChildren) {
      addChild(child);
    }
  }

  void moveTo(LayoutWidget newParent) {
    // Remove from current parent if it exists
    removeFromParent(this);

    // Add to new parent's children
    newParent.addChild(this);

    // Update the removeFromParent function to point to the new parent
    removeFromParent = newParent.removeChild;
  }

  void swapWith(LayoutWidget other) {
    if (parent != other.parent) {
      return; // Cannot swap widgets that arent siblings (i.e., do not share the same parent)
    }

    final index1 = children.indexOf(this);
    final index2 = other.parent?.children.indexOf(other) ?? -1;

    if (index1 == -1 || index2 == -1) {
      throw Exception("One of the widgets is not a child of the parent");
    }

    children.swap(index1, index2);
  }

  void moveUp() {
    if (parent == null) return; // Cannot move up if there is no parent

    final index = parent!.children.indexOf(this);
    if (index > 0) {
      parent!.children.swap(index, index - 1);
    }
  }

  void moveDown() {
    if (parent == null) return; // Cannot move down if there is no parent

    final index = parent!.children.indexOf(this);
    if (index < parent!.children.length - 1) {
      parent!.children.swap(index, index + 1);
    }
  }

  void removeChild(LayoutWidget child) {
    children.removeWhere((element) => element.id == child.id);
  }

  /// Checks if a child can be added to this widget based on its type.
  bool get canAddChild {
    if (type == ContainerType.sealed) {
      return false; // Cannot add children to a sealed container
    } else if (type == ContainerType.single && children.isEmpty) {
      return true; // Can add a single child if there are no children yet
    } else if (type == ContainerType.unlimited) {
      return true; // Unlimited containers can always accept children
    }

    return false; // Default case, should not happen
  }

  bool canDropOn(LayoutWidget other){

    if(dropCondition != null && !dropCondition!(other)) return false; // Cannot drop a Positioned widget on a Widget that is not a Stack


    //if(isDescendant(this, other)) return false; // Cannot drop a widget on itself or its descendants

    return true;
  }

  Widget build(BuildContext context) {
    return _builder(
      context,
      children.map((c) => c.build(context)).toList(),
      properties,
    );
  }
}


bool isDescendant(LayoutWidget dragged, LayoutWidget target) { //check if the dragged widget is a descendant of the target widget
  for (var child in dragged.children) { //for every child of the dragged widget
    if (child == target || isDescendant(child, target)) return true; //if the child is the target or if the child has the target as a descendant, return true. this checks the entire tree of children recursively
  }
  return false; //if no child is the target or has the target as a descendant, return false
}

/// The type of container this widget is.
/// - `unlimited`: Can have any number of children.
/// - `sealed`: Cannot have any children added.
/// - `single`: Can only have one child.
enum ContainerType { unlimited, sealed, single }


extension on List{
  void swap(int index1, int index2) {
    if (index1 < 0 || index2 < 0 || index1 >= length || index2 >= length) {
      throw RangeError('Index out of range');
    }
    final temp = this[index1];
    this[index1] = this[index2];
    this[index2] = temp;
  }
}