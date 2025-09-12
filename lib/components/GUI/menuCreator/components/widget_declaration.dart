import 'package:flame/components.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mpg_achievements_app/components/GUI/menuCreator/components/dependencyViewer/layout_widget.dart';
import 'package:mpg_achievements_app/components/GUI/menuCreator/components/propertyEditor/button_action.dart';
import 'package:mpg_achievements_app/components/GUI/menuCreator/options/widget_options.dart';
import 'package:mpg_achievements_app/components/GUI/widgets/nine_patch_button.dart';
import 'package:vector_math/vector_math_64.dart' as vm64;

import '../../widgets/nine_patch_widgets.dart';
import '../options/widget_builder.dart';

class WidgetDeclaration {
  static Set<WidgetDeclaration> declarationCache = {};

  Type widgetType;
  String id;
  String displayName;
  Icon icon;

  LayoutWidget? Function(
    LayoutWidget? parent, {
    Map<String, dynamic>? properties,
  })
  builder;

  WidgetDeclaration(
    this.widgetType,
    this.id,
    this.displayName,
    this.icon,
    WidgetOptions options,
    this.builder,
  ) {
    print("added");

    declarationCache.add(this);
  }
  @override
  int get hashCode =>
      Object.hashAll([widgetType, id, displayName, icon, builder]);

  @override
  bool operator ==(Object other) {
    return this == other;
  }

  @override
  String toString() {
    return displayName;
  }
}

