import 'package:chatapp/blocs/UserBloc.dart';
import 'package:chatapp/userdetailchatview/ChatViewInheritedWrapper.dart';
import 'package:chatapp/userdetailchatview/chatelements/ChatDeliveryNotification.dart';
import 'package:chatapp/userdetailchatview/chatelements/ChatElementType.dart';
import 'package:chatapp/utils.dart';
import 'package:flutter/material.dart';

class ChatTextWidget extends StatelessWidget {
  ChatTextWidget(Key key) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final inherited = ChatViewInheritedWidget.of(context);

    final inheritedChat = ChatInheritedWidget.of(context);

    final _chat = inheritedChat.chat;

    final currUser = inherited.currUser;

    final bgColor = inherited.backgroundListItemColor;
    final fontColor = inherited.textColorListItem;

    var h = MediaQuery.of(context).size.height;
    var w = MediaQuery.of(context).size.width;

    return ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: 0.0,
        maxWidth: 0.79 * ((h < w) ? h : w),
      ),
      child: Container(
        margin: EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 10.0),
        padding: EdgeInsets.all(7.0),
        decoration: BoxDecoration(
            color: (_chat.fromUserId != currUser.id) ? Colors.white : bgColor,
            borderRadius: BorderRadius.circular(5.0),
            boxShadow: [
              BoxShadow(
                  color: Colors.grey, blurRadius: 1, offset: Offset(1.0, 1.0))
            ]),
        child: Flex(
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
                      data:
                          IconThemeData(color: Colors.blueGrey[500], size: 16),
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
              Utils()
                  .getDateTimeInFormat(_chat.chatDate, 'time', 'userchatview'),
              style: TextStyle(color: Colors.blueGrey[400], fontSize: 11),
            ),
            (_chat.fromUserId == UserBloc().getCurrUser().id)
                ? ChatDeliveryNotification(UniqueKey(), _chat)
                : Container(
                    width: 0,
                    height: 0,
                  )
          ],
        ),
      ),
    );
  }
}
