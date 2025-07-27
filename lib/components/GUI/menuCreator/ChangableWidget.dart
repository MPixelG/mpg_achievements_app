/*import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'menu_creator.dart';

class ChangeableWidget extends StatefulWidget {
  final GuiNode node;
  final VoidCallback? onDelete;

  const ChangeableWidget({super.key, required this.node, this.onDelete});

  @override
  State<ChangeableWidget> createState() => _ChangeableWidgetState();
}


class _ChangeableWidgetState extends State<ChangeableWidget> {
  late double exactX = 0.5;
  late double exactY = 0.5;
  late double x;
  late double y;
  double width = 0.2;
  double height = 0.4;
  double exactWidth = 0.2;
  double exactHeight = 0.4;

  double get screenWidth => MediaQuery.of(context).size.width;
  double get screenHeight => MediaQuery.of(context).size.height;


  @override
  void initState() {
    super.initState();
    x = widget.initialX;
    y = widget.initialY;
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: x * screenWidth,
      top: y * screenHeight,
      child: GestureDetector(
        onPanUpdate: (details) {
          move(details);
        },
        onSecondaryTapDown: (details) => _showContextMenu(context, details.globalPosition, widget.onDelete),
        child: Stack(
          children: [
            SizedBox(
              width: width * screenWidth, //set the right size
              height: height * screenHeight,
              child:

              Stack(
                children: [
                  widget.builder(),
                  ...getChildren()

                ])
            ), //render the actual widget

            Positioned(
              right: 0, //on the bottom left edge
              bottom: 0,
              child: GestureDetector( //gesture detector for resizing
                onPanUpdate: (details) {
                  resize(details); //resize when dragged on the bottom edge
                },
                child: Icon(Icons.open_in_full, size: 16), //render the resize icon
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> getChildren(){
    List<Widget> out = [];

    for (var value in connections.entries) {
      if(value.value == widget.key){
        out.add(widgets[value.key]!);
      }
    }

    print("children: " + out.toString());

    return out;
  }


  void resize(DragUpdateDetails details){
    setState(() {

      double newWidth = exactWidth + (details.delta.dx / screenWidth);
      double newHeight = exactHeight + (details.delta.dy / screenHeight);

      exactWidth = newWidth;
      exactHeight = newHeight;

      final isAltPressed = HardwareKeyboard.instance.isAltPressed;
      if (isAltPressed) {
        const gridSize = 32.0;
        newWidth = (exactWidth / (gridSize / screenWidth)).round() * gridSize / screenWidth;
        newHeight = (exactHeight / (gridSize / screenHeight)).round() * gridSize / screenHeight;
      }

      if(newWidth > 10 / screenWidth) {
        width = newWidth;
      }
      if(newHeight > 10 / screenHeight) {
        height = newHeight;
      }
    });
  }

  void move(DragUpdateDetails details){
    setState(() {
      double newX = exactX + (details.delta.dx / screenWidth);
      double newY = exactY + (details.delta.dy / screenHeight);

      final isAltPressed = HardwareKeyboard.instance.isAltPressed;

      exactX = newX;
      exactY = newY;

      if (isAltPressed) {
        const gridSize = 32.0;
        newX = (exactX / (gridSize / screenWidth)).round() * (gridSize / screenWidth);
        newY = (exactY / (gridSize / screenHeight)).round() * (gridSize / screenHeight);
      }

      x = newX;
      y = newY;
    });
  }

}




void _showContextMenu(BuildContext context, Offset position, VoidCallback? onDelete) async {
  final selected = await showMenu<String>(
    context: context,
    position: RelativeRect.fromLTRB(
      position.dx,
      position.dy,
      position.dx,
      position.dy,
    ),
    items: [
      PopupMenuItem(
        value: 'delete',
        child: Text('Delete'),
      ),
      PopupMenuItem(
        value: 'edit',
        child: Text('Edit'),
      ),
      PopupMenuItem(
        value: 'add_to',
        child: Text('Add To Other Widget'),
      ),
    ],
  );

  if (selected != null && onDelete != null) {
    if (selected == 'delete') {
      onDelete();
    } else if (selected == 'edit') {
    }else if(selected == 'add_to'){
    }
  }
}*/


class GuiNode {
  String type;
  Map<String, dynamic> properties;
  String id;

  GuiNode(this.type, this.properties, this.id);
}