void declareWidgets() {
  Map<String, dynamic> defaultFont = {"fontSize": 0.01};

  WidgetDeclaration(
    Container,
    "Container",
    "Container",
    Icon(Icons.check_box_outline_blank),
    WidgetOptions(
      Container,
      options: [
        WidgetOption<double>(
          parseDouble,
          name: "width",
          defaultValue: 0.1,
          description:
              "The width of the container as a percentage of the screen width",
        ),
        WidgetOption<double>(
          parseDouble,
          name: "height",
          defaultValue: 0.1,
          description:
              "The height of the container as a percentage of the screen height",
        ),
        WidgetOption<Color>(
          parseColor,
          name: "color",
          defaultValue: null,
          description: "The color of the container.",
        ),
        WidgetOption<EdgeInsetsGeometry?>(
          parseEdgeInsets,
          name: "padding",
          defaultValue: null,
          description:
              "The padding of the container. If not set, no padding will be used.",
        ),
        WidgetOption<EdgeInsetsGeometry?>(
          parseEdgeInsets,
          name: "margin",
          defaultValue: null,
          description:
              "The margin of the container. If not set, no margin will be used.",
        ),
        WidgetOption<Alignment?>(
          parseAlignment,
          name: "alignment",
          defaultValue: null,
          description:
              "The alignment of the container. If not set, center will be used.",
          options: {
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
          },
        ),
      ],
    )..register(),
    (LayoutWidget? parent, {Map<String, dynamic>? properties}) {
      //if a parent is provided, we add the container to the parent
      LayoutWidget widget = LayoutWidget(
        (context, children, properties) {
          //this is the builder function that builds the widget

          WidgetOptions options = WidgetOptions.fromType(
            Container,
          ); //we get the widget options for the container widget, which defines the properties that can be set in the GUI editor

          double availableWidth = MediaQuery.of(context)
              .size
              .width; //we get the available width of the parent widget, if no parent is provided, we use the screen width
          double availableHeight = MediaQuery.of(context).size.height;

          properties["width"] ??= options.getDefaultValue(
            "width",
          ); //we set the width property to the default value defined in the widget options, so that we can use it in the widget
          properties["height"] ??= options.getDefaultValue(
            "height",
          ); //same for the height
          properties["color"] ??= options.getDefaultValue(
            "color",
          ); //we set the color property to the default value defined in the widget options, so that we can use it in the widget
          properties["padding"] ??= options.getDefaultValue(
            "padding",
          ); //we set the padding property to the default value defined in the widget options, so that we can use it in the widget
          properties["margin"] ??= options.getDefaultValue(
            "margin",
          ); //we set the margin property to the default value defined in the widget options, so that we can use it in the widget
          properties["alignment"] ??= options.getDefaultValue(
            "alignment",
          ); //we set the alignment

          return Container(
            //the actual container widget that will be displayed
            color: options.getValue(
              "color",
              properties["color"],
            ), //if the color is provided, we use it, otherwise we use a random color. we defined that above
            width:
                options.getValue("width", properties["width"]) *
                availableWidth, //the width of the container is set to a percentage of the screen width, if no width is provided, we use the default value defined in the widget options
            height:
                options.getValue("height", properties["height"]) *
                availableHeight, //same for the height
            padding: convertToAbsolute(
              options.getValue("padding", properties["padding"]),
              availableWidth,
              availableHeight,
            ), //the padding of the container is set to the value provided in the properties, if no padding is provided, we use the default value defined in the widget options
            margin: convertToAbsolute(
              options.getValue("margin", properties["margin"]),
              availableWidth,
              availableHeight,
            ), //the margin of the container is set to the value provided in the properties, if no margin is provided, we use the default value defined in the widget options
            alignment: options.getValue(
              "alignment",
              properties["alignment"],
            ), //the alignment of the container is set to the value provided in the properties, if no alignment is provided, we use the default value defined in the widget options
            child: children.isNotEmpty
                ? children.first
                : null, //we only allow one child in a container, so we take the first child from the children list. if no child is provided, we give null
          );
        },
        id: 'container${containerIndex++}', //the container id is set to a unique id based on the containerIndex. it also increments the index so that the next container will have a different id
        type: ContainerType
            .single, //sets the type of the container to single, meaning it can only have one child
        removeFromParent: parent?.removeChild,
        parent: parent,
        widgetType: Container,
        properties: properties,
      ); // we set the removeFromParent function to the parent's removeChild function, so that we can remove the container from the parent if needed

      return widget; //return the created widget
    },
  );
  WidgetDeclaration(
    Row,
    "Row",
    "Row",
    Icon(Icons.view_agenda_rounded),
    WidgetOptions(
      Row,
      options: [
        WidgetOption<MainAxisAlignment>(
          parseMainAxisAlignment,
          name: "mainAxisAlignment",
          defaultValue: "MainAxisAlignment.center",
          description:
              "The main axis alignment of the row. If not set, center will be used.",
          options: {
            "start": MainAxisAlignment.start,
            "end": MainAxisAlignment.end,
            "center": MainAxisAlignment.center,
            "space between": MainAxisAlignment.spaceBetween,
            "space around": MainAxisAlignment.spaceAround,
            "space evenly": MainAxisAlignment.spaceEvenly,
          },
        ),
        WidgetOption<CrossAxisAlignment>(
          parseCrossAxisAlignment,
          name: "crossAxisAlignment",
          defaultValue: "CrossAxisAlignment.center",
          description:
              "The cross axis alignment of the row. If not set, center will be used.",
          options: {
            "start": CrossAxisAlignment.start,
            "end": CrossAxisAlignment.end,
            "center": CrossAxisAlignment.center,
            "stretch": CrossAxisAlignment.stretch,
            "baseline": CrossAxisAlignment.baseline,
          },
        ),
        WidgetOption<MainAxisSize>(
          parseMainAxisSize,
          name: "mainAxisSize",
          defaultValue: "MainAxisSize.min",
          description:
              "The main axis size of the row. If not set, min will be used.",
          options: {"min": MainAxisSize.min, "max": MainAxisSize.max},
        ),
      ],
    )..register(),
    (LayoutWidget? parent, {Map<String, dynamic>? properties}) {
      //this is used to add a row widget to the layout
      LayoutWidget widget = LayoutWidget(
        (context, children, properties) {
          //this is the builder function that builds the widget

          WidgetOptions options = WidgetOptions.fromType(Row);

          properties["mainAxisSize"] ??= options.getDefaultValue(
            "mainAxisSize",
          ); //we set the mainAxisSize property to the default value defined in the widget options, so that we can use it in the widget
          properties["crossAxisAlignment"] ??= options.getDefaultValue(
            "crossAxisAlignment",
          ); //we set the crossAxisAlignment property to the default value defined in the widget options, so that we
          properties["mainAxisAlignment"] ??= options.getDefaultValue(
            "mainAxisAlignment",
          ); //we set the mainAxisAlignment property to the default value defined in the widget options, so that we can use it in the widget

          return Row(
            //the actual row widget that will be displayed
            mainAxisSize: options.getValue(
              "mainAxisSize",
              properties["mainAxisSize"],
            ), //the main axis size is set to min, so the row will only take up as much space as its children need
            crossAxisAlignment: options.getValue(
              "crossAxisAlignment",
              properties["crossAxisAlignment"],
            ), //the cross axis alignment is set to center, so the children will be centered in the row
            mainAxisAlignment: options.getValue(
              "mainAxisAlignment",
              properties["mainAxisAlignment"],
            ), //the main axis alignment is set to center, so the children will be centered in the row
            children:
                children, //the children of the row are the children passed to the builder function, which are the widgets that will be displayed in the row
          );
        },
        id: 'row${rowIndex++}', //same as the container
        type: ContainerType
            .unlimited, //sets the type of the row to unlimited, meaning it can have multiple children
        removeFromParent: parent?.removeChild,
        parent: parent,
        widgetType: Row,
        properties: properties,
      ); //same as the container

      return widget; //return the created widget
    },
  );
  WidgetDeclaration(
    Column,
    "Column",
    "Column",
    Icon(Icons.view_week_rounded),
    WidgetOptions.from(WidgetOptions.fromType(Row), Column)..register(),
    (LayoutWidget? parent, {Map<String, dynamic>? properties}) {
      //this is used to add a row widget to the layout
      LayoutWidget widget = LayoutWidget(
        (context, children, properties) {
          //this is the builder function that builds the widget

          WidgetOptions options = WidgetOptions.fromType(
            Row,
          ); //a Row has the same options as a Column, so we can use the same widget options class

          properties["mainAxisSize"] ??= options.getDefaultValue(
            "mainAxisSize",
          ); //we set the mainAxisSize property to the default value defined in the widget options, so that we can use it in the widget
          properties["crossAxisAlignment"] ??= options.getDefaultValue(
            "crossAxisAlignment",
          ); //we set the crossAxisAlignment property to the default value defined in the widget options, so that we
          properties["mainAxisAlignment"] ??= options.getDefaultValue(
            "mainAxisAlignment",
          ); //we set the mainAxisAlignment property to the default value defined in the widget options, so that we can use it in the widget

          return Column(
            //the actual row widget that will be displayed
            mainAxisSize: options.getValue(
              "mainAxisSize",
              properties["mainAxisSize"],
            ), //the main axis size is set to min, so the row will only take up as much space as its children need
            crossAxisAlignment: options.getValue(
              "crossAxisAlignment",
              properties["crossAxisAlignment"],
            ), //the cross axis alignment is set to center, so the children will be centered in the row
            mainAxisAlignment: options.getValue(
              "mainAxisAlignment",
              properties["mainAxisAlignment"],
            ), //the main axis alignment is set to center, so the children will be centered in the row
            children:
                children, //the children of the row are the children passed to the builder function, which are the widgets that will be displayed in the row
          );
        },
        id: 'column${columnIndex++}', //same as the container
        type: ContainerType
            .unlimited, //sets the type of the row to unlimited, meaning it can have multiple children
        removeFromParent: parent?.removeChild,
        parent: parent,
        widgetType: Column,
        properties: properties,
      ); //same as the container

      return widget; //return the created widget
    },
  );

  WidgetDeclaration(
    NinePatchButton,
    "NinePatchButton",
    "Nine Patch Button",
    Icon(Icons.view_agenda_rounded),
    WidgetOptions(
      NinePatchButton,
      options: [
        WidgetOption<String>(
          (type) => type.toString(),
          name: "text",
          defaultValue: "",
          description: "The text to display on the button.",
        ),
        WidgetOption<ButtonAction>(
          parseButtonAction,
          name: "onPressed",
          defaultValue: DebugButtonAction().toJson(),
          description:
              "The function to call when the button is pressed. If not set, it will do nothing.",
        ),

        WidgetOption<String>(
          (type) => type.toString(),
          name: "imageName",
          defaultValue: "button_0",
          description:
              "The name of the nine patch image texture that will be used for the button.",
          options: {
            for (var value in NinePatchTexture.getLoadedTextureNames())
              value: value,
          },
        ),
      ],
    )..register(),
    (LayoutWidget? parent, {Map<String, dynamic>? properties}) {
      LayoutWidget widget = LayoutWidget(
        (context, children, properties) {
          WidgetOptions options = WidgetOptions.fromType(NinePatchButton);

          properties["text"] ??= options.getDefaultValue("text");
          properties["onPressed"] ??= options.getDefaultValue("onPressed");
          properties["imageName"] ??= options.getDefaultValue("imageName");

          return NinePatchButton(
            text: options.getValue(
              "text",
              properties["text"],
            ), //the text that will be displayed on the button
            onPressed: () => options
                .getValue("onPressed", properties["onPressed"])
                .press(
                  context,
                ), //the onPressed function is set to the action that was passed to the function, so that we can use it in the widget
            textureName: options.getValue(
              "imageName",
              properties["imageName"],
            ), //the image name is set to the image name that was passed to the function, so that we can use it in the widget
            child: children.isNotEmpty ? children.first : null,
          );
        },
        id: 'ninepatch_button${ninepatchButtonIndex++}',
        type: ContainerType.single,
        removeFromParent: parent?.removeChild,
        parent: parent,
        widgetType: NinePatchButton,
        properties: properties,
      );
      return widget;
    },
  );

  WidgetDeclaration(
    Text,
    "Text",
    "Text",
    Icon(Icons.text_fields_outlined),
    WidgetOptions(
      Text,
      options: [
        WidgetOption<String>(
          (type) => type.toString(),
          name: "text",
          defaultValue: "",
          description: "The text to display in the text widget.",
        ),
        WidgetOption<TextStyle>(
          parseTextStyle,
          name: "style",
          defaultValue: defaultFont,
          description:
              "The style of the text. If not set, a default style will be used.",
        ),
        WidgetOption<TextAlign>(
          parseTextAlign,
          name: "textAlign",
          defaultValue: "TextAlign.center",
          description:
              "The alignment of the text. If not set, center will be used.",
          options: {
            "left": TextAlign.left,
            "right": TextAlign.right,
            "center": TextAlign.center,
            "justify": TextAlign.justify,
            "start": TextAlign.start,
            "end": TextAlign.end,
          },
        ),
      ],
    )..register(),
    (LayoutWidget? parent, {Map<String, dynamic>? properties}) {
      //this is used to add a text widget to the layout
      LayoutWidget widget = LayoutWidget(
        (context, children, properties) {
          //this is the builder function that builds the widget

          WidgetOptions options = WidgetOptions.fromType(Text);

          double screenWidth = MediaQuery.of(context)
              .size
              .width; //getter for the screen width, so we can use it to calculate the size of the widgets
          double screenHeight = MediaQuery.of(
            context,
          ).size.width; //same for the width

          properties["text"] ??=
              "Text"; //we set the text property to the text that was passed to the function, so that we can use it in the widget
          properties["style"] ??= options.getDefaultValue("style");
          properties["alignment"] ??= options.getDefaultValue("alignment");

          return Text(
            options.getValue(
              "text",
              properties["text"],
            ), //the text that will be displayed in the widget
            style: convertToAbsoluteTextSize(
              options.getValue("style", properties["style"]),
              screenWidth,
              screenHeight,
            ), //the text style is set to a font size of 18, black color and the pixel art font
            textAlign: options.getValue(
              "textAlign",
              properties["textAlign"],
            ), //the text is centered in the widget
          );
        },
        id: 'text${textId++}', //same as the container and row
        type: ContainerType
            .sealed, //sealed means that the text widget cannot have any children
        removeFromParent: parent?.removeChild,
        parent: parent,
        widgetType: Text,
        properties: properties,
      ); //same as the container and row

      return widget; //return the created widget
    },
  );
  WidgetDeclaration(
    Expanded,
    "Expanded",
    "Expanded",
    Icon(Icons.expand),
    WidgetOptions(
      Expanded,
      options: [
        WidgetOption<double>(
          parseDouble,
          name: "flex",
          defaultValue: 1.0,
          description:
              "The flex factor of the expanded widget. If not set, 1.0 will be used.",
        ), //the flex factor is used to determine how much space the widget should take up in the row or column
      ],
    )..register(),
    (LayoutWidget? parent, {Map<String, dynamic>? properties}) {
      //this is used to add an expanded widget to the layout
      if (parent == null || !parent.canAddChild) {
        return null; //if the parent is null or cannot have children, we return null
      }

      LayoutWidget widget = LayoutWidget(
        (context, children, properties) {
          //this is the builder function that builds the widget

          WidgetOptions options = WidgetOptions.fromType(Expanded);

          properties["flex"] ??= options.getDefaultValue(
            "flex",
          ); //we set the flex property to the default value defined in the widget options, so that we can use it in the widget

          return Expanded(
            //the actual expanded widget that will be displayed
            flex: options
                .getValue("flex", properties["flex"])
                .toInt(), //the flex factor of the expanded widget
            child: children.isNotEmpty
                ? children.first
                : Container(), //we only allow one child in an expanded widget, so we take the first child from the children list. if no child is provided, we give null
          );
        },
        id: 'expanded${expandedId++}', //same as the container and row
        type: ContainerType
            .single, //sealed means that this widget cannot have any children
        removeFromParent: parent.removeChild,
        parent: parent,
        widgetType: Expanded,
        dropCondition: (other) =>
            other.widgetType == Row || other.widgetType == Column,
        properties: properties,
      ); //same as the container and row

      return widget; //return the created widget
    },
  );

  WidgetDeclaration(
    Positioned,
    "Positioned",
    "Positioned",
    Icon(Icons.add_circle_outline),
    WidgetOptions(
      Positioned,
      options: [
        WidgetOption<double>(
          parseDouble,
          name: "left",
          defaultValue: 0.0,
          description: "The left position of the widget in the stack.",
        ),
        WidgetOption<double>(
          parseDouble,
          name: "top",
          defaultValue: 0.0,
          description: "The top position of the widget in the stack.",
        ),
        WidgetOption<double>(
          parseDouble,
          name: "right",
          defaultValue: 0.0,
          description: "The right position of the widget in the stack.",
        ),
        WidgetOption<double>(
          parseDouble,
          name: "bottom",
          defaultValue: 0.0,
          description: "The bottom position of the widget in the stack.",
        ),
      ],
    )..register(),
    (LayoutWidget? parent, {Map<String, dynamic>? properties}) {
      //this is used to add a positioned widget to the layout
      if (parent == null || !parent.canAddChild) return null;
      LayoutWidget widget = LayoutWidget(
        (context, children, properties) {
          //this is the builder function that builds the widget

          WidgetOptions options = WidgetOptions.fromType(Positioned);

          double screenWidth = MediaQuery.of(context)
              .size
              .width; //getter for the screen width, so we can use it to calculate the size of the widgets
          double screenHeight = MediaQuery.of(
            context,
          ).size.width; //same for the width

          properties["left"] ??= options.getDefaultValue(
            "left",
          ); //we set the left property to the default value defined in the widget options, so that we can use it in the widget
          properties["top"] ??= options.getDefaultValue(
            "top",
          ); //we set the top property to the default value defined in the widget options, so that we can use it in the widget
          properties["right"] ??= options.getDefaultValue(
            "right",
          ); //we set the right property to the default value defined in the widget options, so that we can use it in the widget
          properties["bottom"] ??= options.getDefaultValue(
            "bottom",
          ); //we set the bottom property to the default value defined in the widget options, so that we can use it in the widget

          return Positioned(
            //the actual positioned widget that will be displayed
            left:
                options.getValue("left", properties["left"]) *
                screenWidth, //the left position of the widget in the stack
            top:
                options.getValue("top", properties["top"]) *
                screenHeight, //the top position of the widget in the stack
            right:
                options.getValue("right", properties["right"]) *
                screenWidth, //the right position of the widget in the stack
            bottom:
                options.getValue("bottom", properties["bottom"]) *
                screenHeight, //the bottom position of the widget in the stack
            child: children.isNotEmpty
                ? children.first
                : Container(), //we only allow one child in a positioned widget, so we take the first child from the children list. if no child is provided, we give null
          );
        },
        id: 'positioned${positionedId++}', //same as the container and row
        type: ContainerType
            .single, //sealed means that this widget cannot have any children
        removeFromParent: parent.removeChild,
        parent: parent,
        widgetType: Positioned,
        dropCondition: (other) => other.widgetType is Stack,
        properties: properties,
      ); //same as the container and row

      return widget; //return the created widget
    },
  );
  WidgetDeclaration(
    FittedBox,
    "FittedBox",
    "Fitted Box",
    Icon(Icons.indeterminate_check_box_outlined),
    WidgetOptions(
      FittedBox,
      options: [
        WidgetOption<Alignment>(
          parseAlignment,
          name: "alignment",
          defaultValue: "Alignment.center",
          description:
              "The alignment of the child within the FittedBox. If not set, center will be used.",
          options: {
            "center": Alignment.center,
            "top left": Alignment.topLeft,
            "top right": Alignment.topRight,
            "bottom left": Alignment.bottomLeft,
            "bottom right": Alignment.bottomRight,
            "top center": Alignment.topCenter,
            "bottom center": Alignment.bottomCenter,
          },
        ),
        WidgetOption<BoxFit>(
          parseBoxFit,
          name: "fit",
          defaultValue: "BoxFit.contain",
          description:
              "The fit of the child within the FittedBox. If not set, contain will be used.",
          options: {
            "fill": BoxFit.fill,
            "contain": BoxFit.contain,
            "cover": BoxFit.cover,
            "fit width": BoxFit.fitWidth,
            "fit height": BoxFit.fitHeight,
            "none": BoxFit.none,
          },
        ),
      ],
    )..register(),
    (LayoutWidget? parent, {Map<String, dynamic>? properties}) {
      LayoutWidget widget = LayoutWidget(
        (context, children, properties) {
          WidgetOptions options = WidgetOptions.fromType(FittedBox);

          properties["alignment"] ??= options.getDefaultValue("alignment");
          properties["fit"] ??= options.getDefaultValue("fit");

          return FittedBox(
            alignment: options.getValue("alignment", properties["alignment"]),
            fit: options.getValue("fit", properties["fit"]),
            child: children.isNotEmpty ? children.first : Container(),
          );
        },
        id: 'fitted_box${fittedBoxId++}',
        type: ContainerType.single,
        removeFromParent: parent?.removeChild,
        parent: parent,
        widgetType: FittedBox,
        properties: properties,
      );
      return widget;
    },
  );

  WidgetDeclaration(
    Transform,
    "Transform",
    "Transform",
    Icon(Icons.linear_scale_rounded),
    WidgetOptions(
      Transform,
      options: [
        WidgetOption<double>(
          parseDouble,
          name: "rotation",
          defaultValue: 0.0,
          description:
              "The rotation of the widget in radians. If not set, no rotation will be applied.",
        ),
        WidgetOption<double>(
          parseDouble,
          name: "scale",
          defaultValue: 1.0,
          description:
              "The scale of the widget. If not set, no scaling will be applied.",
        ),
        WidgetOption<Alignment>(
          parseAlignment,
          name: "alignment",
          defaultValue: "Alignment.center",
          description:
              "The alignment of the child within the Transform. If not set, center will be used.",
          options: {
            "center": Alignment.center,
            "top left": Alignment.topLeft,
            "top right": Alignment.topRight,
            "bottom left": Alignment.bottomLeft,
            "bottom right": Alignment.bottomRight,
            "top center": Alignment.topCenter,
            "bottom center": Alignment.bottomCenter,
          },
        ),
      ],
    )..register(),
    (LayoutWidget? parent, {Map<String, dynamic>? properties}) {
      LayoutWidget widget = LayoutWidget(
        (context, children, properties) {
          WidgetOptions options = WidgetOptions.fromType(Transform);

          properties["rotation"] ??= options.getDefaultValue("rotation");
          properties["scale"] ??= options.getDefaultValue("scale");
          properties["alignment"] ??= options.getDefaultValue("alignment");

          return Transform(
            alignment: options.getValue("alignment", properties["alignment"]),
            transform: vm64.Matrix4.identity()
              ..rotateZ(radians(options.getValue("rotation", properties["rotation"])))
              ..scale(options.getValue("scale", properties["scale"])),
            child: children.isNotEmpty ? children.first : Container(),
          );
        },
        id: 'transform${transformId++}',
        type: ContainerType.single,
        removeFromParent: parent?.removeChild,
        parent: parent,
        widgetType: Transform,
        properties: properties,
      );
      return widget;
    },
  );

  WidgetDeclaration(
    Opacity,
    "Opacity",
    "Opacity",
    Icon(Icons.opacity),
    WidgetOptions(
      Opacity,
      options: [
        WidgetOption<double>(
          parseDouble,
          name: "opacity",
          defaultValue: 0.5,
          description:
              "The opacity of the widget. If not set, 0.5 will be used.",
        ),
      ],
    )..register(),
    (LayoutWidget? parent, {Map<String, dynamic>? properties}) {
      LayoutWidget widget = LayoutWidget(
        (context, children, properties) {
          WidgetOptions options = WidgetOptions.fromType(Opacity);

          properties["opacity"] ??= options.getDefaultValue("opacity");

          return Opacity(
            opacity: options.getValue("opacity", properties["opacity"]),
            child: children.isNotEmpty ? children.first : Container(),
          );
        },
        id: 'opacity${opacityId++}',
        type: ContainerType.single,
        removeFromParent: parent?.removeChild,
        parent: parent,
        widgetType: Opacity,
        properties: properties,
      );
      return widget;
    },
  );

  WidgetDeclaration(
    Card,
    "Card",
    "Card",
    Icon(Icons.credit_card),
    WidgetOptions(
      Card,
      options: [
        WidgetOption<Color>(
          parseColor,
          name: "color",
          defaultValue: Colors.white,
          description: "The color of the card. If not set, white will be used.",
        ),
        WidgetOption<EdgeInsetsGeometry?>(
          parseEdgeInsets,
          name: "margin",
          defaultValue: EdgeInsets.all(8.0),
          description: "The margin of the card. If not set, 8.0 will be used.",
        ),
      ],
    )..register(),
    (LayoutWidget? parent, {Map<String, dynamic>? properties}) {
      LayoutWidget widget = LayoutWidget(
        (context, children, properties) {
          WidgetOptions options = WidgetOptions.fromType(Card);

          properties["color"] ??= options.getDefaultValue("color");
          properties["margin"] ??= options.getDefaultValue("margin");

          double availableWidth = MediaQuery.of(context)
              .size
              .width; //we get the available width of the parent widget, if no parent is provided, we use the screen width
          double availableHeight = MediaQuery.of(context).size.height;

          return Card(
            color: options.getValue("color", properties["color"]),
            margin: convertToAbsolute(
              options.getValue("margin", properties["margin"]),
              availableWidth,
              availableHeight,
            ),
            child: children.isNotEmpty ? children.first : Container(),
          );
        },
        id: 'card${cardId++}',
        type: ContainerType.single,
        removeFromParent: parent?.removeChild,
        parent: parent,
        widgetType: Card,
        properties: properties,
      );
      return widget;
    },
  );

  WidgetDeclaration(
    GridView,
    "GridView",
    "Grid View",
    Icon(Icons.grid_4x4),
    WidgetOptions(
      GridView,
      options: [
        WidgetOption<int>(
          parseInt,
          name: "crossAxisCount",
          defaultValue: 2,
          description:
              "The number of columns in the grid. If not set, 2 will be used.",
        ),
        WidgetOption<double>(
          parseDouble,
          name: "childAspectRatio",
          defaultValue: 1.0,
          description:
              "The aspect ratio of the children in the grid. If not set, 1.0 will be used.",
        ),
      ],
    )..register(),
    (LayoutWidget? parent, {Map<String, dynamic>? properties}) {
      LayoutWidget widget = LayoutWidget(
        (context, children, properties) {
          WidgetOptions options = WidgetOptions.fromType(GridView);

          properties["crossAxisCount"] ??= options.getDefaultValue(
            "crossAxisCount",
          );
          properties["childAspectRatio"] ??= options.getDefaultValue(
            "childAspectRatio",
          );

          return GridView.count(
            crossAxisCount: options.getValue(
              "crossAxisCount",
              properties["crossAxisCount"],
            ),
            childAspectRatio: options.getValue(
              "childAspectRatio",
              properties["childAspectRatio"],
            ),
            children: children,
          );
        },
        id: 'grid_view${gridViewId++}',
        type: ContainerType.unlimited,
        removeFromParent: parent?.removeChild,
        parent: parent,
        widgetType: GridView,
        properties: properties,
      );
      return widget;
    },
  );

  WidgetDeclaration(
    Image,
    "Image",
    "Image",
    Icon(Icons.image),
    WidgetOptions(
      Image,
      options: [
        WidgetOption<String>(
          (type) => type.toString(),
          name: "path",
          defaultValue: "",
        ),
        WidgetOption<double>(parseDouble, name: "width", defaultValue: 0.1),
        WidgetOption<double>(parseDouble, name: "height", defaultValue: 0.1),
        WidgetOption<Alignment>(
          parseAlignment,
          name: "alignment",
          defaultValue: "Alignment.center",
          options: {
            "center": Alignment.center,
            "top left": Alignment.topLeft,
            "top right": Alignment.topRight,
            "bottom left": Alignment.bottomLeft,
            "bottom right": Alignment.bottomRight,
            "top center": Alignment.topCenter,
            "bottom center": Alignment.bottomCenter,
          },
        ),
      ],
    )..register(), //no options for stack, because it is just a container for other widgets,
    (LayoutWidget? parent, {Map<String, dynamic>? properties}) {
      LayoutWidget widget = LayoutWidget(
        (context, children, properties) {
          WidgetOptions options = WidgetOptions.fromType(Image);

          double screenWidth = MediaQuery.of(context)
              .size
              .width; //getter for the screen width, so we can use it to calculate the size of the widgets
          double screenHeight = MediaQuery.of(
            context,
          ).size.width; //same for the width

          properties["path"] ??= options.getDefaultValue("path");
          properties["width"] ??= options.getDefaultValue("width");
          properties["height"] ??= options.getDefaultValue("height");
          properties["alignment"] ??= options.getDefaultValue("alignment");

          return Image.asset(
            options.getValue("path", properties["path"]),
            width: options.getValue("width", properties["width"]) * screenWidth,
            height:
                options.getValue("height", properties["height"]) * screenHeight,
            alignment: options.getValue("alignment", properties["alignment"]),
          );
        },
        id: 'image${imageId++}',
        type: ContainerType.sealed,
        removeFromParent: parent?.removeChild,
        parent: parent,
        widgetType: Image,
        properties: properties,
      );
      return widget;
    },
  );

  WidgetDeclaration(
    Stack,
    "Stack",
    "Stack",
    Icon(Icons.layers),
    WidgetOptions(
      Stack,
      options: [],
    )..register(), //no options for stack, because it is just a container for other widgets,
    (LayoutWidget? parent, {Map<String, dynamic>? properties}) {
      LayoutWidget widget = LayoutWidget(
        (context, children, properties) {
          //this is the builder function that builds the widget
          return Stack(
            //the actual stack widget that will be displayed
            children:
                children, //the children of the stack are the children passed to the builder function, which are the widgets that will be displayed in the stack
          );
        },
        id: 'stack${stackId++}', //same as the container
        type: ContainerType
            .unlimited, //sets the type of the stack to unlimited, so it can have multiple children
        removeFromParent: parent?.removeChild,
        parent: parent,
        widgetType: Stack,
        properties: properties,
      ); //same as the container

      return widget; //return the created widget
    },
  );

  WidgetDeclaration(
    InteractiveViewer,
    "InteractiveViewer",
    "Interactive Viewer",
    Icon(Icons.view_carousel_outlined),
    WidgetOptions(
      InteractiveViewer,
      options: [
        WidgetOption<bool>(
          parseBoolean,
          name: "panEnabled",
          defaultValue: true,
        ),
        WidgetOption<bool>(
          parseBoolean,
          name: "scaleEnabled",
          defaultValue: true,
        ),
        WidgetOption<Alignment>(
          parseAlignment,
          name: "alignment",
          defaultValue: "Alignment.center",
          options: {
            "center": Alignment.center,
            "top left": Alignment.topLeft,
            "top right": Alignment.topRight,
            "bottom left": Alignment.bottomLeft,
            "bottom right": Alignment.bottomRight,
            "top center": Alignment.topCenter,
            "bottom center": Alignment.bottomCenter,
          },
        ),
        WidgetOption<PanAxis>(
          parsePanAxis,
          name: "panAxis",
          defaultValue: "PanAxis.free",
          options: {
            "free": PanAxis.free,
            "vertical": PanAxis.vertical,
            "horizontal": PanAxis.horizontal,
            "aligned": PanAxis.aligned,
          },
        ),
        WidgetOption<double>(parseDouble, name: "minScale", defaultValue: 0.2),
        WidgetOption<double>(parseDouble, name: "maxScale", defaultValue: 8.0),
      ],
    )..register(), //no options for stack, because it is just a container for other widgets,
    (LayoutWidget? parent, {Map<String, dynamic>? properties}) {
      LayoutWidget widget = LayoutWidget(
        (context, children, properties) {
          WidgetOptions options = WidgetOptions.fromType(InteractiveViewer);

          properties["panEnabled"] ??= options.getDefaultValue("panEnabled");
          properties["scaleEnabled"] ??= options.getDefaultValue(
            "scaleEnabled",
          );
          properties["alignment"] ??= options.getDefaultValue("alignment");
          properties["panAxis"] ??= options.getDefaultValue("panAxis");
          properties["minScale"] ??= options.getDefaultValue("minScale");
          properties["maxScale"] ??= options.getDefaultValue("maxScale");

          return InteractiveViewer(
            panEnabled: options.getValue(
              "panEnabled",
              properties["panEnabled"],
            ),
            scaleEnabled: options.getValue(
              "scaleEnabled",
              properties["scaleEnabled"],
            ),
            alignment: options.getValue("alignment", properties["alignment"]),
            panAxis: options.getValue("panAxis", properties["panAxis"]),
            minScale: options.getValue("minScale", properties["minScale"]),
            maxScale: options.getValue("maxScale", properties["maxScale"]),

            constrained: false,
            child: children.isNotEmpty ? children.first : Container(),
          );
        },
        id: 'interactive_viewer${interactiveViewerId++}',
        type: ContainerType.single,
        removeFromParent: parent?.removeChild,
        parent: parent,
        widgetType: InteractiveViewer,
        properties: properties,
      );
      return widget;
    },
  );

  WidgetDeclaration(
    SingleChildScrollView,
    "SingleChildScrollView",
    "Single Child Scroll View",
    Icon(Icons.view_headline),
    WidgetOptions(
      SingleChildScrollView,
      options: [
        WidgetOption<Axis>(
          parseAxis,
          name: "axis",
          defaultValue: "Axis.vertical",
          options: {"horizontal": Axis.horizontal, "vertical": Axis.vertical},
        ),
      ],
    )..register(), //no options for stack, because it is just a container for other widgets,
    (LayoutWidget? parent, {Map<String, dynamic>? properties}) {
      LayoutWidget widget = LayoutWidget(
        (context, children, properties) {
          WidgetOptions options = WidgetOptions.fromType(SingleChildScrollView);

          properties["axis"] ??= options.getDefaultValue("axis");

          return SingleChildScrollView(
            scrollDirection: options.getValue("axis", properties["axis"]),
            child: children.isNotEmpty ? children.first : Container(),
          );
        },
        id: 'singleChildScrollView${singleChildScrollViewId++}',
        type: ContainerType.single,
        removeFromParent: parent?.removeChild,
        parent: parent,
        widgetType: SingleChildScrollView,
        properties: properties,
      );
      return widget;
    },
  );
}
