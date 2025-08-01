import 'package:flame/extensions.dart';
import 'package:flutter/material.dart';
import 'package:mpg_achievements_app/components/GUI/menuCreator/editor_node_dependency_viewer.dart';
import 'package:mpg_achievements_app/components/GUI/menuCreator/layout_widget.dart';
import 'package:mpg_achievements_app/components/GUI/menuCreator/widget_options.dart';
import 'package:mpg_achievements_app/components/GUI/widgets/nine_patch_button.dart';
class GuiEditor extends StatefulWidget { //the GUI editor lets us create guis and later export them as a json TODO
  const GuiEditor({super.key});

  @override
  State<StatefulWidget> createState() => _GuiEditorState(); //the state of the widget. we have a separate class for that.
}

class _GuiEditorState extends State<GuiEditor> { //the state class for the GUI editor.

  double get screenWidth => MediaQuery.of(context).size.width; //getter for the screen width, so we can use it to calculate the size of the widgets
  double get screenHeight => MediaQuery.of(context).size.width; //same for the width

  late LayoutWidget root; //just temp to be initialized later in initState()

  late NodeViewer nodeViewer; //this is the node viewer that will be used to show the dependencies of a node. TODO: implement this
  final GlobalKey<NodeViewerState> _nodeViewerKey = GlobalKey<NodeViewerState>();

  void updateViewport() { //this is used to update the viewport of the node viewer, so that it shows the current state of the layout
    setState(() {}); //we call setState on the node viewer to rebuild it and show the current state of the layout
  }

  @override
  void initState(){ //inits. basically the same as onLoad but for flutter widgets
    registerWidgetOptions(); //we register the widget options for the widgets that can be added to the layout. this is used to define the properties of the widgets that can be set in the GUI editor.

    root = addContainer(null); //set the root widget to a container widget, which is the main widget that contains all the other widgets. we set null as the parent, so it is the root widget.
    nodeViewer = NodeViewer(root: root, key: _nodeViewerKey, updateViewport: updateViewport); //the node viewer is initialized with the root widget, which is the main widget that contains all the other widgets.

    super.initState();
  }


  void registerWidgetOptions() { //this is used to register the widget options for the widgets that can be added to the layout

    WidgetOptions(Container, options: [
      WidgetOption<double>(parseDouble, name: "width", defaultValue: 0.1, description: "The width of the container as a percentage of the screen width"),
      WidgetOption<double>(parseDouble, name: "height", defaultValue: 0.1, description: "The height of the container as a percentage of the screen height"),
      WidgetOption<Color>(parseColor, name: "color", defaultValue: null, description: "The color of the container."),
      WidgetOption<EdgeInsetsGeometry?>(parseEdgeInsets, name: "padding", defaultValue: null, description: "The padding of the container. If not set, no padding will be used.", options: [
        null,
        EdgeInsets.all(5),
        EdgeInsets.all(10),
        EdgeInsets.all(20),
        EdgeInsets.all(30),
        EdgeInsets.all(50),
        EdgeInsets.all(100),
      ]),
      WidgetOption<EdgeInsetsGeometry?>(parseEdgeInsets, name: "margin", defaultValue: null, description: "The margin of the container. If not set, no margin will be used.", options: [
        null,
        EdgeInsets.all(5),
        EdgeInsets.all(10),
        EdgeInsets.all(20),
        EdgeInsets.all(30),
        EdgeInsets.all(50),
        EdgeInsets.all(100),
      ]),
      WidgetOption<Alignment?>(parseAlignment, name: "alignment", defaultValue: null, description: "The alignment of the container. If not set, center will be used.", options: [
        null,
        Alignment.center,
        Alignment.topLeft,
        Alignment.topRight,
        Alignment.bottomLeft,
        Alignment.bottomRight,
        Alignment.topCenter,
        Alignment.bottomCenter,
      ]),
    ]).register();

    WidgetOptions(Row, options: [
      WidgetOption<MainAxisAlignment>(parseMainAxisAlignment, name: "mainAxisAlignment", defaultValue: MainAxisAlignment.center, description: "The main axis alignment of the row. If not set, center will be used."),
      WidgetOption<CrossAxisAlignment>(parseCrossAxisAlignment, name: "crossAxisAlignment", defaultValue: CrossAxisAlignment.center, description: "The cross axis alignment of the row. If not set, center will be used."),
      WidgetOption<MainAxisSize>(parseMainAxisSize, name: "mainAxisSize", defaultValue: MainAxisSize.min, description: "The main axis size of the row. If not set, min will be used."),
    ]).register();

    WidgetOptions(Text, options: [
      WidgetOption<String>((type) => type.toString(), name: "text", defaultValue: "", description: "The text to display in the text widget."),
      WidgetOption<TextStyle?>(parseTextStyle, name: "style", defaultValue: null, description: "The style of the text. If not set, a default style will be used."),
      WidgetOption<TextAlign>(parseTextAlign, name: "textAlign", defaultValue: TextAlign.center, description: "The alignment of the text. If not set, center will be used."),
    ]).register();

  }



