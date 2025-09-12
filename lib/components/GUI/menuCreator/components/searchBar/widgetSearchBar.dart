import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:mpg_achievements_app/components/GUI/menuCreator/components/widget_declaration.dart';
import 'package:mpg_achievements_app/components/router/router.dart';

class WidgetSearchBar extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _WidgetSearchBarState();
  const WidgetSearchBar({super.key});
}

class _WidgetSearchBarState extends State<WidgetSearchBar> {
  bool isVisible = false;

  final FocusNode _rootFocus = FocusNode();
  final FocusNode _searchBarFocusNode = FocusNode()..requestFocus();

  late final void Function(RawKeyEvent event)? _controlAndExitListener;

  late final Set<WidgetSearchBarEntry> searchBarEntries;

  Set<WidgetSearchBarEntry> buildEntries() => WidgetDeclaration.declarationCache.map<WidgetSearchBarEntry>((e) => WidgetSearchBarEntry(e)).toSet();

  @override
  void initState() {
    searchBarEntries = buildEntries();

    super.initState();

    _controlAndExitListener = (event) {
      if(!mounted) return;

      final isControlPressed = event.physicalKey == PhysicalKeyboardKey.controlLeft;
      final isHPressed = event.physicalKey == PhysicalKeyboardKey.keyH;

      if(isHPressed && !isVisible){
        print("h pressed!");
        _rootFocus.unfocus();
        _searchBarFocusNode.unfocus();
        setState(() {
          _rootFocus.unfocus();
          _searchBarFocusNode.unfocus();
        });

        AppRouter.router.goNamed("game");
      }

      if(isControlPressed){
        setState(() {
          isVisible = true;

          if(isVisible){
            _searchBarFocusNode.requestFocus();
          }
        });
      }
    };

    Future.delayed(Duration(seconds: 1), () {
      RawKeyboard.instance.addListener(_controlAndExitListener!);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _rootFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    RawKeyboard.instance.removeListener(_controlAndExitListener!);
    _rootFocus.dispose();
    super.dispose();
  }


  void _handleRawKey(KeyEvent event) {
    if (event is KeyDownEvent) {
      final isEnterPressed = event.physicalKey == PhysicalKeyboardKey.enter;

      if(isEnterPressed){
        setState(() {
          isVisible = false;
          _rootFocus.requestFocus();
        });
      }

    }

  }

  @override
  Widget build(BuildContext context) {

    return KeyboardListener(
      focusNode: _rootFocus,
      onKeyEvent: _handleRawKey,
      autofocus: true,

      child: Visibility(
        visible: isVisible,
        child: SearchBar(
          focusNode: _searchBarFocusNode,
          onSubmitted: (value) => _searchBarFocusNode.requestFocus(),
          onTapOutside: (event) {
            setState(() {
              isVisible = false;
            });
          },
        )
      ),
    );

  }
}

class WidgetSearchBarEntry {
  WidgetDeclaration widgetDeclaration;

  String get widgetName => widgetDeclaration.id;

  WidgetSearchBarEntry(this.widgetDeclaration);
}