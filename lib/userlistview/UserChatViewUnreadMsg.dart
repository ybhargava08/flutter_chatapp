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

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: 200,maxWidth: 100,minHeight: 0,minWidth: 0),
      child: Flex(
        direction: Axis.vertical,
        children: <Widget>[
          Flexible(
            flex: 5,
            child: Container(
              padding: EdgeInsets.only(top: 15),
              child: Text(
                lastChatDateTime,
                style: TextStyle(
                    fontSize: 13,
                    color: (unreadMsg <= 0)
                        ? inherited.otherColor
                        : inherited.mainColor),
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
                        color: inherited.mainColor),
                    child: Center(
                      child: Text(
                        unreadMsg.toString(),
                        style: TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.black),
                      ),
                    ))
                : Container(
                    width: 0,
                    height: 0,
                  ),
          )
        ],
      ),
    );
  }
}
