import 'dart:math';

import 'package:flutter/material.dart';

class AnimatedRead extends StatefulWidget {

  @override
  State<StatefulWidget> createState() => _AnimatedReadState();
}

class _AnimatedReadState extends State<AnimatedRead> with TickerProviderStateMixin{

  AnimationController _controller;


  Animation<double> _opacity;

  Animation<double> _blueTickAnim;

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

    _controller.forward();
    super.initState();
  }

  @override
  void dispose() {
    if(_controller!=null) {
        _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return  AnimatedBuilder(
        animation: _controller,
        builder: (BuildContext context,Widget widget) {
             return 
             Transform(
                transform: Matrix4.rotationY(_blueTickAnim.value),
                alignment: FractionalOffset.center,
                child: Opacity(
                   opacity: _opacity.value,
                   child: Icon(Icons.done_all,color: Colors.lightBlueAccent,size: 18),
                )
                
             );
        },
    );
  }
    
}