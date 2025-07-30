import 'dart:math';

import 'package:flame/extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class EditableWidget extends StatefulWidget {
  final EditorNode node; // the node of this widget. see at EditorNode at the bottom for more info.
  final bool isRoot; //if its the root node.

  const EditableWidget(this.node, {required super.key, this.isRoot = false}); //constructor

  @override
  State<StatefulWidget> createState() => _EditableWidgetState(); //the state of the widget
}

class _EditableWidgetState extends State<EditableWidget> { //a class for the state of the editable widget
  double get screenWidth => MediaQuery.of(context).size.width; //a shortcut to get the current screen width
  double get screenHeight => MediaQuery.of(context).size.height; //and height

  @override
  Widget build(BuildContext context) { //the state of the widget. thats the stuff that gets rendered later
    if (widget.isRoot) { //if its the root node, we need to collect all the children recursively for adding gesture detection to them later. doing that recursively doesnt rly work.
      List<EditorNode> allNodes = []; //a list of all the children nodes
      _collectAllNodesRecursive(widget.node, allNodes); //gets all of the child nodes of the given node. since this is the root node, this will get us every one of them.

      return Stack( //a stack lets you render multiple widgets over each other.
        clipBehavior: Clip.none, //so that no child widget gets cut off outside of the bounds of the root node
        children: [
          for (EditorNode node in allNodes) //recursively gets all of the nodes from the root node
            _buildNodeWidget(node),
        ],
      );
    } else {
      return Container(); //since we already did all of the work for the children in the root node, we can skip the build part for the children.
    }
  }

  void _collectAllNodesRecursive(EditorNode node, List<EditorNode> allNodes) { //recursively collects all of the child nodes into a given list.
    allNodes.add(node); //puts the current node into the list
    for (EditorNode child in node.childrenNodes) { //repeats that process for every child.
      _collectAllNodesRecursive(child, allNodes);
    }
  }

  Offset _getAbsolutePosition(EditorNode node) { //returns the absolute position of a given node. this differences because the position of a child node is the position of the parent + the position of the child.
    Offset absolutePos = Offset.zero; //initialize with zero
    EditorNode? currentNode = node; //set the node to the given one

    while (currentNode != null) { //repeat until its null so we arrived at the root node. (the first node where every other node comes out of)
      final nodePos = currentNode.properties['position'] as Offset? ?? Offset(0.1, 0.1); //get the position out of the properties
      absolutePos = Offset(
        absolutePos.dx + nodePos.dx, //add it to the current pos
        absolutePos.dy + nodePos.dy, //same for y
      );
      currentNode = _findParent(currentNode); //and repeat the process with the parent
    }

    return absolutePos; //return it
  }

  EditorNode? _findParent(EditorNode targetNode) { //returns the parent of a given editor node. since the editor nodes dont have parents but only children we have to iterate over every one of them.
    return _findParentRecursive(widget.node, targetNode);
  }

  EditorNode? _findParentRecursive(EditorNode current, EditorNode target) { // a recursive function to iterate over every child node and get the node that has the given node as a child
    for (EditorNode child in current.childrenNodes) { //iterate over every child
      if (child == target) { //if it has the targeted node as a child we found our parent!
        return current;
      }
    }
    //if we didnt find our parent, we have to do the same with every one of the children
    for (EditorNode child in current.childrenNodes) { //iterate over every child again
      final result = _findParentRecursive(child, target); // repeat the process
      if (result != null) return result; //if we got a valid result. we return it to the top
    }

    return null; //return null if there is no node with the given node as a parent
  }

