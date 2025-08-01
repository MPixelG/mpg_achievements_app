import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mpg_achievements_app/components/GUI/menuCreator/editor_node_dependency_viewer.dart';
import 'package:mpg_achievements_app/components/GUI/menuCreator/layout_widget.dart';

class OptionEditorMenu extends StatefulWidget {
  const OptionEditorMenu({super.key, required this.node});

  final LayoutWidget node;

  @override
  State<StatefulWidget> createState() => _OptionEditorMenuState();



}

class _OptionEditorMenuState extends State<OptionEditorMenu> {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: EdgeInsets.all(50),
      backgroundColor: Colors.white,
      child: SizedBox(
        width: 800,
        height: 600,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            centerTitle: true,
            title: Text("Properties Editor for ${widget.node.id}"), //the title of the app bar is the id of the node
          ),

          body: Container(
            decoration: BoxDecoration(
              color: CupertinoColors.extraLightBackgroundGray,
              borderRadius: BorderRadius.circular(12),
            ),
            padding: EdgeInsets.all(24),
          ),
        ),
      ),
    );
  }
}