import 'package:chatapp/CustomInheritedWidget.dart';

import 'package:flutter/material.dart';

class UserViewName extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final inherited = ActualInheritedWidget.of(context);

    final user = inherited.user;

    return Container(
        margin: EdgeInsets.only(bottom: 5),
        child: Text(
      user.name,
      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,color: inherited.mainColor),
    ),
    );
  }
}
