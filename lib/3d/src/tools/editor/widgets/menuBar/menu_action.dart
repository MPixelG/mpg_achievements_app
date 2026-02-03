import 'package:flutter/cupertino.dart';

class MenuAction {
  final String path;
  final String displayName;
  final IconData? icon;
  final void Function() action;

  const MenuAction({required this.path, required this.displayName, this.icon, required this.action});
  
  @override
  String toString() => "[Menu Action '$displayName' (path: $path)]";
}
class MenuActionNode {
  late final String name;
  late final String path;
  late final IconData? icon;
  late final List<MenuActionNode> children;
  late final void Function() action;
  bool dirty = false;

  MenuActionNode({required this.name, this.icon, required this.children, required this.action, required this.path});

  MenuActionNode.fromPath(this.path, Iterable<MenuAction> actions) {
    final Iterable<MenuAction> open = actions.where((element) => element.path.startsWith(path));
    final Iterable<MenuAction> openWithoutSelf = open.where((element) => element.path != path);

    final MenuAction? action = open.firstWhere(
            (element) => element.path == path,
        orElse: () => throw Exception("menu action path is invalid! no action is registered under the path '$path'")
    );

    name = action!.displayName;
    icon = action.icon;
    this.action = action.action;

    final List<MenuActionNode> childrenClosed = [];

    for (MenuAction value in openWithoutSelf) {
      final String childPath = value.path; // Use full path instead of substring

      // Ensure the childPath starts with the current path and is valid
      if (childPath.startsWith("$path/")) {
        childrenClosed.add(MenuActionNode.fromPath(childPath, actions));
      }
    }

    children = childrenClosed;
  }


  @override
  String toString() => "[Menu Action '$name' (children: $children)]";
}

