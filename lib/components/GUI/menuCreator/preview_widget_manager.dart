import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'Preview_widget.dart';

class PreviewWidgetManager extends StatefulWidget{

  const PreviewWidgetManager({super.key});

  @override
  State<PreviewWidgetManager> createState() => _PreviewWidgetManagerState();


}

class _PreviewWidgetManagerState extends State<PreviewWidgetManager>{

  late PreviewNode root;

  @override
  void initState() {
    super.initState();
    root = PreviewNode(children: []);
  }

  void addChild() {
    setState(() {
      root.children.add(PreviewNode());
    });
  }

  void removeChild(PreviewNode child) {
    setState(() {
      root.children.remove(child);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Center(
            child: PreviewWidget(
              node: root,
              onRemoveChild: removeChild
            ),
          ),
        ),
        ElevatedButton(
          onPressed: addChild,
          child: Text("Child hinzufügen"),
        )
      ],
    );
  }



}