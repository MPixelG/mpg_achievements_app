/*
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../widgets/nine_patch_button.dart';
import 'ChangableWidget.dart';

class MenuCreator extends StatefulWidget {
  const MenuCreator({super.key});

  @override
  _MenuCreatorState createState() => _MenuCreatorState();
}

class _MenuCreatorState extends State<MenuCreator> {

  Map<Key, ChangeableWidget> children = {};
  Map<Key, Key> connections = {};

  void addNewWidget() {
    setState(() {
      ChangeableWidget button = _buildNinePatchButton();
      children[button.key!] = button;

      ChangeableWidget button2 = _buildNinePatchButton();
      children[button2.key!] = button2;

      connections[button2.key!] = button.key!;
    });
  }

  ChangeableWidget _buildNinePatchButton(){
    final key = GlobalKey();
    ChangeableWidget widget = ChangeableWidget(
      initialX: 0.5,
      initialY: 0.5,
      key: key,
      builder: () => Container(width: 60, height: 60, color: Colors.red.withValues(alpha: 0.5)),
      onDelete: () {
          setState(() {
            children.remove(key);
          });
        }, widgets: children, connections: connections,
    );

    return widget;
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          if(children.values.isNotEmpty) children.values.first,
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: addNewWidget,
        child: Icon(Icons.add),
      ),
    );
  }
}

class GuiNode {
  final Key key;
  final Widget Function() builder;
  final List<GuiNode> children;
  final Offset position;
  final Size size;

  GuiNode({
    required this.key,
    required this.builder,
    this.children = const [],
    this.position = const Offset(0.5, 0.5),
    this.size = const Size(0.2, 0.4),
  });

  GuiNode copyWith({
    List<GuiNode>? children,
    Offset? position,
    Size? size,
  }) {
    return GuiNode(
      key: key,
      builder: builder,
      children: children ?? this.children,
      position: position ?? this.position,
      size: size ?? this.size,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': builder().runtimeType.toString(),
      'position': {'x': position.dx, 'y': position.dy},
      'size': {'width': size.width, 'height': size.height},
      'children': children.map((c) => c.toJson()).toList(),
    };
  }
}
*/