  Widget _buildNodeWidget(EditorNode node) { // builds a widget around the given node with its properties
    final absolutePos = _getAbsolutePosition(node); //get the position of the node. this needs to be done recursively because the pos of the child node is the pos of the parent + the pos of the child.
    final isDragging = node.properties['isDragging'] as bool? ?? false; //if we are currently dragging

    Widget content = Container( // a container to create an outline around our actual content if we are dragging
      decoration: BoxDecoration(
        border: isDragging ? Border.all(color: Colors.blue, width: 2) : null, //if we are dragging, we create a blue border.
      ),
      child: node.builder(), //give the actual content of the current node as a child to be rendered inside
    );

    return Positioned( //move the node to the actual position
      left: absolutePos.dx * screenWidth, //convert the relative position to the absolute position. the relative one is a percentage of the screen size.
      top: absolutePos.dy * screenHeight, //same for the y
      child: GestureDetector( //a gesture detector to detect clicking, dragging, etc.
        behavior: HitTestBehavior.opaque, //set the hit test behavior to opaque, so that only the clicked element gets clicked at, not the ones below it.
        onPanStart: (details) { //when we start clicking / dragging
          setState(() {
            node.properties['isDragging'] = true; //we set dragging to true
          });
        },
        onPanUpdate: (details) => panUpdate(details, node), // when we start / stop / update dragging / clicking
        onPanEnd: (details) { //when we end it
          setState(() {
            node.properties['isDragging'] = false; //we set dragging back to false
          });
        },
        onSecondaryTapDown: (details) { // when we right-click
          _showContextMenu(context, details.globalPosition, node); //we create a little menu to delete, edit, etc. still WIP //TODO
        },
        child: content, //the actual content of the node
      ),
    );
  }


  //pan update = click / drag update
  void panUpdate(DragUpdateDetails details, EditorNode node){

    //we need an exact pos, because every frame we only move the curser by 1-5 px. if we round that back to 0 bc of the grid movement we wouldnt move at all. thats why we have the regular position that is used for rendering and the exact position used for calculating.
    final Offset exactPos = node.properties['exactPosition'] as Offset? ?? node.properties['position'] as Offset? ?? Offset(0.05, 0.05); //if there isnt a position set yet, we use 0.1 as a default (0.1 = 10% of the screen width)

    final Offset newExactPos = Offset(exactPos.dx + details.delta.dx / screenWidth, //add the movement of the curser to the position of the component to drag it with the mouse cursor
        exactPos.dy + details.delta.dy / screenHeight); //same for the y


    final Offset newPos; //the pos after the drag (with a potential grid snap calculate in it)

    if(HardwareKeyboard.instance.isAltPressed){ //if alt is pressed, we snap the position in a grid.
      double gridSize = 32.0; //the size of the fields in that grid

      newPos = Offset(
        (exactPos.dx - (newExactPos.dx % (gridSize / screenWidth))) + details.delta.dx / screenWidth, //by using the modulo (%) operator, we can get the rest to the given point. since we use relative coordinates to the screen size (from 0-1) we have to divide through this
        (exactPos.dy - (newExactPos.dy % (gridSize / screenHeight))) + details.delta.dy / screenHeight, //sam for the y coords
      );

    } else{
      newPos = Offset(
        newExactPos.dx + details.delta.dx / screenWidth, // if we dont pres alt while dragging, we drag precisely on pixel
        newExactPos.dy + details.delta.dy / screenHeight,
      );

    }


    setState(() { //we need to set the state for it to update.
      node.properties['position'] = newPos.clamp(Offset(-0.5, -0.5), Offset(1.5, 1.5)); //the position thats being rendered
      node.properties['exactPosition'] = newExactPos.clamp(Offset(-0.5, -0.5), Offset(1.5, 1.5)); //the exact position
    });
  }

