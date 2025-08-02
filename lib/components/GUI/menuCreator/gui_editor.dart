import 'package:flame/extensions.dart';
import 'package:flutter/material.dart';
import 'package:mpg_achievements_app/components/GUI/menuCreator/button_action.dart';
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

    if(WidgetOptions.isRegistered(Container)) return; //if the widget options for the container are already registered, we return and do not register them again. this is to prevent duplicate registrations.

    WidgetOptions(Container, options: [
      WidgetOption<double>(parseDouble, name: "width", defaultValue: 0.1, description: "The width of the container as a percentage of the screen width"),
      WidgetOption<double>(parseDouble, name: "height", defaultValue: 0.1, description: "The height of the container as a percentage of the screen height"),
      WidgetOption<Color>(parseColor, name: "color", defaultValue: null, description: "The color of the container."),
      WidgetOption<EdgeInsetsGeometry?>(parseEdgeInsets, name: "padding", defaultValue: null, description: "The padding of the container. If not set, no padding will be used."),
      WidgetOption<EdgeInsetsGeometry?>(parseEdgeInsets, name: "margin", defaultValue: null, description: "The margin of the container. If not set, no margin will be used."),
      WidgetOption<Alignment?>(parseAlignment, name: "alignment", defaultValue: null, description: "The alignment of the container. If not set, center will be used.", options: {
        "default": null,
        "center": Alignment.center,
        "top left": Alignment.topLeft,
        "top right": Alignment.topRight,
        "bottom left": Alignment.bottomLeft,
        "bottom right": Alignment.bottomRight,
        "top center": Alignment.topCenter,
        "bottom center": Alignment.bottomCenter,
      }),
    ]).register();

    WidgetOptions(Row, options: [
      WidgetOption<MainAxisAlignment>(parseMainAxisAlignment, name: "mainAxisAlignment", defaultValue: MainAxisAlignment.center, description: "The main axis alignment of the row. If not set, center will be used.", options: {
          "start": MainAxisAlignment.start,
          "end": MainAxisAlignment.end,
          "center": MainAxisAlignment.center,
          "space between": MainAxisAlignment.spaceBetween,
          "space around": MainAxisAlignment.spaceAround,
          "space evenly": MainAxisAlignment.spaceEvenly,
        }),
      WidgetOption<CrossAxisAlignment>(parseCrossAxisAlignment, name: "crossAxisAlignment", defaultValue: CrossAxisAlignment.center, description: "The cross axis alignment of the row. If not set, center will be used.", options: {
          "start": CrossAxisAlignment.start,
          "end": CrossAxisAlignment.end,
          "center": CrossAxisAlignment.center,
          "stretch": CrossAxisAlignment.stretch,
          "baseline": CrossAxisAlignment.baseline,
        }),
      WidgetOption<MainAxisSize>(parseMainAxisSize, name: "mainAxisSize", defaultValue: MainAxisSize.min, description: "The main axis size of the row. If not set, min will be used.", options: {
          "min": MainAxisSize.min,
          "max": MainAxisSize.max,
        }),
    ]).register();

    WidgetOptions(Positioned, options: [
      WidgetOption<double>(parseDouble, name: "left", defaultValue: 0.0, description: "The left position of the widget in the stack."),
      WidgetOption<double>(parseDouble, name: "top", defaultValue: 0.0, description: "The top position of the widget in the stack."),
      WidgetOption<double>(parseDouble, name: "right", defaultValue: 0.0, description: "The right position of the widget in the stack."),
      WidgetOption<double>(parseDouble, name: "bottom", defaultValue: 0.0, description: "The bottom position of the widget in the stack."),
    ]).register();


    WidgetOptions(Text, options: [
      WidgetOption<String>((type) => type.toString(), name: "text", defaultValue: "", description: "The text to display in the text widget."),
      WidgetOption<TextStyle?>(parseTextStyle, name: "style", defaultValue: null, description: "The style of the text. If not set, a default style will be used."),
      WidgetOption<TextAlign>(parseTextAlign, name: "textAlign", defaultValue: TextAlign.center, description: "The alignment of the text. If not set, center will be used."),
    ]).register();


    WidgetOptions(NinePatchButton, options: [

      WidgetOption<String>((type) => type.toString(), name: "text", defaultValue: "", description: "The text to display on the button."),
      WidgetOption<ButtonAction>(parseButtonAction, name: "onPressed", defaultValue: DebugButtonAction(), description: "The function to call when the button is pressed. If not set, it will do nothing."),

      WidgetOption<String>((type) => type.toString(), name: "imageName", defaultValue: "button_0", description: "The name of the nine patch image texture that will be used for the button."),
    ]).register();

    WidgetOptions(Expanded, options: [
      WidgetOption<double>(parseDouble, name: "flex", defaultValue: 1.0, description: "The flex factor of the expanded widget. If not set, 1.0 will be used."), //the flex factor is used to determine how much space the widget should take up in the row or column
    ]).register();

    WidgetOptions.from(WidgetOptions.fromType(Row), Column).register();

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
                LayoutWidget? parent = getNearestFlexRecursive(root); //we get the nearest stack widget to add the expanded widget to
                addWidget(addExpanded(parent), root: parent);
              }
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


  int containerIndex = 0; //this is used to give the container widgets a unique id
  /// Adds a container widget to the layout.
  /// The container will fill a percentage of the screen size based on the properties provided.
  /// If no properties are provided, it defaults to 30% of the screen width and height.
  /// The container will have a random color from the Colors.primaries list.
  LayoutWidget addContainer(LayoutWidget? parent) {
    //if a parent is provided, we add the container to the parent
    LayoutWidget widget = LayoutWidget((context, children, properties) { //this is the builder function that builds the widget
      
      WidgetOptions options = WidgetOptions.fromType(Container); //we get the widget options for the container widget, which defines the properties that can be set in the GUI editor

      RenderBox? currentParentBox = context.findRenderObject() as RenderBox?;

      double availableWidth = currentParentBox == null ? MediaQuery.of(context).size.width : (currentParentBox.size.width); //we get the available width of the parent widget, if no parent is provided, we use the screen width
      double availableHeight = currentParentBox == null ? MediaQuery.of(context).size.height : (currentParentBox.size.height); //same for the height

      properties["width"] ??= options.getDefaultValue("width"); //we set the width property to the default value defined in the widget options, so that we can use it in the widget
      properties["height"] ??= options.getDefaultValue("height"); //same for the height
      properties["color"] ??= options.getDefaultValue("color"); //we set the color property to the default value defined in the widget options, so that we can use it in the widget
      properties["padding"] ??= options.getDefaultValue("padding"); //we set the padding property to the default value defined in the widget options, so that we can use it in the widget
      properties["margin"] ??= options.getDefaultValue("margin"); //we set the margin property to the default value defined in the widget options, so that we can use it in the widget
      properties["alignment"] ??= options.getDefaultValue("alignment"); //we set the alignment


      return Container( //the actual container widget that will be displayed
        color: options.getValue("color", properties["color"]), //if the color is provided, we use it, otherwise we use a random color. we defined that above
        width: options.getValue("width", properties["width"]) * availableWidth, //the width of the container is set to a percentage of the screen width, if no width is provided, we use the default value defined in the widget options
        height: options.getValue("height", properties["height"]) * availableHeight, //same for the height
        padding: options.getValue("padding", properties["padding"]), //the padding of the container is set to the value provided in the properties, if no padding is provided, we use the default value defined in the widget options
        margin: options.getValue("margin", properties["margin"]), //the margin of the container is set to the value provided in the properties, if no margin is provided, we use the default value defined in the widget options
        alignment: options.getValue("alignment", properties["alignment"]), //the alignment of the container is set to the value provided in the properties, if no alignment is provided, we use the default value defined in the widget options
        child: children.isNotEmpty ? children.first : null //we only allow one child in a container, so we take the first child from the children list. if no child is provided, we give null
      );
    }, id: 'container${containerIndex++}', //the container id is set to a unique id based on the containerIndex. it also increments the index so that the next container will have a different id
        type: ContainerType.single, //sets the type of the container to single, meaning it can only have one child
        removeFromParent: parent?.removeChild, parent: parent, widgetType: Container); // we set the removeFromParent function to the parent's removeChild function, so that we can remove the container from the parent if needed

    return widget; //return the created widget
  }

  int rowIndex = 0; //this is used to give the row widgets a unique id
  LayoutWidget addRow(LayoutWidget? parent){ //this is used to add a row widget to the layout
    LayoutWidget widget = LayoutWidget((context, children, properties) { //this is the builder function that builds the widget

      WidgetOptions options = WidgetOptions.fromType(Row);


      properties["mainAxisSize"] ??= options.getDefaultValue("mainAxisSize"); //we set the mainAxisSize property to the default value defined in the widget options, so that we can use it in the widget
      properties["crossAxisAlignment"] ??= options.getDefaultValue("crossAxisAlignment"); //we set the crossAxisAlignment property to the default value defined in the widget options, so that we
      properties["mainAxisAlignment"] ??= options.getDefaultValue("mainAxisAlignment"); //we set the mainAxisAlignment property to the default value defined in the widget options, so that we can use it in the widget


      return Row( //the actual row widget that will be displayed
        mainAxisSize: options.getValue("mainAxisSize", properties["mainAxisSize"]), //the main axis size is set to min, so the row will only take up as much space as its children need
        crossAxisAlignment: options.getValue("crossAxisAlignment", properties["crossAxisAlignment"]), //the cross axis alignment is set to center, so the children will be centered in the row
        mainAxisAlignment: options.getValue("mainAxisAlignment", properties["mainAxisAlignment"]), //the main axis alignment is set to center, so the children will be centered in the row
        children: children, //the children of the row are the children passed to the builder function, which are the widgets that will be displayed in the row
      );
    }, id: 'row${rowIndex++}', //same as the container
        type: ContainerType.unlimited, //sets the type of the row to unlimited, meaning it can have multiple children
        removeFromParent: parent?.removeChild, parent: parent, widgetType: Row); //same as the container

    return widget; //return the created widget
  }


  int columnIndex = 0; //this is used to give the row widgets a unique id
  LayoutWidget addColumn(LayoutWidget? parent){ //this is used to add a row widget to the layout
    LayoutWidget widget = LayoutWidget((context, children, properties) { //this is the builder function that builds the widget

      WidgetOptions options = WidgetOptions.fromType(Row); //a Row has the same options as a Column, so we can use the same widget options class


      properties["mainAxisSize"] ??= options.getDefaultValue("mainAxisSize"); //we set the mainAxisSize property to the default value defined in the widget options, so that we can use it in the widget
      properties["crossAxisAlignment"] ??= options.getDefaultValue("crossAxisAlignment"); //we set the crossAxisAlignment property to the default value defined in the widget options, so that we
      properties["mainAxisAlignment"] ??= options.getDefaultValue("mainAxisAlignment"); //we set the mainAxisAlignment property to the default value defined in the widget options, so that we can use it in the widget


      return Column( //the actual row widget that will be displayed
        mainAxisSize: options.getValue("mainAxisSize", properties["mainAxisSize"]), //the main axis size is set to min, so the row will only take up as much space as its children need
        crossAxisAlignment: options.getValue("crossAxisAlignment", properties["crossAxisAlignment"]), //the cross axis alignment is set to center, so the children will be centered in the row
        mainAxisAlignment: options.getValue("mainAxisAlignment", properties["mainAxisAlignment"]), //the main axis alignment is set to center, so the children will be centered in the row
        children: children, //the children of the row are the children passed to the builder function, which are the widgets that will be displayed in the row
      );
    }, id: 'column${columnIndex++}', //same as the container
        type: ContainerType.unlimited, //sets the type of the row to unlimited, meaning it can have multiple children
        removeFromParent: parent?.removeChild, parent: parent, widgetType: Column); //same as the container

    return widget; //return the created widget
  }

  int stackIndex = 0; //this is used to give the stack widgets a unique id
  LayoutWidget addStack(LayoutWidget? parent) {
    LayoutWidget widget = LayoutWidget((context, children, properties) { //this is the builder function that builds the widget
      return Stack( //the actual stack widget that will be displayed
        children: children, //the children of the stack are the children passed to the builder function, which are the widgets that will be displayed in the stack
      );
    }, id: 'stack${stackIndex++}', //same as the container
        type: ContainerType.unlimited, //sets the type of the stack to unlimited, so it can have multiple children
        removeFromParent: parent?.removeChild, parent: parent, widgetType: Stack); //same as the container

    return widget; //return the created widget
  }

  int positionedIndex = 0; //this is used to give the positioned widgets a unique id
  LayoutWidget? addPositioned(LayoutWidget? parent) { //this is used to add a positioned widget to the layout
    if(parent == null || !parent.canAddChild) return null;
    LayoutWidget widget = LayoutWidget((context, children, properties) { //this is the builder function that builds the widget

      WidgetOptions options = WidgetOptions.fromType(Positioned);


      properties["left"] ??= options.getDefaultValue("left"); //we set the left property to the default value defined in the widget options, so that we can use it in the widget
      properties["top"] ??= options.getDefaultValue("top"); //we set the top property to the default value defined in the widget options, so that we can use it in the widget
      properties["right"] ??= options.getDefaultValue("right"); //we set the right property to the default value defined in the widget options, so that we can use it in the widget
      properties["bottom"] ??= options.getDefaultValue("bottom"); //we set the bottom property to the default value defined in the widget options, so that we can use it in the widget

      return Positioned( //the actual positioned widget that will be displayed
        left: options.getValue("left", properties["left"]) * screenWidth, //the left position of the widget in the stack
        top: options.getValue("top", properties["top"]) * screenHeight, //the top position of the widget in the stack
        right: options.getValue("right", properties["right"]) * screenWidth, //the right position of the widget in the stack
        bottom: options.getValue("bottom", properties["bottom"]) * screenHeight, //the bottom position of the widget in the stack
        child: children.isNotEmpty ? children.first : Container(), //we only allow one child in a positioned widget, so we take the first child from the children list. if no child is provided, we give null
      );
    }, id: 'positioned${positionedIndex++}', //same as the container and row
        type: ContainerType.single, //sealed means that this widget cannot have any children
        removeFromParent: parent.removeChild, parent: parent, widgetType: Positioned, dropCondition: (other) => other.widgetType is Stack,); //same as the container and row

    return widget; //return the created widget
  }

  LayoutWidget? addExpanded(LayoutWidget? parent) { //this is used to add an expanded widget to the layout
    if(parent == null || !parent.canAddChild) return null; //if the parent is null or cannot have children, we return null

    LayoutWidget widget = LayoutWidget((context, children, properties) { //this is the builder function that builds the widget

      WidgetOptions options = WidgetOptions.fromType(Expanded);

      properties["flex"] ??= options.getDefaultValue("flex"); //we set the flex property to the default value defined in the widget options, so that we can use it in the widget

      return Expanded( //the actual expanded widget that will be displayed
        flex: options.getValue("flex", properties["flex"]).toInt(), //the flex factor of the expanded widget
        child: children.isNotEmpty ? children.first : Container(), //we only allow one child in an expanded widget, so we take the first child from the children list. if no child is provided, we give null
      );
    }, id: 'expanded${containerIndex++}', //same as the container and row
        type: ContainerType.single, //sealed means that this widget cannot have any children
        removeFromParent: parent.removeChild, parent: parent, widgetType: Expanded, dropCondition: (other) => other.widgetType == Row || other.widgetType == Column); //same as the container and row

    return widget; //return the created widget
  }




  int textIndex = 0; //this is used to give the text widgets a unique id
  /// Adds a text widget to the layout.
  LayoutWidget addText(String text, LayoutWidget? parent){ //this is used to add a text widget to the layout
    LayoutWidget widget = LayoutWidget((context, children, properties) { //this is the builder function that builds the widget

      WidgetOptions options = WidgetOptions.fromType(Text);


      properties["text"] ??= text; //we set the text property to the text that was passed to the function, so that we can use it in the widget

      return Text(
            options.getValue("text", properties["text"]), //the text that will be displayed in the widget
            style: options.getValue("style", properties["style"]), //the text style is set to a font size of 18, black color and the pixel art font
            textAlign: options.getValue("textAlign", properties["textAlign"]) //the text is centered in the widget
      );
    }, id: 'text${textIndex++}', //same as the container and row
        type: ContainerType.sealed, //sealed means that the text widget cannot have any children
        removeFromParent: parent?.removeChild, parent: parent, widgetType: Text); //same as the container and row

    return widget; //return the created widget
  }


  int ninepatchButtonIndex = 0; //this is used to give the nine patch button widgets a unique id
  LayoutWidget addNinepatchButton(LayoutWidget? parent) {
    LayoutWidget widget = LayoutWidget((context, children, properties) {

      WidgetOptions options = WidgetOptions.fromType(NinePatchButton);

      properties["text"] ??= options.getDefaultValue("text");
      properties["onPressed"] ??= options.getDefaultValue("onPressed");
      properties["imageName"] ??= options.getDefaultValue("imageName");


      return NinePatchButton(
          text: options.getValue("text", properties["text"]), //the text that will be displayed on the button
          onPressed: options.getValue("onPressed", properties["onPressed"]).press, //the onPressed function is set to the action that was passed to the function, so that we can use it in the widget
          textureName: options.getValue("imageName", properties["imageName"]) //the image name is set to the image name that was passed to the function, so that we can use it in the widget
      );
    }, id: 'ninepatch_button${ninepatchButtonIndex++}',
        type: ContainerType.single,
        removeFromParent: parent?.removeChild, parent: parent, widgetType: NinePatchButton);
    return widget;
  }

}