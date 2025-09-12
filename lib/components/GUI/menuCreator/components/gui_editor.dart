import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' hide Matrix4;
import 'package:flutter/services.dart';
import 'package:flutter_resizable_container/flutter_resizable_container.dart';
import 'package:mpg_achievements_app/components/GUI/json_factory/json_exporter.dart';
import 'package:mpg_achievements_app/components/GUI/menuCreator/components/dependencyViewer/display_node.dart';
import 'package:mpg_achievements_app/components/GUI/menuCreator/components/propertyEditor/option_editor.dart';
import 'package:mpg_achievements_app/components/GUI/menuCreator/components/searchBar/widgetSearchBar.dart';
import 'package:mpg_achievements_app/components/GUI/menuCreator/components/widget_declaration.dart';
import 'package:mpg_achievements_app/components/GUI/menuCreator/components/dependencyViewer/editor_node_dependency_viewer.dart';
import 'package:mpg_achievements_app/components/GUI/menuCreator/components/dependencyViewer/layout_widget.dart';
import 'package:mpg_achievements_app/components/router/router.dart';
import 'package:mpg_achievements_app/main.dart';

class GuiEditor extends StatefulWidget {
  //the GUI editor lets us create guis and later export them as a json
  const GuiEditor({super.key});

  @override
  State<StatefulWidget> createState() => _GuiEditorState(); //the state of the widget. we have a separate class for that.
}

class _GuiEditorState extends State<GuiEditor> {
  //the state class for the GUI editor.

  double get screenWidth => MediaQuery.of(context)
      .size
      .width; //getter for the screen width, so we can use it to calculate the size of the widgets
  double get screenHeight =>
      MediaQuery.of(context).size.height; //same for the width

  late LayoutWidget root; //just temp to be initialized later in initState()

  NodeViewer? nodeViewer; //this is the node viewer that will be used to show the dependencies of a node.
  final GlobalKey<NodeViewerState> _nodeViewerKey =
      GlobalKey<NodeViewerState>();


  OptionEditorMenu? optionEditor;
  final editorKey = GlobalKey<OptionEditorMenuState>();

  late WidgetSearchBar widgetSearchBar;

  void updateViewport() {
    //this is used to update the viewport of the node viewer, so that it shows the current state of the layout
    setState(
      () {},
    ); //we call setState on the node viewer to rebuild it and show the current state of the layout
  }



