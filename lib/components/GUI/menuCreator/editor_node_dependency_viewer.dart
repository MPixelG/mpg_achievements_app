import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mpg_achievements_app/components/GUI/menuCreator/layout_widget.dart';

class NodeViewer extends StatefulWidget { // a widget to view and manage a tree of LayoutWidgets
  final LayoutWidget? root; // the root node of the tree to display
  final void Function()? updateViewport; // a function to update the viewport, not used in this widget but can be used to refresh the view of the parent

  const NodeViewer({this.root, super.key, this.updateViewport}); //default constructor with an optional root node

  @override
  State<NodeViewer> createState() => NodeViewerState(); // create the state for this widget. we have a separate class for that
}

class NodeViewerState extends State<NodeViewer> { //the state for the NodeViewer widget
  void _handleReorder(LayoutWidget dragged, LayoutWidget target) { //handle the reordering of nodes when a widget is dragged and dropped onto another
    if (widget.root == null ||//if there is no root node, do nothing
        dragged == target || //if the dragged widget is the same as the target, do nothing
        isDescendant(dragged, target)) { //if the dragged widget is a descendant (a child / grand child / ...) of the target, do nothing
      return;
    }

    final parent = findParent(widget.root!, dragged); //get the parent of the dragged widget
    parent?.children.remove(dragged); //remove the dragged widget from its parent

    target.children.add(dragged); //and add it to the target widgets children
    setState(() {}); //refresh the state to update the gui

    if(widget.updateViewport != null) { //if there is a function to update the viewport, call it
      widget.updateViewport!(); //this is used to refresh the view of the parent widget
    }

  }

  bool isDescendant(LayoutWidget dragged, LayoutWidget target) { //check if the dragged widget is a descendant of the target widget
    for (var child in dragged.children) { //for every child of the dragged widget
      if (child == target || isDescendant(child, target)) return true; //if the child is the target or if the child has the target as a descendant, return true. this checks the entire tree of children recursively
    }
    return false; //if no child is the target or has the target as a descendant, return false
  }

  LayoutWidget? findParent(LayoutWidget root, LayoutWidget child) { //find the parent of a child widget in the tree
    for (var c in root.children) { //for every child of the root widget
      if (c == child) return root; //if the child is the same as the current child, return the root widget as the parent
      final found = findParent(c, child); //if thats not the case, repeat the process for the current child
      if (found != null) return found; //if the child was found in the current child, return it
    }
    return null; //if the child was not found in any of the children, return null
  }

