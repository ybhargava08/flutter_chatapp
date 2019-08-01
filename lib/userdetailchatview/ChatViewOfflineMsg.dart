import 'package:chatapp/userdetailchatview/ChatViewInheritedWrapper.dart';

import 'package:flutter/material.dart';

class ChatViewOfflineMsg extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var inherited = ChatViewInheritedWidget.of(context);
    final user = inherited.toUser;

    return /* (!user.isOnline)
        ? GeneralNotificationWidget( user.name + ' is offline')
        : Container(
            width: 0,
            height: 0,
          ); */Container(width: 0,height: 0,);
  }
}
