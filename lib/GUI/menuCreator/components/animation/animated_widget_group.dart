import 'package:flutter/material.dart';
import 'package:mpg_achievements_app/GUI/widgets/nine_patch_button.dart';
import 'package:mpg_achievements_app/components/animation/animation_style.dart';

class AnimatedWidgetGroup extends StatefulWidget {
  final List<WidgetAnimationKeyframe> keyframes;
  final bool loop;

  const AnimatedWidgetGroup({
    super.key,
    required this.keyframes,
    this.loop = false,
  });

  @override
  State<AnimatedWidgetGroup> createState() => _AnimatedWidgetGroupState();
}

class _AnimatedWidgetGroupState extends State<AnimatedWidgetGroup>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();

    _controller =
        AnimationController(
          vsync: this,
          duration: Duration(
            milliseconds:
                (widget.keyframes[_currentIndex].animationDuration * 1000)
                    .toInt(),
          ),
        )..addStatusListener((status) {
          if (status == AnimationStatus.completed) {
            _nextKeyframe();
          }
        });

    _controller.forward();
  }

  void _nextKeyframe() {
    if (_currentIndex < widget.keyframes.length - 1) {
      setState(() => _currentIndex++);
      _controller.duration = Duration(
        milliseconds: (widget.keyframes[_currentIndex].animationDuration * 1000)
            .toInt(),
      );
      _controller.forward(from: 0);
    } else if (widget.loop) {
      setState(() => _currentIndex = 0);
      _controller.duration = Duration(
        milliseconds: (widget.keyframes[_currentIndex].animationDuration * 1000)
            .toInt(),
      );
      _controller.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final current = widget.keyframes[_currentIndex];
    final nextIndex = (_currentIndex + 1) % widget.keyframes.length;
    final next = widget.keyframes[nextIndex];

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;

        final width = lerpDouble(current.width, next.width, t)!;
        final height = lerpDouble(current.height, next.height, t)!;
        final dx = lerpDouble(current.offset.dx, next.offset.dx, t)!;
        final dy = lerpDouble(current.offset.dy, next.offset.dy, t)!;

        return Transform.translate(
          offset: Offset(dx, dy),
          child: SizedBox(
            width: width,
            height: height,
            child: NinePatchButton(text: "", onPressed: () {}),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class WidgetAnimationKeyframe {
  final double width;
  final double height;
  final Offset offset;
  final double animationDuration;

  const WidgetAnimationKeyframe({
    required this.width,
    required this.height,
    required this.offset,
    required this.animationDuration,
  });
}

double? lerpDouble(double a, double b, double t) =>
    easeOut(t, startVal: a, endVal: b);
