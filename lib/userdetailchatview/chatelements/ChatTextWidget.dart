import 'package:chatapp/blocs/UserBloc.dart';
import 'package:chatapp/blocs/WebsocketBloc.dart';
import 'package:chatapp/database/ChatReceiptDB.dart';
import 'package:chatapp/database/SembastChat.dart';
import 'package:chatapp/model/ChatModel.dart';
import 'package:chatapp/model/WebSocModel.dart';
import 'package:chatapp/userdetailchatview/ChatViewInheritedWrapper.dart';
import 'package:chatapp/userdetailchatview/chatelements/ChatDeliveryNotification.dart';
import 'package:chatapp/utils.dart';
import 'package:flutter/material.dart';

class ChatTextWidget extends StatefulWidget {
  final ChatModel chat;

  final int index;

  final int totalLength;

  final ScrollController scrollController;

  ChatTextWidget(
      Key key, this.chat, this.index, this.totalLength, this.scrollController)
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _ChatTextWidgetState();
}

class _ChatTextWidgetState extends State<ChatTextWidget> {
  @override
  void initState() {
    if (UserBloc().getCurrUser().id == widget.chat.toUserId &&
        widget.chat.delStat != ChatModel.READ_BY_USER) {
      widget.chat.delStat = ChatModel.READ_BY_USER;
      SembastChat()
          .updateDeliveryReceipt(widget.chat.id.toString(), widget.chat.delStat)
          .then((isUpdated) {
        if (isUpdated) {
          ChatReceiptDB().upsertReceiptInDB(widget.chat).then((res) {
            WebsocketBloc().addDataToSocket(WebSocModel.RECEIPT_DEL, res);
          });
        }
      });
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final inherited = ChatViewInheritedWidget.of(context);

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
            color: (widget.chat.fromUserId != currUser.id)
                ? Colors.white
                : bgColor,
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
            Flexible(
              flex: 1,
              child: Container(
                margin: EdgeInsets.only(right: 10),
                child: Text(widget.chat.chat,
                    style: TextStyle(
                        fontSize: 16,
                        color: (widget.chat.fromUserId != currUser.id)
                            ? Colors.black
                            : fontColor)),
              ),
            ),
            Text(
              Utils().getDateTimeInFormat(
                  widget.chat.chatDate, 'time', 'userchatview'),
              style: TextStyle(color: Colors.blueGrey[400], fontSize: 11),
            ),
            (widget.chat.fromUserId == UserBloc().getCurrUser().id)
                ? ChatDeliveryNotification(UniqueKey(), widget.chat)
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