  @override
  Widget build(BuildContext context) { //build the widget tree for the NodeViewer
    if (widget.root == null) { //if there is no root widget, display a message
      return const Scaffold(
        body: Center(child: Text("No root widget defined")), // display that no root widget is defined
      );
    }

    return Scaffold( //the main scaffold for the NodeViewer
      appBar: AppBar( //the app bar at the top of the screen
        title: const Text("Node Viewer"), //with a title
        centerTitle: true, //that is centered
        backgroundColor: Theme.of(context).colorScheme.inversePrimary, //the background color is the inversed scheme
      ),

      //trash to drop widgets
      floatingActionButton: DragTarget<LayoutWidget>( //the floating action button is a preset we use for a trash can. DragTarget allows us to drop widgets onto it
        builder: (context, candidateData, rejectedData) => FloatingActionButton( //set a floating action button as a child so that we can drop widgets onto it and click it to clear the tree
          onPressed: () { //when the button is pressed
            widget.root!.children.clear(); //clear the children of the root widget
            setState(() {}); //and refresh the state to update the gui
            widget.updateViewport!();
          },
          child: Icon(CupertinoIcons.trash), //the icon of the button is a trash can
        ),
        onAcceptWithDetails: (details) { //when a widget is dropped onto the button
          details.data.removeFromParent(details.data); //we remove the widget from its parent so that its gone
          setState(() {}); //and refresh the state to update the gui
          widget.updateViewport!();
        },
      ),

      body: Container( //the actual body of the NodeViewer
        padding: const EdgeInsets.all(16), //padding around the content so that it doesnt touch the edges
        child: InteractiveViewer( //allows us to zoom and move the content
          constrained: false, //we dont want to constrain the size of the content
          boundaryMargin: const EdgeInsets.all(10), //the margin around the content so that we can scroll a bit outside the content
          minScale: 0.4, //the minimum scale we can zoom out to
          maxScale: 8.0, //the maximum scale we can zoom in to
          child: SingleChildScrollView( //allows to scroll horizontally
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView( //and vertically
              scrollDirection: Axis.vertical,
              child: Container( //the container that holds the content
                constraints: const BoxConstraints( //with constraints so that it has a minimum size
                  minWidth: 800, //of 800
                  minHeight: 600, //and 600
                ),
                child: DisplayNode( //the actual display node. it also displays all the children recursively
                  node: widget.root!, //the root widget is the node we want to display
                  onReorder: _handleReorder, //the function to handle reordering of nodes when they are dragged and dropped onto each other
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class DisplayNode extends StatelessWidget { //a widget to display a single LayoutWidget and its children
  final LayoutWidget node; //the node to display
  final void Function(LayoutWidget dragged, LayoutWidget target)? onReorder; //the function thats called when a widget is dragged and dropped onto another widget to reorder them

  const DisplayNode({ //constructor for the DisplayNode widget
    required this.node, //the node to display
    super.key, //the key for the widget
    this.onReorder, //function to reorder
  });

  @override
  Widget build(BuildContext context) { //build the widget tree for the DisplayNode and its children
    final children = node.children; //get the children of the node to display

    List<Widget> displayedChildren = []; //a list to hold the widgets that will be displayed as children
    for (int i = 0; i < children.length; i++) { //iterate over them

      displayedChildren.add( //and add them to the list
        DisplayNode( //as a DisplayNode widget
          node: children[i], //with the given child node
          onReorder: onReorder, //and the function to reorder them
          key: ValueKey(children[i].id), //and a key to identify it
        ),
      );
    }

    return DragTarget<LayoutWidget>( //the DisplayNode is also a DragTarget so that we can drop widgets onto it
      onWillAcceptWithDetails: (dragged) { //when a widget is dragged over the DisplayNode we check if we can accept it
        return dragged.data != node && node.canAddChild; //if its not the same node and if the node can accept children, we return true
      },
      onAcceptWithDetails: (dragged) { //when a widget is dropped onto the DisplayNode
        if (onReorder != null) onReorder!(dragged.data, node); //we call the function to reorder the nodes
      },
      builder: (context, candidateData, rejectedData) { //build the widget tree for the DisplayNode
        bool isHovering = candidateData.isNotEmpty; //check if the DisplayNode is currently being hovered over by a dragged widget

        return Draggable<LayoutWidget>( //the DisplayNode is also a Draggable widget so that we can drag it around
          data: node, //the data we want to drag is the node
          feedback: Material( //the feedback widget that is displayed while dragging
            elevation: 8, //with a little bit of elevation
            borderRadius: BorderRadius.circular(8), //and a border radius of 8
            child: GestureDetector(
              onSecondaryTap: () { //when the user right clicks on the feedback widget,

              },

              child: Container( //the container that holds the feedback widget
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), //with some padding (its used to add some space around the text)
                decoration: BoxDecoration( //the decoration of the container
                  color: Colors.blue.shade100, //a light blue background color
                  borderRadius: BorderRadius.circular(8), //with a border radius of 8
                  border: Border.all(color: Colors.blue, width: 2), //and a blue border
                ),
                child: Text( //the text that is displayed while dragging
                  node.id, //it displays the id of the node for now //TODO
                  style: const TextStyle( //the style of the text
                    color: Colors.blue, //the text color is blue
                    fontWeight: FontWeight.bold, //in bold
                    fontSize: 14, //with a font size of 14
                  ),
                ),
              ),
            ),
          ),
          childWhenDragging: Opacity( //the widget that is displayed while dragging the DisplayNode has a lower opacity
            opacity: 0.5, //of 0.5
            child: _buildNodeContent(context, isHovering, displayedChildren), //the content of the DisplayNode is still displayed while dragging
          ),
          child: _buildNodeContent(context, isHovering, displayedChildren), //the content of the DisplayNode is displayed normally when not dragging
        );
      },
    );
  }

  Widget _buildNodeContent( //a helper function to build the content of the DisplayNode
    BuildContext context, //the context of the widget
    bool isHovering, //if the DisplayNode is currently being hovered over
    List<Widget> displayedChildren, //the list of widgets that are the children of the node
  ) {
    return Container( //the container that holds the content of the DisplayNode
      margin: const EdgeInsets.symmetric(vertical: 2.0), //with some vertical margin (the space between the nodes)
      padding: const EdgeInsets.all(8.0), //and some padding (the space inside the node)
      decoration: BoxDecoration( //the decoration of the container
        color: isHovering ? Colors.green.shade50 : Colors.transparent, //if the DisplayNode is being hovered over, we use a light green background color, otherwise we use transparent (no background)
        border: isHovering //if the DisplayNode is being hovered over, we use a green border, otherwise we use a light grey border
            ? Border.all(color: Colors.green, width: 2) // a green border
            : Border.all(color: Colors.grey.shade300, width: 1), // a light grey border
        borderRadius: BorderRadius.circular(8), //with a border radius of 8
      ),
      child: IntrinsicWidth( //the content of the DisplayNode should have an intrinsic width (a width that is determined by the content)
        child: Column( //the content is a column
          crossAxisAlignment: CrossAxisAlignment.start, //with the children aligned to the start (left side)
          mainAxisSize: MainAxisSize.min, //it takes as little space as needed
          children: [ //the children of the column are the content of the DisplayNode
            Container( //the first child is a container that displays the id of the node
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), //with some padding
              decoration: BoxDecoration( //the decoration of the container
                color: Colors.blue.shade50, //a light blue background color
                borderRadius: BorderRadius.circular(4), //with a border radius of 4
              ),
              child: Row( //the content of the container is a row
                mainAxisSize: MainAxisSize.min, //it takes as little space as needed
                children: [ //the children of the row are the icon and the id of the node
                  Icon(Icons.widgets, size: 16, color: Colors.blue.shade700), //an icon in a blue color
                  const SizedBox(width: 4), //a little space between the icon and the text
                  Text( //the text that displays the id of the node
                    node.id, //the id of the node
                    style: TextStyle( //the style of the text
                      fontSize: 14, //the font size is 14
                      fontWeight: FontWeight.w600, //the font weight is semi-bold
                      color: Colors.blue.shade800, //the text color is a darker blue
                    ),
                  ),
                ],
              ),
            ),
            if (displayedChildren.isNotEmpty) ...[ //if the node has children, we display them
              const SizedBox(height: 8), //a little space between the id and the children
              Padding( //the children are displayed in a column with some padding
                padding: const EdgeInsets.only(left: 20), //with some padding to the left
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, //the children are aligned to the start (left side)
                  children: displayedChildren, //the children are the widgets we created earlier
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
