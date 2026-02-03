import 'package:flutter/material.dart';
import 'package:mpg_achievements_app/3d/src/tools/editor/widgets/menuBar/menu_action.dart';

import 'dropdown_menu_button.dart';

class MenuActionRegistry {
  static Set<MenuAction> actions = {};

  static void register(MenuAction action) {
    actions.add(action);
  }

  static MenuAction? getAction(String name) => actions.where((element) => element.displayName == name).firstOrNull;

  static MenuAction? getActionAt(String path) => actions.where((element) => element.path == path).firstOrNull;
  static String? getActionPath(String name) => actions.where((element) => element.displayName == name).firstOrNull?.path;
  static IconData? getActionIcon(String name) => actions.where((element) => element.displayName == name).firstOrNull?.icon;
  
  static Iterable<MenuActionNode>? rootNodes;
  static List<Widget> getAllAsMenuBarItems() {
    rootNodes ??= getRootNodes();
    return [
      for (MenuActionNode value in rootNodes!)
        DropdownMenuButton(
          label: value.name,
          dropdownWidgets: _getAllAsMenuBarItemsRecursively(value, 0),
          icon: value.icon,
          onTap: value.action,
        ),
    ];
  }

  static List<Widget> _getAllAsMenuBarItemsRecursively(MenuActionNode rootNode, int depth) => [
    for (MenuActionNode value in rootNode.children)
      DropdownMenuButton(
        label: value.name,
        dropdownWidgets: _getAllAsMenuBarItemsRecursively(value, depth + 1),
        isNested: depth > 1,
        icon: value.icon,
        onTap: value.action,
      ),
  ];

  static Iterable<MenuActionNode> getRootNodes() => MenuActionRegistry.getActionsAt("").map((e) => MenuActionNode.fromPath(e.path, actions));

  static Iterable<MenuAction> getActionsAt(String path) => actions.where((element) => element.path.lastIndexOf("/") == path.lastIndexOf("/"));
  
  static void updateNodes(){
    
  }
  static MenuActionNode updateNodesRecursively(MenuActionNode current){
    if(current.dirty) {
      current = MenuActionNode.fromPath(current.path, actions);
    }
    current.children.setAll(0, current.children.map((e) => updateNodesRecursively(e)));
    return current;
  }
}


void registerMenuActions() {


  MenuActionRegistry.register(MenuAction(path: "file", displayName: "File", action: () {}));
  MenuActionRegistry.register(MenuAction(path: "file/save", displayName: "Save", action: () {}));
  MenuActionRegistry.register(MenuAction(path: "file/save_as", displayName: "Save As", action: () {}));
  MenuActionRegistry.register(MenuAction(path: "file/save_as/json", displayName: "JSON", action: () {}));
  MenuActionRegistry.register(MenuAction(path: "file/save_as/png", displayName: "PNG", action: () {}));
  MenuActionRegistry.register(MenuAction(path: "file/save_as/bf", displayName: "BF", action: () {}));
  MenuActionRegistry.register(MenuAction(path: "file/open", displayName: "Open", action: () {}));
  MenuActionRegistry.register(MenuAction(path: "view", displayName: "View", action: () {}));
  MenuActionRegistry.register(MenuAction(path: "view/fullscreen", displayName: "Fullscreen", action: () {}));

}