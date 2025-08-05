import 'dart:convert';
import 'dart:io';

import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/material.dart' hide Matrix4;
import 'package:flutter/services.dart';
import 'package:mpg_achievements_app/components/GUI/menuCreator/json_exporter.dart';
import 'package:mpg_achievements_app/components/GUI/menuCreator/widget_builder.dart';
import 'package:mpg_achievements_app/components/GUI/menuCreator/editor_node_dependency_viewer.dart';
import 'package:mpg_achievements_app/components/GUI/menuCreator/layout_widget.dart';
import 'package:mpg_achievements_app/components/GUI/menuCreator/widget_option_definitions.dart';

class GuiEditor extends StatefulWidget { //the GUI editor lets us create guis and later export them as a json TODO
  const GuiEditor({super.key});

  @override
  State<StatefulWidget> createState() => _GuiEditorState(); //the state of the widget. we have a separate class for that.
}

class _GuiEditorState extends State<GuiEditor> { //the state class for the GUI editor.

  double get screenWidth => MediaQuery.of(context).size.width; //getter for the screen width, so we can use it to calculate the size of the widgets
  double get screenHeight => MediaQuery.of(context).size.height; //same for the width

  late LayoutWidget root; //just temp to be initialized later in initState()

  NodeViewer? nodeViewer; //this is the node viewer that will be used to show the dependencies of a node. TODO: implement this
  final GlobalKey<NodeViewerState> _nodeViewerKey = GlobalKey<NodeViewerState>();

  void updateViewport() { //this is used to update the viewport of the node viewer, so that it shows the current state of the layout
    setState(() {}); //we call setState on the node viewer to rebuild it and show the current state of the layout
  }

  @override
  void initState() {
    super.initState();
    initEditor();


    registerWidgetOptions();
  }

  bool doneLoading = false;
  Future<void> initEditor() async {
    doneLoading = false;

    root = await WidgetJsonUtils.importScreen("test");

    setState(() {
      nodeViewer = NodeViewer(
        root: root,
        key: _nodeViewerKey,
        updateViewport: updateViewport,
      );
    });
    doneLoading = true;
  }

  Future<Map<String, dynamic>> loadJson(String name) async {
    final jsonString = await rootBundle.loadString("assets/screens/$name.json");
    final jsonMap = json.decode(jsonString);
    return Map<String, dynamic>.from(jsonMap);
  }

