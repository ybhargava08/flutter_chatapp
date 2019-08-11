import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:chatapp/CustomInheritedWidget.dart';

class UserViewAvatar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final inherited = ActualInheritedWidget.of(context);

    if(null == inherited) {
        return Container(width: 0,height: 0,);
    }

    final user = inherited.user;

    return ((user.photoUrl != null))
        ? Container(
          width: 50,
          height: 50,
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                image: DecorationImage(
                    fit: BoxFit.fill,
                    image: CachedNetworkImageProvider(user.photoUrl))))
        : Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.blueGrey[100], width: 1.0),
                image: DecorationImage(
                    image: AssetImage('assets/images/placeholder_acc.png'))),
          );
  }
}