  void _showContextMenu(BuildContext context, Offset position, EditorNode targetNode) async { //shows a menu to add a child / edit / delete / show info from a node
    final selected = await showMenu<String>( // show a menu
      context: context, //on the current build context
      position: RelativeRect.fromLTRB( //set the sizes and position to the given pos
        position.dx,
        position.dy,
        position.dx, //set the sizes to the same pos to be as small as possible
        position.dy,
      ),
      items: [ //the options to choose from
        PopupMenuItem(value: 'add_child', child: Text('Add Child')), //adds a child node
        PopupMenuItem(value: 'edit', child: Text('Edit')), //edits the properties of the node TODO
        PopupMenuItem(value: 'delete', child: Text('Delete')), //deletes the node TODO
        PopupMenuItem(value: 'info', child: Text('Show Info')), //shows some info of the node
      ],
    );

    if (selected == 'add_child') { //if we clicked on 'add child'


      final newType = await showMenu<String>(
        context: context,
        position: RelativeRect.fromLTRB( //set the sizes and position to the given pos
          position.dx,
          position.dy,
          position.dx, //set the sizes to the same pos to be as small as possible
          position.dy,
        ), items: [

          PopupMenuItem(value: "container", child: Text("Container")),
          PopupMenuItem(value: "text", child: Text("Text")),
          PopupMenuItem(value: "row", child: Text("Row")),
          PopupMenuItem(value: "colum", child: Text("Colum"))


      ]);
      setState(() { //we update the state
        final childPos = Offset(0.05, 0.05); //the new child pos

        String text = "";
        if(newType == "text") {
          Future.microtask(() async {
            String text = "";
            if(newType == "text") {
              text = await getDialogueAnswer("question", context);

              setState(() {
                EditorNode newChild = EditorNode(() => _buildText(text),
                    GlobalKey(),
                    properties: {'position': childPos}
                );
                targetNode.childrenNodes.add(newChild);
              });
            }
          });
        }



        EditorNode newChild = EditorNode(() => switch(newType){
          "row" => _buildRow(targetNode),
          "colum" => _buildColumn(targetNode),

          "text" => _buildText(text),
          "container" => _buildContainer(targetNode.key),
          _ => _buildContainer(targetNode.key)
        },
            GlobalKey(), properties: {'position': childPos}
        );

        targetNode.childrenNodes.add(newChild); //and add it to the targeted node
      });
    } else if (selected == 'info') { //if we clicked 'info'
      final parent = _findParent(targetNode); //we get the parent to indicate if the current node has a parent
      final absolutePos = _getAbsolutePosition(targetNode); //and we calculate the abs pos
      ScaffoldMessenger.of(context).showSnackBar( //we show a snack bar (lol)
        SnackBar(content: Text('Parent: ${parent != null ? "Yes" : "Root"}, AbsPos: ${absolutePos.dx.toStringAsFixed(2)}, ${absolutePos.dy.toStringAsFixed(2)}')), //and then we show the info
      );
    }
  }
}

Future<String> getDialogueAnswer(String question, BuildContext context) async {

  final TextEditingController _textController = TextEditingController();

  String text = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(question),
          content: TextField(
            controller: _textController,
            decoration: InputDecoration(hintText: question),
          ),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Submit'),
              onPressed: () {
                Navigator.of(context).pop(_textController.text);
              },
            ),
          ],
        );

      })

      ?? "";


  return text;
}



Container _buildContainer(Key targetedNodeKey){
  return Container( //add a new editor node (for now just a colored container)
    width: 50, //with a width of 50
    height: 30, //and a height of 30
    color: Colors.primaries.random(Random(targetedNodeKey.hashCode)).shade300, //get a random color depending on the parents key
  );
}

Text _buildText(String text){
  return Text(text, style: TextStyle(fontFamily: "gameFont"));
}

