import 'package:chatapp/blocs/UserBloc.dart';
import 'package:chatapp/model/ChatModel.dart';
import 'package:chatapp/userdetailchatview/chatelements/ChatDeliveryNotification.dart';
import 'package:flutter/material.dart';

import 'package:chatapp/CustomInheritedWidget.dart';

class UserViewLastMsg extends StatelessWidget {
  Widget getMsgWidget(
      ChatModel chatModel, var unreadMsgCount, BuildContext context,var inherited) {
    if (null != chatModel) {
      //print('in getmsg widget  '+chatModel.toString()); 
      Widget iconType = (chatModel.chatType == ChatModel.IMAGE)
          ? Icon(Icons.photo_camera)
          : Icon(Icons.videocam);
      String txt = (chatModel.chatType == ChatModel.CHAT)?(chatModel != null) ? chatModel.chat : ""
        :(chatModel.chatType == ChatModel.IMAGE) ? 'Photo' : 'Video';
      return Flex(
        direction: Axis.horizontal,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Flexible(
              child: Container(
            margin: EdgeInsets.only(right: 3),
            child: (chatModel != null &&
                    chatModel.fromUserId == UserBloc().getCurrUser().id)
                ? ChatDeliveryNotification(UniqueKey(),chatModel)
                : Container(
                    width: 0,
                    height: 0,
                  ),
          )),
          (chatModel.chatType !=ChatModel.CHAT)?Flexible(
            child: Container(
              margin: EdgeInsets.only(right: 2),
              child: IconTheme(
                child: iconType,
                data: IconThemeData(size: 18, color: inherited.otherColor),
              ),
            ),
          ):Container(width: 0,height: 0,),
          Flexible(child: getText(txt, unreadMsgCount, context,inherited))
        ],
      );
    }
    return Container(width: 0,height: 0,); 
  }

  Widget getText(var lastMessage, var unreadMsgCount, BuildContext context,var inherited) {
    return Text(
      lastMessage,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(fontSize: 15, color: inherited.otherColor),
    );
  }

  @override
  Widget build(BuildContext context) {
    final inherited = ActualInheritedWidget.of(context);
    final chatModel = inherited.chatModel;
    final unreadMsgCount = inherited.unreadMsgCount;

    return Align(
      alignment: Alignment.topLeft,
      child: getMsgWidget(chatModel, unreadMsgCount, context,inherited),
    );
  }
}