  @override
  void initState() {
    super.initState();
    initEditor();
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
        updateWithNewSelectedWidget: (LayoutWidget newNode) {
          setState(() {
            editorKey.currentState!.setState(() {
              optionEditor!.node = newNode;
            });
          });
        },
      );
    });

    optionEditor = OptionEditorMenu(
      key: editorKey,
      node: nodeViewer!.currentSelectedWidget,
      updateView: updateViewport,
    );

    widgetSearchBar = WidgetSearchBar(
        onWidgetSelected: (WidgetDeclaration widgetDeclaration) {
          _nodeViewerKey.currentState!.setState(() {
            DisplayNode.widgetToDropOff = widgetDeclaration.builder(root);
          });
      print("new widget to drop off set!");
    });

    doneLoading = true;
  }

  Future<Map<String, dynamic>> loadJson(String name) async {
    final jsonString = await rootBundle.loadString("assets/screens/$name.json");
    final jsonMap = json.decode(jsonString);
    return Map<String, dynamic>.from(jsonMap);
  }

  @override
  Widget build(BuildContext context) {
    //here we actually build the stuff that's being rendered
    if (nodeViewer == null || optionEditor == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      //we use a scaffold bc it lets us easily add components with some presets.
      backgroundColor: Colors
          .white, //the background color of the scaffold is white, so we can see the widgets clearly

      body: ResizableContainer(
        children: [
          ResizableChild(
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                nodeViewer!,
                Column(
                  children: [
                    SizedBox(height: 57),

                    FloatingActionButton(
                      heroTag: null,
                      onPressed: () {
                        String json = WidgetJsonUtils.exportWidgetToJson(
                          root,
                        ); //we convert the root widget to a json string
                        print("json: $json");
                      },
                      child: Icon(Icons.outbond_outlined),
                    ),
                    SizedBox(height: screenHeight * 0.62),

                    Container(
                      width: 55,
                      height: 55,

                      decoration: BoxDecoration(
                        color: CupertinoColors.extraLightBackgroundGray,
                        borderRadius: BorderRadius.circular(15.0),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            spreadRadius: 2,
                            blurRadius: 6,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),

                      child: PopupMenuButton(
                        style: ButtonStyle(
                          backgroundColor: WidgetStateProperty.all(
                            CupertinoColors.systemGrey4,
                          ),
                          elevation: WidgetStateProperty.all(6.0),
                          shape: WidgetStateProperty.all(CircleBorder()),
                        ),

                        itemBuilder: (context) => [
                          for (final declaration
                              in WidgetDeclaration.declarationCache)
                            PopupMenuItem(
                              value: declaration.id,
                              child: ListTile(
                                leading: declaration.icon,
                                title: Text(declaration.displayName),
                              ),
                            ),
                        ],
                        onSelected: (value) {
                          //this is called when an item is selected from the popup menu
                          switch (value) {
                            //we switch on the value of the selected item
                            case "positioned":
                              {
                                LayoutWidget? parent = getNearestStackRecursive(
                                  root,
                                );

                                var widgetDeclaration = WidgetDeclaration
                                    .declarationCache
                                    .where((element) => element.id == value)
                                    .firstOrNull;
                                if (widgetDeclaration != null) {
                                  addWidget(widgetDeclaration.builder(parent));
                                }
                              } //if the value is positioned, we add a positioned widget to the root widget
                            case "expanded":
                              {
                                LayoutWidget? parent = getNearestFlexRecursive(
                                  root,
                                ); //we get the nearest stack widget to add the expanded widget to, because you can only add expanded widgets to a row or column

                                var widgetDeclaration = WidgetDeclaration
                                    .declarationCache
                                    .where((element) => element.id == value)
                                    .firstOrNull;
                                if (widgetDeclaration != null) {
                                  addWidget(widgetDeclaration.builder(parent));
                                }
                              }
                            default:
                              {
                                var widgetDeclaration = WidgetDeclaration
                                    .declarationCache
                                    .where((element) => element.id == value)
                                    .firstOrNull;
                                if (widgetDeclaration != null) {
                                  addWidget(widgetDeclaration.builder(root));
                                }
                              }
                          }

                          _nodeViewerKey.currentState?.setState(
                            () {},
                          ); //this updates the node viewer to show the new widget that was added
                        },
                        tooltip: "open widget menu",
                        child: Icon(Icons.add_box_rounded),
                      ), //tooltip and + icon
                    ),
                  ],
                ),
              ],
            ),
          ),
          ResizableChild(
            size: ResizableSize.expand(flex: 3),
            child: ResizableContainer(
              children: [
                ResizableChild(
                  size: ResizableSize.expand(flex: 3),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      double containerWidth = constraints.maxWidth;
                      double containerHeight = constraints.maxHeight;

                      return Stack(
                        children: [
                          SizedBox(
                            width: containerWidth,
                            height: containerHeight,
                            child: root.build(context),
                          ),
                          Positioned.fill(
                            child: Center(child: widgetSearchBar),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                ResizableChild(
                  child: ResizableContainer(
                    direction: Axis.horizontal,
                    children: [
                      ResizableChild(child: optionEditor!),
                    ],
                  ),
                ),
              ],
              direction: Axis.vertical,
            )

          ),
        ],
        direction: Axis.horizontal,
      ),

      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [],
      ),
    );
  }

  /// Adds a widget to the layout.
  /// The widget is built using the provided LayoutWidget.
  void addWidget(LayoutWidget? layoutWidget, {LayoutWidget? root}) async {
    if (layoutWidget == null) {
      return; //if the layoutWidget is null, we return and do not add anything
    }

    setState(() {
      //we call setState to rebuild the widget tree and show the new widget
      root ??=
          this.root; //if no root is provided, we use the current root widget

      root!.addChild(
        layoutWidget,
      ); //we add the new widget to the root widget's children
    });
  }

  List<Widget> toWidgetList(List<LayoutWidget> widgets) {
    return widgets.map((widget) => widget.build(context)).toList();
  }

  LayoutWidget? getNearestStackRecursive(LayoutWidget widget) {
    for (var value in widget.children) {
      if (value.widgetType == Stack) {
        //if the widget is a stack, we return it
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