  @override
  Widget build(BuildContext context) { //here we actually build the stuff thats being rendered
    return Scaffold( //we use a scaffold bc it lets us easily add components with some presets.
      backgroundColor: Colors.white, //the background color of the scaffold is white, so we can see the widgets clearly

        body: Row( //we use a row to display the node viewer and the root widget side by side
          children: [ //the children of the row are the node viewer and the root widget
            SizedBox(height: screenHeight, width: 0.2 * screenWidth, child: nodeViewer), //the node viewer is on the left side of the screen, taking up 20% of the width
            SizedBox(height: screenHeight, width: 0.8 * screenWidth, child: root.build(context)),// the root widget is the main widget that contains all the other widgets. it is built using the LayoutWidget class.
          ]
        ),

      floatingActionButton: PopupMenuButton(itemBuilder: (context) => [ //this is the floating action button that opens a popup menu with the options to add widgets
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
            leading: Icon(Icons.rectangle_outlined), //a rectangle icon
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
      ],
          onSelected: (value) { //this is called when an item is selected from the popup menu
            switch(value){ //we switch on the value of the selected item
              case "container": addWidget(addContainer(root)); //if the value is container, we add a container widget to the root widget
              case "text": showTextAlertDialog(context); //same for text
              case "row": addWidget(addRow(root)); //and row
              case "ninepatch_button": addWidget(addNinepatchButton(root)); //and nine patch button
            }

            _nodeViewerKey.currentState?.setState(() {}); //this updates the node viewer to show the new widget that was added

          },tooltip: "open widget menu", child: Icon(Icons.add_box_rounded)) //tooltip and + icon
    );
  }

  void showTextAlertDialog(BuildContext context) { //this function shows an alert dialog to enter text for a text widget
    showDialog( //buil-in function to show a dialog
      context: context, //the context is the current context of the widget
      builder: (context) { //the builder is a function that returns the widget that will be displayed in the dialog
        String inputText = ""; //this is the text that will be entered in the text field. we set it to an empty string by default
        return AlertDialog( //the actual dialog widget
          title: Text("Ener your text name here"), //the title of the dialog
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
  void addWidget(LayoutWidget layoutWidget) async{
    setState(() { //we call setState to rebuild the widget tree and show the new widget
      root.addChild(layoutWidget); //we add the new widget to the root widget's children
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
  LayoutWidget addContainer(LayoutWidget? parent) {
    //if a parent is provided, we add the container to the parent
    LayoutWidget widget = LayoutWidget((context, children, properties) { //this is the builder function that builds the widget
      
      WidgetOptions options = WidgetOptions.fromType(Container);

      double screenWidth = MediaQuery.of(context).size.width; //getter for the screen width
      double screenHeight = MediaQuery.of(context).size.height; //and height


      return Container( //the actual container widget that will be displayed
        color: options.getValue("color", properties["color"]), //if the color is provided, we use it, otherwise we use a random color. we defined that above
        width: properties["width"] == null ? (options.getDefaultValue("width") * screenWidth) : options.getValue("width", properties) * screenWidth, //we calculate the width of the container based on the properties provided. if no width is provided, we use the screen width to fully fill the screen
        height: properties["height"] == null ? (options.getDefaultValue("height") * screenHeight) : properties["height"] * screenHeight, //same for the height
        child: children.isNotEmpty ? children.first : null //we only allow one child in a container, so we take the first child from the children list. if no child is provided, we give null
      );
    }, id: 'container${containerIndex++}', //the container id is set to a unique id based on the containerIndex. it also increments the index so that the next container will have a different id
        type: ContainerType.single, //sets the type of the container to single, meaning it can only have one child
        removeFromParent: parent?.removeChild); // we set the removeFromParent function to the parent's removeChild function, so that we can remove the container from the parent if needed

    return widget; //return the created widget
  }

  int rowIndex = 0; //this is used to give the row widgets a unique id
  LayoutWidget addRow(LayoutWidget? parent){ //this is used to add a row widget to the layout
    LayoutWidget widget = LayoutWidget((context, children, properties) { //this is the builder function that builds the widget
      return Row( //the actual row widget that will be displayed
        mainAxisSize: MainAxisSize.min, //the main axis size is set to min, so the row will only take up as much space as its children need
        crossAxisAlignment: CrossAxisAlignment.center, //the cross axis alignment is set to center, so the children will be centered in the row
        mainAxisAlignment: MainAxisAlignment.center, //the main axis alignment is set to center, so the children will be centered in the row
        children: children, //the children of the row are the children passed to the builder function, which are the widgets that will be displayed in the row
      );
    }, id: 'row${rowIndex++}', //same as the container
        type: ContainerType.unlimited, //sets the type of the row to unlimited, meaning it can have multiple children
        removeFromParent: parent?.removeChild); //same as the container

    return widget; //return the created widget
  }


  int textIndex = 0; //this is used to give the text widgets a unique id
  /// Adds a text widget to the layout.
  LayoutWidget addText(String text, LayoutWidget? parent){ //this is used to add a text widget to the layout
    LayoutWidget widget = LayoutWidget((context, children, properties) { //this is the builder function that builds the widget
      return Text(
            text, //the text that will be displayed in the widget
            style: TextStyle(fontSize: 18, color: Colors.black, fontFamily: "gameFont"), //the text style is set to a font size of 18, black color and the pixel art font
            textAlign: TextAlign.center //the text is centered in the widget
      );
    }, id: 'text${textIndex++}', //same as the container and row
        type: ContainerType.sealed, //sealed means that the text widget cannot have any children
        removeFromParent: parent?.removeChild); //same as the container and row

    return widget; //return the created widget
  }


  int ninepatchButtonIndex = 0; //this is used to give the nine patch button widgets a unique id
  LayoutWidget addNinepatchButton(LayoutWidget? parent) {
    LayoutWidget widget = LayoutWidget((context, children, properties) {
      return NinePatchButton(
          text: 'Test Button',
          onPressed: () { print("pressed!"); },
          imageName: 'button_0', //the image name is the name of the nine patch image texture that will be used for the button
          borderX: 3,
          borderY: 3,
          borderX2: 3,
          borderY2: 3,
      );
    }, id: 'ninepatch_button${ninepatchButtonIndex++}',
        type: ContainerType.single,
        removeFromParent: parent?.removeChild);

    return widget;
  }

}