import 'package:flutter/material.dart';

import 'package:chatapp/CustomInheritedWidget.dart';

class UserViewOnlineInd extends StatelessWidget {

     @override
  Widget build(BuildContext context) {
    final inherited = ActualInheritedWidget.of(context);

    final user = inherited.user;

    return      Align(
                          alignment: Alignment.bottomRight,
                          child: Container(
                            width:18,
                            height: 18,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(50.0),
                              border: Border.all(width: 2.0,color: Colors.white),
                              color: (/* user.isOnline */false)?Colors.lightGreenAccent[400]:Colors.blueGrey[100] 
                            ),
                          )
                );
  }
}