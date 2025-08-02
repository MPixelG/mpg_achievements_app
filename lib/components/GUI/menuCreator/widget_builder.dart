import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mpg_achievements_app/components/GUI/menuCreator/widget_options.dart';

import 'package:vector_math/vector_math_64.dart' as vm64;

import '../widgets/nine_patch_button.dart';
import 'button_action.dart';
import 'layout_widget.dart';


int containerIndex = 0; //this is used to give the container widgets a unique id
/// Adds a container widget to the layout.
/// The container will fill a percentage of the screen size based on the properties provided.
/// If no properties are provided, it defaults to 30% of the screen width and height.
/// The container will have a random color from the Colors.primaries list.






LayoutWidget addContainer(LayoutWidget? parent, {Map<String, dynamic>? properties}) {

  //if a parent is provided, we add the container to the parent
  LayoutWidget widget = LayoutWidget((context, children, properties) { //this is the builder function that builds the widget

    WidgetOptions options = WidgetOptions.fromType(Container); //we get the widget options for the container widget, which defines the properties that can be set in the GUI editor


    double availableWidth =MediaQuery.of(context).size.width;//we get the available width of the parent widget, if no parent is provided, we use the screen width
    double availableHeight =MediaQuery.of(context).size.height;

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
      removeFromParent: parent?.removeChild, parent: parent, widgetType: Container, properties: properties); // we set the removeFromParent function to the parent's removeChild function, so that we can remove the container from the parent if needed

  return widget; //return the created widget
}

int rowIndex = 0; //this is used to give the row widgets a unique id
LayoutWidget addRow(LayoutWidget? parent, {Map<String, dynamic>? properties}){ //this is used to add a row widget to the layout
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
      removeFromParent: parent?.removeChild, parent: parent, widgetType: Row, properties: properties); //same as the container

  return widget; //return the created widget
}


int columnIndex = 0; //this is used to give the row widgets a unique id
LayoutWidget addColumn(LayoutWidget? parent, {Map<String, dynamic>? properties}){ //this is used to add a row widget to the layout
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
      removeFromParent: parent?.removeChild, parent: parent, widgetType: Column, properties: properties); //same as the container

  return widget; //return the created widget
}

int stackIndex = 0; //this is used to give the stack widgets a unique id
LayoutWidget addStack(LayoutWidget? parent, {Map<String, dynamic>? properties}) {
  LayoutWidget widget = LayoutWidget((context, children, properties) { //this is the builder function that builds the widget
    return Stack( //the actual stack widget that will be displayed
      children: children, //the children of the stack are the children passed to the builder function, which are the widgets that will be displayed in the stack
    );
  }, id: 'stack${stackIndex++}', //same as the container
      type: ContainerType.unlimited, //sets the type of the stack to unlimited, so it can have multiple children
      removeFromParent: parent?.removeChild, parent: parent, widgetType: Stack, properties: properties); //same as the container

  return widget; //return the created widget
}

int positionedIndex = 0; //this is used to give the positioned widgets a unique id
LayoutWidget? addPositioned(LayoutWidget? parent, {Map<String, dynamic>? properties}) { //this is used to add a positioned widget to the layout
  if(parent == null || !parent.canAddChild) return null;
  LayoutWidget widget = LayoutWidget((context, children, properties) { //this is the builder function that builds the widget

    WidgetOptions options = WidgetOptions.fromType(Positioned);

    double screenWidth = MediaQuery.of(context).size.width; //getter for the screen width, so we can use it to calculate the size of the widgets
    double screenHeight = MediaQuery.of(context).size.width; //same for the width


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
    removeFromParent: parent.removeChild, parent: parent, widgetType: Positioned, dropCondition: (other) => other.widgetType is Stack, properties: properties); //same as the container and row

  return widget; //return the created widget
}

int expandedIndex = 0; //this is used to give the expanded widgets a unique id
LayoutWidget? addExpanded(LayoutWidget? parent, {Map<String, dynamic>? properties}) { //this is used to add an expanded widget to the layout
  if(parent == null || !parent.canAddChild) return null; //if the parent is null or cannot have children, we return null

  LayoutWidget widget = LayoutWidget((context, children, properties) { //this is the builder function that builds the widget

    WidgetOptions options = WidgetOptions.fromType(Expanded);

    properties["flex"] ??= options.getDefaultValue("flex"); //we set the flex property to the default value defined in the widget options, so that we can use it in the widget

    return Expanded( //the actual expanded widget that will be displayed
      flex: options.getValue("flex", properties["flex"]).toInt(), //the flex factor of the expanded widget
      child: children.isNotEmpty ? children.first : Container(), //we only allow one child in an expanded widget, so we take the first child from the children list. if no child is provided, we give null
    );
  }, id: 'expanded${expandedIndex++}', //same as the container and row
      type: ContainerType.single, //sealed means that this widget cannot have any children
      removeFromParent: parent.removeChild, parent: parent, widgetType: Expanded, dropCondition: (other) => other.widgetType == Row || other.widgetType == Column, properties: properties); //same as the container and row

  return widget; //return the created widget
}




int textIndex = 0; //this is used to give the text widgets a unique id
/// Adds a text widget to the layout.
LayoutWidget addText(String text, LayoutWidget? parent, {Map<String, dynamic>? properties}){ //this is used to add a text widget to the layout
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
      removeFromParent: parent?.removeChild, parent: parent, widgetType: Text, properties: properties); //same as the container and row

  return widget; //return the created widget
}


