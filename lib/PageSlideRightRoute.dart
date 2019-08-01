import 'package:flutter/material.dart';

class PageSlideRightRoute extends PageRouteBuilder {
       final Widget widget;
       PageSlideRightRoute({this.widget}):
       super(
         pageBuilder:(BuildContext context, Animation<double> animation,Animation<double> secondAnimation) {
            return widget;
         },
         transitionsBuilder:(BuildContext context, Animation<double> animation,
          Animation<double> secondAnimation,Widget widget) {
              return SlideTransition(
                  position: Tween<Offset>(
                       begin: Offset(-1.0,0.0),
                       end: Offset.zero
                  ).animate(animation),
                  child: widget,
              );
          }
       );
}