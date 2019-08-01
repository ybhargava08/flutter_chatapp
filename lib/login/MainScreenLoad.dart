import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class MainScreenLoad extends StatefulWidget {
  final int numOfDots;

  final int duration;

  MainScreenLoad(this.numOfDots, this.duration);

  @override
  State<StatefulWidget> createState() => _MainScreenLoadState();
}

class _MainScreenLoadState extends State<MainScreenLoad>
    with TickerProviderStateMixin {
  AnimationController _controller;

  List<Animation<double>> _animations;

  @override
  void initState() {
    double parts = 1 / (widget.numOfDots + 1);
    _controller = AnimationController(
        vsync: this, duration: Duration(milliseconds: widget.duration))
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _controller.repeat();
        }
      });
    _animations = List.generate(widget.numOfDots, (int i) {
      double beg = (i) * parts;

      double end = beg + parts;

      return Tween<double>(begin: 0, end: 15).animate(CurvedAnimation(
          parent: _controller,
          curve: Interval(beg, end, curve: Curves.easeInOutQuad)));
    });
    _controller.forward();
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<Widget> buildList() {
    return List.generate(widget.numOfDots, (int i) {
      return Container(
        width: _animations[i].value,
        height: _animations[i].value,
        decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.cyan[400]),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: buildList(),
        );
      },
    );
  }
}
