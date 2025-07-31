import 'package:flame/extensions.dart';
import 'package:flutter/material.dart';
import 'package:mpg_achievements_app/components/GUI/menuCreator/editor_node_dependency_viewer.dart';
import 'package:mpg_achievements_app/components/GUI/menuCreator/layout_widget.dart';
class GuiEditor extends StatefulWidget { //the GUI editor lets us create guis and later export them as a json TODO
  const GuiEditor({super.key});

  @override
  State<StatefulWidget> createState() => _GuiEditorState(); //the state of the widget. we have a separate class for that.
}

class _GuiEditorState extends State<GuiEditor> { //the state class for the GUI editor.

  double get screenWidth => MediaQuery.of(context).size.width;
  double get screenHeight => MediaQuery.of(context).size.width;

  late LayoutWidget root; //just temp to be initialized later in initState()

  late NodeViewer nodeViewer; //this is the node viewer that will be used to show the dependencies of a node. TODO: implement this
  final GlobalKey<NodeViewerState> _nodeViewerKey = GlobalKey<NodeViewerState>();


  @override
  void initState(){

    root = addContainer();
    nodeViewer = NodeViewer(root: root, key: _nodeViewerKey,); //the node viewer is initialized with the root widget, which is the main widget that contains all the other widgets.

    super.initState();
  }




  @override
  Widget build(BuildContext context) { //here we actually build the stuff thats being rendered
    return Scaffold( //we use a scaffold bc it lets us easily add components with some presets.
      backgroundColor: Colors.white,

        body: Row(
          children: [
            SizedBox(height: screenHeight, width: 0.2 * screenWidth, child: nodeViewer), //the node viewer is on the left side of the screen, taking up 20% of the width
            SizedBox(height: screenHeight, width: 0.8 * screenWidth, child: root.build(context)),// the root widget is the main widget that contains all the other widgets. it is built using the LayoutWidget class.
          ]
        ),

      floatingActionButton: PopupMenuButton(itemBuilder: (context) => [
        PopupMenuItem(
          value: 'container',
          child: ListTile(
            leading: Icon(Icons.add_card),
            title: Text('Container'),
          ),
        ),
        PopupMenuItem(
          value: 'text',
          child: ListTile(
            leading: Icon(Icons.text_snippet),
            title: Text('Text'),
          ),
        ),
        PopupMenuItem(
          value: 'row',
          child: ListTile(
            leading: Icon(Icons.rectangle_outlined),
            title: Text('Row'),
          ),
        ),
      ],
          onSelected: (value) {
            switch(value){
              case "container": addWidget(addContainer());
              case "text": showTextAlertDialog(context);
              case "row": addWidget(addRow());
            }

            _nodeViewerKey.currentState?.setState(() {}); //this updates the node viewer to show the new widget that was added
            print("updated state of node viewer!");

          },tooltip: "open widget menu", child: Icon(Icons.add_box_rounded),),
    );
  }

  void showTextAlertDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        String inputText = "";
        return AlertDialog(
          title: Text("Ener your text name here"),
          content: TextField(
            autofocus: true,
            onChanged: (value) {
              inputText = value;
            },
            decoration: InputDecoration(hintText: "Ener your text name here"),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                if (inputText.isNotEmpty) {
                  addWidget(addText(inputText));
                }
              },
              child: Text("Accept"),
            ),
          ],
        );
      },
    );
  }

  /// Adds a widget to the layout.
  /// The widget is built using the provided LayoutWidget.
  void addWidget(LayoutWidget layoutWidget) async{
    setState(() {
      root.addChild(layoutWidget);
    });
  }


  List<Widget> toWidgetList(List<LayoutWidget> widgets) {
    return widgets.map((widget) => widget.build(context)).toList();
  }


  int containerIndex = 0; //this is used to give the container widgets a unique id
  /// Adds a container widget to the layout.
  /// The container will fill a percentage of the screen size based on the properties provided.
  /// If no properties are provided, it defaults to 30% of the screen width and height.
  /// The container will have a random color from the Colors.primaries list.
  LayoutWidget addContainer(){
    LayoutWidget widget = LayoutWidget((context, children, properties) {

      double screenWidth = MediaQuery.of(context).size.width;
      double screenHeight = MediaQuery.of(context).size.height;

      return Container(
        color: Colors.primaries.random(),
        width: properties["width"] == null ? double.infinity : properties["width"] * screenWidth,
        height: properties["height"] == null ? double.infinity : properties["height"] * screenHeight,
        child: Stack(children: children),
      );
    }, id: 'container${containerIndex++}');

    return widget;
  }


  int rowIndex = 0; //this is used to give the row widgets a unique id
  LayoutWidget addRow(){
    LayoutWidget widget = LayoutWidget((context, children, properties) {
      return Row(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.center,
        children: children,
      );
    }, id: 'row${rowIndex++}');

    return widget;
  }


  int textIndex = 0; //this is used to give the text widgets a unique id
  /// Adds a text widget to the layout.
  LayoutWidget addText(String text){
    LayoutWidget widget = LayoutWidget((context, children, properties) {

      return Stack(
        children: [
          Text(
            text,
            style: TextStyle(fontSize: 18, color: Colors.black, fontFamily: "gameFont"),
            textAlign: TextAlign.center),
        ...children]
      );
    }, id: 'text${textIndex++}');

    return widget;
  }
}