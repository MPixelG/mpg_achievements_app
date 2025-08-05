import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mpg_achievements_app/components/GUI/menuCreator/widget_options.dart';
import 'package:mpg_achievements_app/components/GUI/widgets/nine_patch_widgets.dart';

import '../widgets/nine_patch_button.dart';
import 'button_action.dart';

Map<String, dynamic> defaultFont = {
  "fontSize": 0.01
};



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
      "center left": Alignment.centerLeft,
      "center right": Alignment.centerRight,
    }),
  ]).register();

  WidgetOptions(Row, options: [
    WidgetOption<MainAxisAlignment>(parseMainAxisAlignment, name: "mainAxisAlignment", defaultValue: "MainAxisAlignment.center", description: "The main axis alignment of the row. If not set, center will be used.", options: {
      "start": MainAxisAlignment.start,
      "end": MainAxisAlignment.end,
      "center": MainAxisAlignment.center,
      "space between": MainAxisAlignment.spaceBetween,
      "space around": MainAxisAlignment.spaceAround,
      "space evenly": MainAxisAlignment.spaceEvenly,
    }),
    WidgetOption<CrossAxisAlignment>(parseCrossAxisAlignment, name: "crossAxisAlignment", defaultValue: "CrossAxisAlignment.center", description: "The cross axis alignment of the row. If not set, center will be used.", options: {
      "start": CrossAxisAlignment.start,
      "end": CrossAxisAlignment.end,
      "center": CrossAxisAlignment.center,
      "stretch": CrossAxisAlignment.stretch,
      "baseline": CrossAxisAlignment.baseline,
    }),
    WidgetOption<MainAxisSize>(parseMainAxisSize, name: "mainAxisSize", defaultValue: "MainAxisSize.min", description: "The main axis size of the row. If not set, min will be used.", options: {
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
    WidgetOption<TextStyle>(parseTextStyle, name: "style", defaultValue: defaultFont, description: "The style of the text. If not set, a default style will be used."),
    WidgetOption<TextAlign>(parseTextAlign, name: "textAlign", defaultValue: "TextAlign.center", description: "The alignment of the text. If not set, center will be used.", options: {
      "left": TextAlign.left,
      "right": TextAlign.right,
      "center": TextAlign.center,
      "justify": TextAlign.justify,
      "start": TextAlign.start,
      "end": TextAlign.end,
    }),
  ]).register();


  List<String> loadedTextureNames = NinePatchTexture.getLoadedTextureNames();

  WidgetOptions(NinePatchButton, options: [

    WidgetOption<String>((type) => type.toString(), name: "text", defaultValue: "", description: "The text to display on the button."),
    WidgetOption<ButtonAction>(parseButtonAction, name: "onPressed", defaultValue: DebugButtonAction().toJson(), description: "The function to call when the button is pressed. If not set, it will do nothing."),

    WidgetOption<String>((type) => type.toString(), name: "imageName", defaultValue: "button_0", description: "The name of the nine patch image texture that will be used for the button.", options: {
          for (var value in loadedTextureNames) value : value,
        }
    ),
  ]).register();

  WidgetOptions(Expanded, options: [
    WidgetOption<double>(parseDouble, name: "flex", defaultValue: 1.0, description: "The flex factor of the expanded widget. If not set, 1.0 will be used."), //the flex factor is used to determine how much space the widget should take up in the row or column
  ]).register();

  WidgetOptions.from(WidgetOptions.fromType(Row), Column).register();


  WidgetOptions(FittedBox, options: [
    WidgetOption<Alignment>(parseAlignment, name: "alignment", defaultValue: "Alignment.center", description: "The alignment of the child within the FittedBox. If not set, center will be used.", options: {
      "center": Alignment.center,
      "top left": Alignment.topLeft,
      "top right": Alignment.topRight,
      "bottom left": Alignment.bottomLeft,
      "bottom right": Alignment.bottomRight,
      "top center": Alignment.topCenter,
      "bottom center": Alignment.bottomCenter,
    }),
    WidgetOption<BoxFit>(parseBoxFit, name: "fit", defaultValue: "BoxFit.contain", description: "The fit of the child within the FittedBox. If not set, contain will be used.", options: {
      "fill": BoxFit.fill,
      "contain": BoxFit.contain,
      "cover": BoxFit.cover,
      "fit width": BoxFit.fitWidth,
      "fit height": BoxFit.fitHeight,
      "none": BoxFit.none,
    }),
  ]).register();


  WidgetOptions(Transform, options: [
    WidgetOption<double>(parseDouble, name: "rotation", defaultValue: 0.0, description: "The rotation of the widget in radians. If not set, no rotation will be applied."),
    WidgetOption<double>(parseDouble, name: "scale", defaultValue: 1.0, description: "The scale of the widget. If not set, no scaling will be applied."),
    WidgetOption<Alignment>(parseAlignment, name: "alignment", defaultValue: "Alignment.center", description: "The alignment of the child within the Transform. If not set, center will be used.", options: {
      "center": Alignment.center,
      "top left": Alignment.topLeft,
      "top right": Alignment.topRight,
      "bottom left": Alignment.bottomLeft,
      "bottom right": Alignment.bottomRight,
      "top center": Alignment.topCenter,
      "bottom center": Alignment.bottomCenter,
    }),
  ]).register();

  WidgetOptions(Opacity, options: [
    WidgetOption<double>(parseDouble, name: "opacity", defaultValue: 0.5, description: "The opacity of the widget. If not set, 0.5 will be used."),
  ]).register();

  WidgetOptions(Card, options: [
    WidgetOption<Color>(parseColor, name: "color", defaultValue: Colors.white, description: "The color of the card. If not set, white will be used."),
    WidgetOption<EdgeInsetsGeometry?>(parseEdgeInsets, name: "margin", defaultValue: EdgeInsets.all(8.0), description: "The margin of the card. If not set, 8.0 will be used."),
  ]).register();

  WidgetOptions(GridView, options: [
    WidgetOption<int>(parseInt, name: "crossAxisCount", defaultValue: 2, description: "The number of columns in the grid. If not set, 2 will be used."),
    WidgetOption<double>(parseDouble, name: "childAspectRatio", defaultValue: 1.0, description: "The aspect ratio of the children in the grid. If not set, 1.0 will be used."),
  ]).register();

  WidgetOptions(Stack, options: []).register(); //no options for stack, because it is just a container for other widgets


  WidgetOptions(Image, options: [
    WidgetOption<String>((type) => type.toString(), name: "path", defaultValue: ""),
    WidgetOption<double>(parseDouble, name: "width", defaultValue: 0.1),
    WidgetOption<double>(parseDouble, name: "height", defaultValue: 0.1),
    WidgetOption<Alignment>(parseAlignment, name: "alignment", defaultValue: "Alignment.center", options: {
  "center": Alignment.center,
  "top left": Alignment.topLeft,
  "top right": Alignment.topRight,
  "bottom left": Alignment.bottomLeft,
  "bottom right": Alignment.bottomRight,
  "top center": Alignment.topCenter,
  "bottom center": Alignment.bottomCenter,
  }),
  ]).register();


  WidgetOptions(InteractiveViewer, options: [
    WidgetOption<bool>(parseBoolean, name: "panEnabled", defaultValue: true),
    WidgetOption<bool>(parseBoolean, name: "scaleEnabled", defaultValue: true),
    WidgetOption<Alignment>(parseAlignment, name: "alignment", defaultValue: "Alignment.center", options: {
      "center": Alignment.center,
      "top left": Alignment.topLeft,
      "top right": Alignment.topRight,
      "bottom left": Alignment.bottomLeft,
      "bottom right": Alignment.bottomRight,
      "top center": Alignment.topCenter,
      "bottom center": Alignment.bottomCenter,
    }),
    WidgetOption<PanAxis>(parsePanAxis, name: "panAxis", defaultValue: "PanAxis.free", options: {
      "free": PanAxis.free,
      "vertical": PanAxis.vertical,
      "horizontal": PanAxis.horizontal,
      "aligned": PanAxis.aligned
    }),
    WidgetOption<double>(parseDouble, name: "minScale", defaultValue: 0.2),
    WidgetOption<double>(parseDouble, name: "maxScale", defaultValue: 8.0),
  ]).register();


  WidgetOptions(SingleChildScrollView, options: [

    WidgetOption<Axis>(parseAxis, name: "axis", defaultValue: "Axis.vertical", options: {
      "horizontal": Axis.horizontal,
      "vertical": Axis.vertical
    })

  ]).register();















}