  @override
  Widget build(BuildContext context) { //here we actually build the stuff thats being rendered
    if (nodeViewer == null) return const Center(child: CircularProgressIndicator());


    return Scaffold( //we use a scaffold bc it lets us easily add components with some presets.
      backgroundColor: Colors.white, //the background color of the scaffold is white, so we can see the widgets clearly

        body: Row( //we use a row to display the node viewer and the root widget side by side
          children: [ //the children of the row are the node viewer and the root widget
            SizedBox(height: screenHeight, width: 0.2 * screenWidth, child: nodeViewer), //the node viewer is on the left side of the screen, taking up 20% of the width
            SizedBox(height: screenHeight, width: 0.8 * screenWidth, child: root.build(context)),// the root widget is the main widget that contains all the other widgets. it is built using the LayoutWidget class.
          ]
        ),

      floatingActionButton: Row(mainAxisAlignment: MainAxisAlignment.end,children: [

        FloatingActionButton(
          heroTag: null,
          onPressed: () {
          String json = WidgetJsonUtils.exportWidgetToJson(root); //we convert the root widget to a json string
          print("json: $json");
        }, child: Icon(Icons.outbond_outlined),),

        PopupMenuButton(itemBuilder: (context) => [ //this is the floating action button that opens a popup menu with the options to add widgets
          PopupMenuItem( //this is the popup menu item that lets us add a positioned widget
            value: 'interactive_viewer', //the value of the popup menu item is used to identify which widget to add
            child: ListTile( //the ListTile is used to display the icon and the text of the popup menu item
              leading: Icon(Icons.dashboard_customize_outlined), //the icon of the ListTile is the icon that is displayed next to the text
              title: Text('Interactive Viewer'), //the displayed text
            ),
          ),
          PopupMenuItem( //this is the popup menu item that lets us add a positioned widget
            value: 'single_child_scroll_view', //the value of the popup menu item is used to identify which widget to add
            child: ListTile( //the ListTile is used to display the icon and the text of the popup menu item
              leading: Icon(Icons.expand_rounded), //the icon of the ListTile is the icon that is displayed next to the text
              title: Text('Single Child Scroll View'), //the displayed text
            ),
          ),



        PopupMenuItem( //this is the popup menu item that lets us add a positioned widget
          value: 'fitted_box', //the value of the popup menu item is used to identify which widget to add
          child: ListTile( //the ListTile is used to display the icon and the text of the popup menu item
            leading: Icon(Icons.fit_screen), //the icon of the ListTile is the icon that is displayed next to the text
            title: Text('Fitted Box'), //the displayed text
          ),
        ),
        PopupMenuItem( //this is the popup menu item that lets us add a grid view widget
          value: 'grid_view', //the value of the popup menu item is used to identify which widget to add
          child: ListTile( //the ListTile is used to display the icon and the text of the popup menu item
            leading: Icon(Icons.grid_view), //the icon of the ListTile is the icon that is displayed next to the text
            title: Text('Grid View'), //the displayed text
          ),
        ),
        PopupMenuItem( //this is the popup menu item that lets us add a transform widget
          value: 'transform', //the value of the popup menu item is used to identify which widget to add
          child: ListTile( //the ListTile is used to display the icon and the text of the popup menu item
            leading: Icon(Icons.transform), //the icon of the ListTile is the icon that is displayed next to the text
            title: Text('Transform'), //the displayed text
          ),
        ),
        PopupMenuItem( //this is the popup menu item that lets us add an opacity widget
          value: 'opacity', //the value of the popup menu item is used to identify which widget to add
          child: ListTile( //the ListTile is used to display the icon and the text of the popup menu item
            leading: Icon(Icons.opacity), //the icon of the ListTile is the icon that is displayed next to the text
            title: Text('Opacity'), //the displayed text
          ),
        ),

        PopupMenuItem(
          value: "image",
          child: ListTile(leading:
              Icon(Icons.image),
              title: Text("Image"),
          )
        ),

        PopupMenuItem(
          value: 'expanded', //another option for positioned
          child: ListTile(
            leading: Icon(Icons.expand_rounded), //a positioned icon
            title: Text('Expanded'), //with Positioned as a display
          ),
        ),
        PopupMenuItem(
          value: 'positioned', //another option for positioned
          child: ListTile(
            leading: Icon(Icons.add_circle_outline), //a positioned icon
            title: Text('Positioned'), //with Positioned as a display
          ),
        ),
        PopupMenuItem(//this is the popup menu item that lets us add a container widget
          value: 'container', //the value of the popup menu item is used to identify which widget to add
          child: ListTile( //the ListTile is used to display the icon and the text of the popup menu item
            leading: Icon(Icons.add_card), //the icon of the ListTile is the icon that is displayed next to the text
            title: Text('Container'), //the displayed text
          ),
        ),
        PopupMenuItem( //another option for text
          value: 'text', //text as a value
          child: ListTile(
            leading: Icon(Icons.text_snippet), //a text snippet icon
            title: Text('Text'), //with Text as a display
          ),
        ),
        PopupMenuItem( //another option for row
          value: 'row', //row as a value
          child: ListTile(
            leading: Icon(Icons.view_agenda_rounded), //a rectangle icon
            title: Text('Row'), //with Row as a display
          ),
        ),
        PopupMenuItem( //another option for nine patch button
          value: 'ninepatch_button', //nine patch button as a value
          child: ListTile(
            leading: Icon(Icons.casino_outlined), //a square icon
            title: Text('Nine Patch Button'), //with Nine Patch Button as a display
          ),
        ),
        PopupMenuItem(
          value: 'column', //another option for column
          child: ListTile(
            leading: Icon(Icons.view_week_rounded), //a column icon
            title: Text('Column'), //with Column as a display
          ),
        ),
        PopupMenuItem( //another option for stack)
          value: 'stack', //stack as a value
          child: ListTile(
            leading: Icon(Icons.layers), //a stack icon
            title: Text('Stack'), //with Stack as a display
          ),
        ),
    ],
          onSelected: (value) { //this is called when an item is selected from the popup menu
            switch(value){ //we switch on the value of the selected item
              case "positioned": {LayoutWidget? parent = getNearestStackRecursive(root); addWidget(addPositioned(parent), root: parent);} //if the value is positioned, we add a positioned widget to the root widget
              case "container": addWidget(addContainer(root)); //if the value is container, we add a container widget to the root widget
              case "text": showTextAlertDialog(context); //same for text
              case "row": addWidget(addRow(root)); //and row
              case "column": addWidget(addColumn(root)); //and column
              case "stack": addWidget(addStack(root)); //and stack
              case "ninepatch_button": addWidget(addNinepatchButton(root)); //and nine patch button
              case "expanded": {
                LayoutWidget? parent = getNearestFlexRecursive(root); //we get the nearest stack widget to add the expanded widget to, because you can only add expanded widgets to a row or column
                addWidget(addExpanded(parent), root: parent);
              }
              case "fitted_box": addWidget(addFittedBox(root));
              case "grid_view": addWidget(addGridView(root));
              case "transform": addWidget(addTransform(root));
              case "opacity": addWidget(addOpacity(root));
              case "image": addWidget(addImage(root));
              case "interactive_viewer": addWidget(addInteractiveViewer(root));
              case "single_child_scroll_view": addWidget(addSingleChildScrollView(root));
            }

            _nodeViewerKey.currentState?.setState(() {}); //this updates the node viewer to show the new widget that was added

          },tooltip: "open widget menu", child: Icon(Icons.add_box_rounded)), //tooltip and + icon

      ],)
    );
  }

