import 'dart:math';

import 'package:flutter/material.dart';

class TestAnimation extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _TestAnimationState();
}

class _TestAnimationState extends State<TestAnimation>
    with TickerProviderStateMixin {
  AnimationController _controller;


  Animation<double> _opacity;

  Animation<double> _blueTickAnim;

  Animation<Color> _color;

  @override
  void initState() {

     _controller = AnimationController(vsync: this,duration: Duration(milliseconds: 1200)); 


  _blueTickAnim= Tween<double>(begin: -pi,end: 0).animate(CurvedAnimation(
    parent: _controller,
    curve: Interval(
       0.0,1.0,
       curve: Curves.ease
    ),
  ));

  _opacity = Tween<double>(
     begin: 0,end: 1.0
  ).animate(CurvedAnimation(
      parent: _controller,
      curve: Interval(0.25 , 0.35,curve: Curves.ease)
  ));

  _color = ColorTween(begin: Colors.grey,end: Colors.tealAccent).animate(CurvedAnimation(
      parent: _controller,
      curve: Interval(
         0.25, 1.0,
         curve: Curves.ease
         )
  ));

    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
       AnimatedBuilder(
        animation: _controller,
        builder: (BuildContext context,Widget widget) {
             return 
             Transform(
                transform: Matrix4.rotationY(_blueTickAnim.value),
                alignment: FractionalOffset.center,
                child: Opacity(
                   opacity: _opacity.value,
                   child: Icon(Icons.done_all,color: _color.value,),
                )
                
             );
        },
    ),RaisedButton(
        onPressed: () {
             _controller.forward();
        },
        child: Text('click'),
        textColor: Colors.white,
        color: Colors.blue,
    )
      ],
    )
    ;
  }
}