Widget _buildRow(EditorNode node){
  return Container(
    constraints: BoxConstraints(
      minWidth: 100,
      minHeight: 50,
    ),
    decoration: BoxDecoration(
      border: Border.all(
        color: Colors.blue.withOpacity(0.5),
        width: 1,
        style: BorderStyle.solid,
      ),
      color: Colors.blue.withOpacity(0.1),
    ),
    child: IntrinsicHeight(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (node.childrenNodes.isEmpty)
            Container(
              width: 80,
              height: 30,
              alignment: Alignment.center,
              child: Text(
                'Empty Row',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

Widget _buildColumn(EditorNode node){
  return Container(
    constraints: BoxConstraints(
      minWidth: 80,
      minHeight: 100,
    ),
    decoration: BoxDecoration(
      border: Border.all(
        color: Colors.green.withOpacity(0.5),
        width: 1,
        style: BorderStyle.solid,
      ),
      color: Colors.green.withOpacity(0.1),
    ),
    child: IntrinsicWidth(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (node.childrenNodes.isEmpty)
            Container(
              width: 60,
              height: 80,
              alignment: Alignment.center,
              child: Text(
                'Empty\nColumn',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

// Lösung 2: Erweiterte Builder mit dynamischen Eigenschaften
Widget _buildRowAdvanced(EditorNode node) {
  // Eigenschaften aus den node properties lesen
  final double minWidth = node.properties['minWidth'] as double? ?? 100;
  final double minHeight = node.properties['minHeight'] as double? ?? 50;
  final bool showBorder = node.properties['showBorder'] as bool? ?? true;
  final MainAxisAlignment mainAxisAlignment =
      node.properties['mainAxisAlignment'] as MainAxisAlignment? ?? MainAxisAlignment.start;
  final CrossAxisAlignment crossAxisAlignment =
      node.properties['crossAxisAlignment'] as CrossAxisAlignment? ?? CrossAxisAlignment.center;

  return Container(
    constraints: BoxConstraints(
      minWidth: minWidth,
      minHeight: minHeight,
    ),
    decoration: showBorder ? BoxDecoration(
      border: Border.all(
        color: Colors.blue.withOpacity(0.5),
        width: 1,
      ),
      color: Colors.blue.withOpacity(0.05),
    ) : null,
    child: IntrinsicHeight(
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: mainAxisAlignment,
        crossAxisAlignment: crossAxisAlignment,
        children: [
          if (node.childrenNodes.isEmpty)
            Container(
              padding: EdgeInsets.fromLTRB(5, 5, 5, 5),
              child: Text(
                'Drop items here',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

Widget _buildColumnAdvanced(EditorNode node) {
  final double minWidth = node.properties['minWidth'] as double? ?? 80;
  final double minHeight = node.properties['minHeight'] as double? ?? 100;
  final bool showBorder = node.properties['showBorder'] as bool? ?? true;
  final MainAxisAlignment mainAxisAlignment =
      node.properties['mainAxisAlignment'] as MainAxisAlignment? ?? MainAxisAlignment.start;
  final CrossAxisAlignment crossAxisAlignment =
      node.properties['crossAxisAlignment'] as CrossAxisAlignment? ?? CrossAxisAlignment.center;

  return Container(
    constraints: BoxConstraints(
      minWidth: minWidth,
      minHeight: minHeight,
    ),
    decoration: showBorder ? BoxDecoration(
      border: Border.all(
        color: Colors.green.withOpacity(0.5),
        width: 1,
      ),
      color: Colors.green.withOpacity(0.05),
    ) : null,
    child: IntrinsicWidth(
      child: Column(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: mainAxisAlignment,
        crossAxisAlignment: crossAxisAlignment,
        children: [

          // Wenn keine Kinder vorhanden sind, Platzhalter anzeigen
          if (node.childrenNodes.isEmpty)
            Container(
              padding: EdgeInsets.all(8),
              child: Text(
                'Drop items\nhere',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

// Hilfsfunktion um zu prüfen ob ein Layout-Widget leer ist
bool _isLayoutEmpty(EditorNode node) {
  return node.childrenNodes.isEmpty;
}

extension OffsetClamp on Offset { //we create an extension for the offset. with that, we can now call the clamp function on any offset. this way everything is cleaned up and we dont have a separate function just for this
  Offset clamp(Offset min, Offset max) { //clamp sets a limit. so if x is smaller than min, we just set it to min, etc.
    return Offset(
      dx.clamp(min.dx, max.dx), //theres already a clamp function for the double we can use
      dy.clamp(min.dy, max.dy), //sane for y
    );
  }
}

class EditorNode { //the logic behind the widgets. the nodes let us create a tree-like structure.
  Map<String, dynamic> properties; //the properties of this node
  List<EditorNode> childrenNodes = []; //the children of this node
  final Widget Function() builder; //the builder. the builder lets us put any widget we want inside our widget as a child.
  Key key; //the key so that every widget is unique

  EditorNode(this.builder, this.key, {required this.properties});
}