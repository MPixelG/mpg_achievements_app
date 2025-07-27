import 'package:flutter/material.dart';
import 'package:mpg_achievements_app/components/GUI/menuCreator/editable_widget.dart';

class GuiEditor extends StatefulWidget {
  const GuiEditor({super.key});

  @override
  State<StatefulWidget> createState() => _GuiEditorState();
}

class _GuiEditorState extends State<GuiEditor> {
  late EditorNode rootNode;

  @override
  void initState() {
    super.initState();

    rootNode = EditorNode(
            () => Container(
          width: 120,
          height: 80,
          color: Colors.blue.withValues(alpha: .3),
          child: Center(
              child: Text('Root', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
          ),
        ),
        properties: {'position': Offset(0.4, 0.3)}
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: EditableWidget(
          rootNode,
          isRoot: true,
        ),
      ),
    );
  }
}