import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mpg_achievements_app/components/GUI/menuCreator/components/dependencyViewer/layout_widget.dart';
import 'package:mpg_achievements_app/components/GUI/menuCreator/components/propertyEditor/option_editor.dart';

import 'display_node.dart';

class NodeViewer extends StatefulWidget {
  // a widget to view and manage a tree of LayoutWidgets
  final LayoutWidget root; // the root node of the tree to display
  final void Function()? updateViewport; // a function to update the viewport, not used in this widget but can be used to refresh the view of the parent

  late final List<LayoutWidget> _currentSelectedWidget;

  final void Function(LayoutWidget newNode) updateWithNewSelectedWidget;

  NodeViewer({
    required this.root,
    super.key,
    this.updateViewport,
    required this.updateWithNewSelectedWidget,
  }) { //default constructor with an optional root node
    _currentSelectedWidget = [root];
  }

  LayoutWidget get currentSelectedWidget => _currentSelectedWidget.firstOrNull ?? root;
  set currentSelectedWidget(LayoutWidget newVal) {
    _currentSelectedWidget[0] = newVal;
    updateViewport!();
  }

  @override
  State<NodeViewer> createState() => NodeViewerState(); // create the state for this widget. we have a separate class for that
}

class NodeViewerState extends State<NodeViewer> {
  //the state for the NodeViewer widget

  bool isInDropMode = false;

  @override
  void initState() {
    super.initState();
  }


  void _handleReorder(LayoutWidget dragged, LayoutWidget target) {
    //handle the reordering of nodes when a widget is dragged and dropped onto another
    if (dragged == target || //if the dragged widget is the same as the target, do nothing
        isDescendant(dragged, target)) {
      //if the dragged widget is a descendant (a child / grand child / ...) of the target, do nothing
      return;
    }

    final parent = findParent(
      widget.root,
      dragged,
    ); //get the parent of the dragged widget
    parent?.removeChild(dragged); //remove the dragged widget from its parent

    target.addChild(dragged); //and add it to the target widgets children
    setState(() {}); //refresh the state to update the gui

    if (widget.updateViewport != null) {
      //if there is a function to update the viewport, call it
      widget.updateViewport!(); //this is used to refresh the view of the parent widget
    }
  }

  LayoutWidget? findParent(LayoutWidget root, LayoutWidget child) {
    //find the parent of a child widget in the tree
    for (var c in root.children) {
      //for every child of the root widget
      if (c == child) {
        return root; //if the child is the same as the current child, return the root widget as the parent
      }
      final found = findParent(
        c,
        child,
      ); //if thats not the case, repeat the process for the current child
      if (found != null) {
        return found; //if the child was found in the current child, return it
      }
    }
    return null; //if the child was not found in any of the children, return null
  }

  LayoutWidget? selectedNode;

  void updateSelectedNode(LayoutWidget node){
    setState(() {

      if(DisplayNode.widgetToDropOff != null){

        if((DisplayNode.widgetToDropOff != null && DisplayNode.widgetToDropOff!.canDropOn(node) && node.canAddChild)) {
          node.addChild(DisplayNode.widgetToDropOff!);

          widget.updateViewport!();

          DisplayNode.widgetToDropOff = null;
        }
      }else {
        selectedNode = node;
        widget._currentSelectedWidget[0] = node;
        widget.updateWithNewSelectedWidget(node);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    //build the widget tree for the NodeViewer
    return Scaffold(
      //the main scaffold for the NodeViewer
      appBar: AppBar(
        //the app bar at the top of the screen
        title: const Text("Node Viewer"), //with a title
        centerTitle: true, //that is centered
        backgroundColor: Theme.of(context)
            .colorScheme
            .inversePrimary, //the background color is the inversed scheme
      ),
      //trash to drop widgets
      floatingActionButton: DragTarget<LayoutWidget>(
        //the floating action button is a preset we use for a trash can. DragTarget allows us to drop widgets onto it
        builder: (context, candidateData, rejectedData) => FloatingActionButton(
          //set a floating action button as a child so that we can drop widgets onto it and click it to clear the tree
          onPressed: () {
            //when the button is pressed
            widget.root.children
                .clear(); //clear the children of the root widget
            setState(() {}); //and refresh the state to update the gui
            widget.updateViewport!();
          },
          child: Icon(
            CupertinoIcons.trash,
          ), //the icon of the button is a trash can
        ),
        onAcceptWithDetails: (details) {
          //when a widget is dropped onto the button
          details.data.removeFromParent(
            details.data,
          ); //we remove the widget from its parent so that its gone
          setState(() {}); //and refresh the state to update the gui
          widget.updateViewport!();
        },
      ),

      body: InteractiveViewer(
        //allows us to zoom and move the content
        constrained:
            false, //we dont want to constrain the size of the content
        boundaryMargin: const EdgeInsets.all(
          60,
        ), //the margin around the content so that we can scroll a bit outside the content
        scaleEnabled: false,
        child: SingleChildScrollView(
          //allows to scroll horizontally
          scrollDirection: Axis.horizontal,
          child: SingleChildScrollView(
            //and vertically
            scrollDirection: Axis.vertical,
            child: Container(
              //the container that holds the content
              constraints: const BoxConstraints(
                //with constraints so that it has a minimum size
                minWidth: 200, //of 800
                minHeight: 600, //and 600
              ),
              child: DisplayNode(
                //the actual display node. it also displays all the children recursively
                node: widget.root, //the root widget is the node we want to display
                onReorder: _handleReorder, //the function to handle reordering of nodes when they are dragged and dropped onto each other
                updateViewport: () {
                  widget.updateViewport!();
                  setState(() {});
                }, //the function to update the viewport, not used in this widget but can be used to refresh the view of the parent
                onClickOnNode: updateSelectedNode, getSelectedNode: () => selectedNode,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

