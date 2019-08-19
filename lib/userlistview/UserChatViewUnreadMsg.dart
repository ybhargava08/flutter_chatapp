import 'package:chatapp/utils.dart';
import 'package:flutter/material.dart';

import 'package:chatapp/CustomInheritedWidget.dart';

class UserChatViewUnreadMsg extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final inherited = ActualInheritedWidget.of(context);

    final unreadMsg = inherited.unreadMsgCount;

    final chatModel = inherited.chatModel;

    final lastChatDateTime = (chatModel != null)
        ? Utils().getDateTimeInFormat(chatModel.chatDate, 'date', 'userview')
        : "";

    return Flex(
      direction: Axis.vertical,
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: <Widget>[
        Flexible(
          child: Container(
            padding: EdgeInsets.only(top:15),
            child: Text(
              lastChatDateTime,
              style: TextStyle(
                  fontSize: 13,
                  color: (unreadMsg <= 0)
                      ? inherited.otherColor
                      : Theme.of(context).accentColor),
            ),
          ),
        ),
        Flexible(
          child: (unreadMsg > 0)
              ? Container(
                  width: 20,
                  height: 20,
                  margin: EdgeInsets.only(top: 4.0),
                  alignment: Alignment.bottomLeft,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(50.0),
                      color: Theme.of(context).accentColor),
                  child: Center(
                    child: Text(
                      unreadMsg.toString(),
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ))
              : Container(
                  width: 0,
                  height: 0,
                ),
        )
      ],
    );
  }
}
