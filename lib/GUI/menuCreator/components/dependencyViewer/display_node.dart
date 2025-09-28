import 'package:flutter/material.dart';

import '../propertyEditor/option_editor.dart';
import 'layout_widget.dart';

class DisplayNode extends StatefulWidget {
  //a widget to display a single LayoutWidget and its children
  final LayoutWidget node; //the node to display
  final void Function(LayoutWidget dragged, LayoutWidget target)?
  onReorder; //the function thats called when a widget is dragged and dropped onto another widget to reorder them
  final void Function()
  updateViewport; //a function to update the viewport, not used in this widget but can be used to refresh the view of the parent

  final void Function(LayoutWidget) onClickOnNode;
  final LayoutWidget? Function() getSelectedNode;

  static LayoutWidget? widgetToDropOff;

  const DisplayNode({
    //constructor for the DisplayNode widget
    required this.node, //the node to display
    super.key, //the key for the widget
    this.onReorder, //function to reorder
    required this.updateViewport,
    required this.onClickOnNode,
    required this.getSelectedNode,
  });

  @override
  State<StatefulWidget> createState() => _DisplayNodeState();
}

class _DisplayNodeState extends State<DisplayNode> {
  static bool hasTapped =
      false; //a static variable to check if a menu is currently shown

  @override
  Widget build(BuildContext context) {
    LayoutWidget node = widget.node;

    //build the widget tree for the DisplayNode and its children
    final children =
        widget.node.children; //get the children of the node to display

    List<Widget> displayedChildren =
        []; //a list to hold the widgets that will be displayed as children
    for (int i = 0; i < children.length; i++) {
      //iterate over them

      displayedChildren.add(
        //and add them to the list
        DisplayNode(
          //as a DisplayNode widget
          node: children[i], //with the given child node
          onReorder: widget.onReorder, //and the function to reorder them
          key: ValueKey(children[i].id), //and a key to identify it
          updateViewport:
              widget.updateViewport, //and the function to update the viewport
          onClickOnNode: widget.onClickOnNode,
          getSelectedNode: widget.getSelectedNode,
        ),
      );
    }

    bool canMoveUp =
        (node.parent?.children.indexOf(node) ?? 0) >
        0; //check if the node can be moved up (if its not the first child)
    bool canMoveDown =
        (node.parent?.children.indexOf(node) ?? 0) <
        (node.parent?.children.length ?? 0) -
            1; //check if the node can be moved down (if its not the last child)

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onSecondaryTapDown: (details) {
        if (!hasTapped) {
          //if no menu is currently shown, we show the context menu. we need to do this to prevent multiple menus from parents of this widgets from being shown at the same time
          hasTapped =
              true; //set the static variable to true to indicate that a menu is shown
          _showContextMenu(
            context,
            details,
          ); //show the context menu at the position of the tap
          Future.delayed(
            Duration(milliseconds: 10),
            () => hasTapped = false,
          ); // reset the static variable after a short delay to allow the menu to be shown again
        }
      },

      onTapDown: (details) {
        if (hasTapped) {
          return; //if there has been tapped before, we dont want to do anything
        }
        hasTapped =
            true; //set the static variable to true to indicate that a menu is shown

        Future.delayed(Duration(milliseconds: 10), () => hasTapped = false);

        double buttonX = 16;

        if (buttonX - details.localPosition.dx > 20) {
          return;
        }

        double secondButtonX = 16 * 3; //the position of the second button

        if ((buttonX - details.localPosition.dx).abs() <
            (secondButtonX - details.localPosition.dx).abs()) {
          if (canMoveUp) {
            //if the tap is closer to the first button and the node can be moved up
            node.moveUp(); //we move the node up
            widget.updateViewport(); //and update the viewport
          }
        } //if the tap is closer to the first button, we press the first one
        else if (details.localPosition.dx < 16 * 3) {
          if (canMoveDown) {
            node.moveDown(); //if the tap is closer to the second button and the node can be moved down, we move the node down
            widget.updateViewport();
          }
        } else {
          setState(() {
            widget.onClickOnNode(widget.node);
            print("click");
          });
        }
      },

      child: DragTarget<LayoutWidget>(
        //the DisplayNode is also a DragTarget so that we can drop widgets onto it
        onWillAcceptWithDetails: (dragged) {
          //when a widget is dragged over the DisplayNode we check if we can accept it
          return dragged.data != node &&
              node.canAddChild &&
              dragged.data.canDropOn(
                node,
              ); //if its not the same node and if the node can accept children, we return true
        },
        onAcceptWithDetails: (dragged) {
          //when a widget is dropped onto the DisplayNode
          if (widget.onReorder != null) {
            widget.onReorder!(
              dragged.data,
              node,
            ); //we call the function to reorder the nodes
          }
        },
        builder: (context, candidateData, rejectedData) {
          //build the widget tree for the DisplayNode
          bool isHovering = candidateData
              .isNotEmpty; //check if the DisplayNode is currently being hovered over by a dragged widget

          return Draggable<LayoutWidget>(
            //the DisplayNode is also a Draggable widget so that we can drag it around
            data: node, //the data we want to drag is the node
            feedback: Material(
              //the feedback widget that is displayed while dragging
              elevation: 8, //with a little bit of elevation
              borderRadius: BorderRadius.circular(8), //and a border radius of 8

              child: Container(
                //the container that holds the feedback widget
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ), //with some padding (its used to add some space around the text)
                decoration: BoxDecoration(
                  //the decoration of the container
                  color: Colors.blue.shade100, //a light blue background color
                  borderRadius: BorderRadius.circular(
                    8,
                  ), //with a border radius of 8
                  border: Border.all(
                    color: Colors.blue,
                    width: 2,
                  ), //and a blue border
                ),
                child: Text(
                  //the text that is displayed while dragging
                  node.id, //it displays the id of the node for now //TODO
                  style: const TextStyle(
                    //the style of the text
                    color: Colors.blue, //the text color is blue
                    fontWeight: FontWeight.bold, //in bold
                    fontSize: 14, //with a font size of 14
                  ),
                ),
              ),
            ),
            childWhenDragging: Opacity(
              //the widget that is displayed while dragging the DisplayNode has a lower opacity
              opacity: 0.5, //of 0.5
              child: _buildNodeContent(
                context,
                isHovering,
                displayedChildren,
              ), //the content of the DisplayNode is still displayed while dragging
            ),
            child: _buildNodeContent(
              context,
              isHovering,
              displayedChildren,
            ), //the content of the DisplayNode is displayed normally when not dragging
          );
        },
      ),
    );
  }

  Widget _buildNodeContent(
    //a helper function to build the content of the DisplayNode
    BuildContext context, //the context of the widget
    bool isHovering, //if the DisplayNode is currently being hovered over
    List<Widget>
    displayedChildren, //the list of widgets that are the children of the node
  ) {
    LayoutWidget node = widget.node;

    Color containerColor =
        isHovering ||
            (DisplayNode.widgetToDropOff != null &&
                DisplayNode.widgetToDropOff!.canDropOn(node) &&
                node.canAddChild)
        ? Colors.green.shade50
        : widget.getSelectedNode() == node
        ? Colors.blue.shade300
        : Colors.grey.shade100;

    BoxBorder boxBorder =
        isHovering ||
            (DisplayNode.widgetToDropOff != null &&
                DisplayNode.widgetToDropOff!.canDropOn(node) &&
                node.canAddChild) //if the DisplayNode is being hovered over, we use a green border, otherwise we use a light grey border
        ? Border.all(color: Colors.green, width: 2) // a green border
        : Border.all(
            color: Colors.grey.shade300, // a light grey border
            width: 1,
          );

    return Container(
      //the container that holds the content of the DisplayNode
      decoration: BoxDecoration(
        //the decoration of the container
        color: Colors
            .white, //if the DisplayNode is being hovered over, we use a light green background color, otherwise we use white
        border: boxBorder,
        borderRadius: BorderRadius.circular(2), //with a border radius of 8
      ),
      child: IntrinsicWidth(
        //the content of the DisplayNode should have an intrinsic width (a width that is determined by the content)
        child: Column(
          //the content is a column
          crossAxisAlignment: CrossAxisAlignment
              .start, //with the children aligned to the start (left side)
          mainAxisSize: MainAxisSize.min, //it takes as little space as needed
          children: [
            //the children of the column are the content of the DisplayNode
            Container(
              //the first child is a container that displays the id of the node
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ), //with some padding
              decoration: BoxDecoration(
                //the decoration of the container
                color: containerColor, //a light blue background color
                borderRadius: BorderRadius.circular(
                  4,
                ), //with a border radius of 4
              ),
              child: Row(
                //the content of the container is a row
                mainAxisSize:
                    MainAxisSize.min, //it takes as little space as needed
                children: [
                  //the children of the row are the icon and the id of the node
                  Icon(
                    Icons.keyboard_arrow_up,
                    size: 16,
                    color: (node.parent?.children.indexOf(node) ?? 0) > 0
                        ? Colors.blue.shade700
                        : Colors.grey.shade400,
                  ), //an icon to indicate that the node can be moved up, if its not the first child, otherwise its greyed out
                  Icon(
                    Icons.keyboard_arrow_down,
                    size: 16,
                    color:
                        (node.parent?.children.indexOf(node) ?? 0) <
                            (node.parent?.children.length ?? 0) - 1
                        ? Colors.blue.shade700
                        : Colors.grey.shade400,
                  ),
                  const SizedBox(
                    width: 4,
                  ), //a little space between the icon and the text
                  Text(
                    //the text that displays the id of the node
                    node.id, //the id of the node
                    style: TextStyle(
                      //the style of the text
                      fontSize: 14, //the font size is 14
                      fontWeight:
                          FontWeight.w600, //the font weight is semi-bold
                      color: Colors
                          .blue
                          .shade800, //the text color is a darker blue
                    ),
                  ),
                  const SizedBox(width: 4),
                ],
              ),
            ),
            if (displayedChildren.isNotEmpty) ...[
              //if the node has children, we display them
              Padding(
                //the children are displayed in a column with some padding
                padding: const EdgeInsets.only(
                  left: 20,
                ), //with some padding to the left
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment
                      .start, //the children are aligned to the start (left side)
                  children:
                      displayedChildren, //the children are the widgets we created earlier
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showContextMenu(BuildContext context, TapDownDetails details) {
    LayoutWidget node = widget.node;

    //a function to show a context menu when the user right clicks on the DisplayNode
    hasTapped =
        true; //set the static variable to true to indicate that a menu is shown
    showMenu(
      //show a menu with options
      context: context, //the context of the widget
      position: RelativeRect.fromLTRB(
        details.globalPosition.dx,
        details.globalPosition.dy,
        details.globalPosition.dx,
        details.globalPosition.dy,
      ), //the position of the menu (we can change this to be relative to the DisplayNode)
      items: [
        //the items in the menu
        PopupMenuItem(
          //a menu item to delete the node
          child: const Text("Delete Node"), //the text of the menu item
          onTap: () {
            //when the user taps on the menu item
            node.removeFromParent(
              node,
            ); //remove the node from its parent if it has a removeFromParent function
            widget.updateViewport();
          },
        ),
        PopupMenuItem(
          onTap: () => showPropertiesEditor(
            context,
          ), //a menu item to show the properties editor
          child: const Text("edit properties"),
        ),
        PopupMenuItem(
          child: const Text(
            "pop node",
          ), //a menu item to pop the node (remove it and add its children to the parent)
          onTap: () {
            if (node.parent != null) {
              //if the node has a parent
              node.parent!.addChildren(
                node.children,
              ); //add the children of the node to the parent
              node.removeFromParent(node); //remove the node from its parent
              widget
                  .updateViewport(); //update the viewport to reflect the changes
            }
          },
        ),
      ],
    );
  }

  void showPropertiesEditor(BuildContext context) {
    //a function to show the properties editor for the node

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return OptionEditorMenu(
          node: widget.node,
          updateView: () => widget.updateViewport(),
        );
      },
    );
  }
}
