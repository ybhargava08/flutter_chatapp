import 'package:chatapp/model/ChatModel.dart';
import 'package:chatapp/userdetailchatview/ChatViewInheritedWrapper.dart';
import 'package:chatapp/userdetailchatview/chatelements/ChatDeliveryNotification.dart';
import 'package:chatapp/utils.dart';
import 'package:flutter/material.dart';

class ChatTextWidget extends StatelessWidget {
  final ChatModel _chat;

  ChatTextWidget(Key key, this._chat) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final inherited = ChatViewInheritedWidget.of(context);

    final currUser = inherited.currUser;

    final fontColor = inherited.textColorListItem;
    return Flex(
      direction: Axis.horizontal,
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        (!_chat.isD)
            ? Container(
                width: 0,
                height: 0,
              )
            : Container(
                margin: EdgeInsets.only(right: 5),
                child: IconTheme(
                  child: Icon(Icons.delete),
                  data: IconThemeData(color: Colors.blueGrey[500], size: 16),
                ),
              ),
        Container(
          margin: EdgeInsets.only(right: 10),
          child: Text(_chat.chat,
              style: !_chat.isD
                  ? TextStyle(
                      fontSize: 16,
                      color: (_chat.fromUserId != currUser.id)
                          ? Colors.black
                          : fontColor)
                  : TextStyle(
                      fontSize: 14,
                      color: Colors.blueGrey[500],
                      fontStyle: FontStyle.italic)),
        ),
        Text(
          Utils().getDateTimeInFormat(_chat.chatDate, 'time', 'userchatview'),
          style: TextStyle(color: Colors.blueGrey[400], fontSize: 11),
        ),
        (_chat.fromUserId == currUser.id)
            ? ChatDeliveryNotification(UniqueKey(), _chat)
            : Container(
                width: 0,
                height: 0,
              )
      ],
    );
  }
}
