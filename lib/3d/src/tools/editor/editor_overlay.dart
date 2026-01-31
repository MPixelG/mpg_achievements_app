import 'package:flame/extensions.dart';
import 'package:flutter/material.dart';
import 'package:mpg_achievements_app/3d/src/tools/editor/widgets/window_system/logic_nodes.dart';
import 'package:mpg_achievements_app/3d/src/tools/editor/widgets/window_system/window_system.dart';
import 'package:mpg_achievements_app/3d/src/tools/editor/widgets/window_system/window_type_registry.dart';

///Editor overlay with Window System
class Editor3DOverlay extends StatelessWidget {
  final String id;

  const Editor3DOverlay({required this.id, super.key});

  @override
  Widget build(BuildContext context) => getEditorController(id).windowManager; //uses the window manager of the controller as the widget to show. this way we dont cache widgets directly and dont use states either
}

//the EditorController class. Acts basically as a state for the Editor Overlay. we cant use a state because otherwise the state would get deleted when we hide the Overlay
class EditorController {
  final WindowManager windowManager = WindowManager(
    controller: WindowManagerController(
      WindowSplit(
        direction: Axis.horizontal,
        children: [
          WindowLeaf(
            config: WindowConfig.create(
              //here we can create different window types.
              title: "colored container",
              child: Container(color: Colors.primaries.random()),
            ),
          ),
          WindowLeaf(
            config: WindowConfig.create(
              title: "button",
              child: ElevatedButton(onPressed: () {}, child: null),
            ),
          ),
        ],
      ),
    ),
  );
}

final Map<String, EditorController> _controllers = {};

///returns an editor controller for a given id. if there isn't one yet, it gets created
EditorController getEditorController(String id) => _controllers[id] ??= EditorController();
