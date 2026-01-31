import 'package:flame/extensions.dart';
import 'package:flutter/material.dart';
import 'package:mpg_achievements_app/3d/src/tools/editor/widgets/window_system/window_container.dart';
import 'package:mpg_achievements_app/3d/src/tools/editor/widgets/window_system/window_system.dart';
import 'package:mpg_achievements_app/3d/src/tools/editor/widgets/window_system/window_type_registry.dart';

class Editor3DOverlay extends StatelessWidget {
  final String id;

  const Editor3DOverlay({required this.id, super.key});

  @override
  Widget build(BuildContext context) => getEditorController(id).windowManager;
}

final Map<String, EditorController> _controllers = {};

EditorController getEditorController(String id) => _controllers[id] ??= EditorController();

class EditorController {
  final WindowManager windowManager = WindowManager(
    controller: WindowManagerController(
      WindowSplit(
        direction: Axis.horizontal,
        children: [
          WindowLeaf(
            config: WindowConfig.create(
              title: "test1",
              child: Container(color: Colors.primaries.random()),
            ),
          ),
          WindowLeaf(
            config: WindowConfig.create(
              title: "test2",
              child: Container(color: Colors.primaries.random()),
            ),
          ),
        ],
      ),
    ),
  );
}