int ninepatchButtonIndex = 0; //this is used to give the nine patch button widgets a unique id
LayoutWidget addNinepatchButton(LayoutWidget? parent, {Map<String, dynamic>? properties}) {
  LayoutWidget widget = LayoutWidget((context, children, properties) {

    WidgetOptions options = WidgetOptions.fromType(NinePatchButton);

    properties["text"] ??= options.getDefaultValue("text");
    properties["onPressed"] ??= options.getDefaultValue("onPressed");
    properties["imageName"] ??= options.getDefaultValue("imageName");


    return NinePatchButton(
        text: options.getValue("text", properties["text"]), //the text that will be displayed on the button
        onPressed: () => options.getValue("onPressed", properties["onPressed"]).press(context), //the onPressed function is set to the action that was passed to the function, so that we can use it in the widget
        textureName: options.getValue("imageName", properties["imageName"]) //the image name is set to the image name that was passed to the function, so that we can use it in the widget
    );
  }, id: 'ninepatch_button${ninepatchButtonIndex++}',
      type: ContainerType.single,
      removeFromParent: parent?.removeChild, parent: parent, widgetType: NinePatchButton, properties: properties);
  return widget;
}


LayoutWidget addFittedBox(LayoutWidget? parent, {Map<String, dynamic>? properties}) {
  LayoutWidget widget = LayoutWidget((context, children, properties) {

    WidgetOptions options = WidgetOptions.fromType(FittedBox);

    properties["alignment"] ??= options.getDefaultValue("alignment");
    properties["fit"] ??= options.getDefaultValue("fit");

    return FittedBox(
      alignment: options.getValue("alignment", properties["alignment"]),
      fit: options.getValue("fit", properties["fit"]),
      child: children.isNotEmpty ? children.first : Container(),
    );
  }, id: 'fitted_box', type: ContainerType.single,
      removeFromParent: parent?.removeChild, parent: parent, widgetType: FittedBox, properties: properties);
  return widget;
}

LayoutWidget addTransform(LayoutWidget? parent, {Map<String, dynamic>? properties}) {
  LayoutWidget widget = LayoutWidget((context, children, properties) {

    WidgetOptions options = WidgetOptions.fromType(Transform);

    properties["rotation"] ??= options.getDefaultValue("rotation");
    properties["scale"] ??= options.getDefaultValue("scale");
    properties["alignment"] ??= options.getDefaultValue("alignment");

    return Transform(
      alignment: options.getValue("alignment", properties["alignment"]),
      transform: vm64.Matrix4.identity()
        ..rotateZ(options.getValue("rotation", properties["rotation"]))
        ..scale(options.getValue("scale", properties["scale"])),
      child: children.isNotEmpty ? children.first : Container(),
    );
  }, id: 'transform', type: ContainerType.single,
      removeFromParent: parent?.removeChild, parent: parent, widgetType: Transform, properties: properties);
  return widget;
}


LayoutWidget addOpacity(LayoutWidget? parent, {Map<String, dynamic>? properties}) {
  LayoutWidget widget = LayoutWidget((context, children, properties) {

    WidgetOptions options = WidgetOptions.fromType(Opacity);

    properties["opacity"] ??= options.getDefaultValue("opacity");

    return Opacity(
      opacity: options.getValue("opacity", properties["opacity"]),
      child: children.isNotEmpty ? children.first : Container(),
    );
  }, id: 'opacity', type: ContainerType.single,
      removeFromParent: parent?.removeChild, parent: parent, widgetType: Opacity, properties: properties);
  return widget;
}

LayoutWidget addCard(LayoutWidget? parent, {Map<String, dynamic>? properties}) {
  LayoutWidget widget = LayoutWidget((context, children, properties) {

    WidgetOptions options = WidgetOptions.fromType(Card);

    properties["color"] ??= options.getDefaultValue("color");
    properties["margin"] ??= options.getDefaultValue("margin");

    return Card(
      color: options.getValue("color", properties["color"]),
      margin: options.getValue("margin", properties["margin"]),
      child: children.isNotEmpty ? children.first : Container(),
    );
  }, id: 'card', type: ContainerType.single,
      removeFromParent: parent?.removeChild, parent: parent, widgetType: Card, properties: properties);
  return widget;
}

LayoutWidget addGridView(LayoutWidget? parent, {Map<String, dynamic>? properties}) {
  LayoutWidget widget = LayoutWidget((context, children, properties) {

    WidgetOptions options = WidgetOptions.fromType(GridView);

    properties["crossAxisCount"] ??= options.getDefaultValue("crossAxisCount");
    properties["childAspectRatio"] ??= options.getDefaultValue("childAspectRatio");

    return GridView.count(
      crossAxisCount: options.getValue("crossAxisCount", properties["crossAxisCount"]),
      childAspectRatio: options.getValue("childAspectRatio", properties["childAspectRatio"]),
      children: children,
    );
  }, id: 'grid_view', type: ContainerType.unlimited,
      removeFromParent: parent?.removeChild, parent: parent, widgetType: GridView, properties: properties);
  return widget;
}