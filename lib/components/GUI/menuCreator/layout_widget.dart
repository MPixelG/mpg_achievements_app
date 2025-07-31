import 'package:flutter/cupertino.dart';

class LayoutWidget{
  final List<LayoutWidget> children = [];
  final Widget Function(BuildContext context, List<LayoutWidget> children, Map<String, dynamic> properties) _builder;
  Map<String, dynamic> properties;

  LayoutWidget(this._builder, {this.properties = const {}});

  void addChild(LayoutWidget child) {
    children.add(child);
  }

  Widget build(BuildContext context) => _builder(context, children, properties);

  void removeChild(LayoutWidget child) => children.remove(child);
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