  void showTextAlertDialog(BuildContext context) { //this function shows an alert dialog to enter text for a text widget
    showDialog( //buil-in function to show a dialog
      context: context, //the context is the current context of the widget
      builder: (context) { //the builder is a function that returns the widget that will be displayed in the dialog
        String inputText = ""; //this is the text that will be entered in the text field. we set it to an empty string by default
        return AlertDialog( //the actual dialog widget
          title: Text("Enter your text name here"), //the title of the dialog
          content: TextField( //the content of the dialog is a text field where the user can enter the text
            autofocus: true, //this makes the text field focused when the dialog is opened
            onChanged: (value) { //this is called when the text in the text field changes
              inputText = value; //we update the inputText variable with the new value
            },
            decoration: InputDecoration(hintText: "Ener your text name here"), //the background of the text field has a hint text that tells the user what to enter
          ),
          actions: [ //the actions of the dialog are the buttons that the user can press
            TextButton( //the cancel button
              onPressed: () {
                Navigator.of(context).pop(); //we close the dialog when the user presses the cancel button
              },
              child: Text("Cancel"), //the text of the cancel button
            ),
            TextButton( //the accept button
              onPressed: () {
                Navigator.of(context).pop(); //we close the dialog when the user presses the accept button
                if (inputText.isNotEmpty) { //if the inputText is not empty, we add a text widget to the root widget
                  addWidget(addText(inputText, root)); //we add the text widget to the root widget
                  _nodeViewerKey.currentState?.setState(() {}); //this updates the node viewer to show the new text widget that was added. we use the key to access the state of the node viewer and call setState to rebuild it
                }
              },
              child: Text("Accept"), //the text of the accept button
            ),
          ],
        );
      },
    );
  }

  /// Adds a widget to the layout.
  /// The widget is built using the provided LayoutWidget.
  void addWidget(LayoutWidget? layoutWidget, {LayoutWidget? root}) async{
    if(layoutWidget == null) return; //if the layoutWidget is null, we return and do not add anything

    setState(() { //we call setState to rebuild the widget tree and show the new widget
      root ??= this.root; //if no root is provided, we use the current root widget

      root!.addChild(layoutWidget); //we add the new widget to the root widget's children
    });
  }


  List<Widget> toWidgetList(List<LayoutWidget> widgets) {
    return widgets.map((widget) => widget.build(context)).toList();
  }


  LayoutWidget? getNearestStackRecursive(LayoutWidget widget) {
    for (var value in widget.children) {
      if (value.widgetType == Stack) { //if the widget is a stack, we return it
        return value; //we return the stack widget
      }
      return getNearestStackRecursive(value);
    }
    return null; //if we reach here, it means that the widget has no parent or no children, so we return null
  }

  LayoutWidget? getNearestFlexRecursive(LayoutWidget widget) {
    for (var value in widget.children) {
      if (value.widgetType == Row || value.widgetType == Column) {
        return value; //we return the expanded widget
      }
      return getNearestFlexRecursive(value);
    }
    return null; //if we reach here, it means that the widget has no parent or no children, so we return null
  }





}