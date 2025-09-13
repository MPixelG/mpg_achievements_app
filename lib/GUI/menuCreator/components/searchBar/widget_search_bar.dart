import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mpg_achievements_app/components/router/router.dart';
import 'package:mpg_achievements_app/components/util/utils.dart';

import '../widget_declaration.dart';

class WidgetSearchBar extends StatefulWidget {
  final void Function(WidgetDeclaration widgetDeclaration) onWidgetSelected;

  @override
  State<StatefulWidget> createState() => _WidgetSearchBarState();
  const WidgetSearchBar({super.key, required this.onWidgetSelected});
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
      final isEscapePressed = event.physicalKey == PhysicalKeyboardKey.escape;
      final isHPressed = event.physicalKey == PhysicalKeyboardKey.keyH;

      if(isHPressed && !isVisible){
        _rootFocus.unfocus();
        _searchBarFocusNode.unfocus();
        setState(() {
          _rootFocus.unfocus();
          _searchBarFocusNode.unfocus();
        });

        AppRouter.router.goNamed("game");
      }

      if(isEscapePressed && isVisible){
        setState(() {
          isVisible = false;
          _searchBarFocusNode.unfocus();
          _rootFocus.requestFocus();
        });
      }

      if(isControlPressed && !isVisible){
        setState(() {
          isVisible = true;
          _searchBarFocusNode.requestFocus();
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

    WidgetDeclaration? currentBestMatch;

    SearchController searchController = SearchController();



    return KeyboardListener(
      focusNode: _rootFocus,
      onKeyEvent: _handleRawKey,
      autofocus: true,

      child: Visibility(
        visible: isVisible,
        child: SearchAnchor(
          searchController: searchController,
          builder: (context, controller) {
            SearchBar searchBar = SearchBar(
              controller: controller,
              focusNode: _searchBarFocusNode,
              onSubmitted: (value) {
                _searchBarFocusNode.requestFocus();
                print(currentBestMatch);
              },
              onTapOutside: (event) {
                setState(() {
                  isVisible = false;
                });
              },
              onChanged: (value) {
                if (!controller.isOpen) {
                  controller.openView();
                }
              },
            );
            return searchBar;
          },
          suggestionsBuilder: (BuildContext context, SearchController controller) {

            var allElements = WidgetDeclaration.declarationCache.toList();
            allElements.sort(
              (a, b) =>
                jaroWinkler(b.displayName, controller.text).compareTo(jaroWinkler(a.displayName, controller.text))
            );

            currentBestMatch = allElements.firstOrNull;

            return allElements.map<ListTile>((e) => ListTile(title: Text(e.displayName)));
          },
          viewOnSubmitted: (value) {
            setState(() {
              _searchBarFocusNode.unfocus();
              isVisible = false;
              widget.onWidgetSelected(currentBestMatch!);
              print(currentBestMatch);
            });
          },
        )
      )
    );

  }
}

class WidgetSearchBarEntry {
  WidgetDeclaration widgetDeclaration;

  String get widgetName => widgetDeclaration.id;

  WidgetSearchBarEntry(this.widgetDeclaration);
}