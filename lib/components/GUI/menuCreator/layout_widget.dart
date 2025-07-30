import 'package:flutter/cupertino.dart';

class LayoutWidget{
  final List<Widget> _children = [];
  final Widget Function(BuildContext context, List<Widget> children, Map<String, dynamic> properties) _builder;
  Map<String, dynamic> properties;

  LayoutWidget(this._builder, {this.properties = const {}});

  void addChild(Widget child) {
    _children.add(child);
  }

  Widget build(BuildContext context) => _builder(context, _children, properties);
}

class RelativelySizedBox extends StatelessWidget {
  final double widthFactor;
  final double heightFactor;
  final Widget child;

  const RelativelySizedBox({
    required this.widthFactor,
    required this.heightFactor,
    required this.child,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return SizedBox(
      width: widthFactor * size.width,
      height: heightFactor * size.height,
      child: child,
    );
  }
}
