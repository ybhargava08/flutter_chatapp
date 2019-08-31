import 'dart:async';

import 'package:chatapp/blocs/ChatReceiptListener.dart';
import 'package:chatapp/blocs/NotificationBloc.dart';
import 'package:chatapp/blocs/UserBloc.dart';
import 'package:chatapp/database/SembastChat.dart';
import 'package:chatapp/model/ChatModel.dart';
import 'package:chatapp/userdetailchatview/chatelements/AnimatedRead.dart';
import 'package:flutter/material.dart';

class ChatDeliveryNotification extends StatefulWidget {
  final ChatModel chat;

  ChatDeliveryNotification(Key key, this.chat) : super(key: key);
  @override
  State<StatefulWidget> createState() => _ChatDeliveryNotificationState();
}

class _ChatDeliveryNotificationState extends State<ChatDeliveryNotification>
    with TickerProviderStateMixin {
  String _deliveryState;

  bool _doAnimation = false;

  StreamSubscription _subs;

  StreamSubscription _delSubs;

  @override
  void initState() {
    super.initState();

    _deliveryState = widget.chat.delStat;
    if (widget.chat.delStat != ChatModel.READ_BY_USER) {
      listenForNotificationChanges();
    }
  }

  listenForNotificationChanges() {
    _subs = NotificationBloc()
        .getNotificationController()
        .stream
        .where((item) => item.chatId == widget.chat.id)
        .listen((data) {
      /*print('got data ' +
          data.status +
          ' in notifcation listener ' +
          widget.chat.toString());*/
      if (data.status.compareTo(_deliveryState) > 0) {
        widget.chat.delStat = data.status;
        SembastChat().upsertInChatStore(widget.chat, 'delivery notification');
        setState(() {
          _deliveryState = data.status;
          _doAnimation = true;
        });
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    if (null != _subs) {
      _subs.cancel();
    }
    if (null != _delSubs) {
      _delSubs.cancel();
    }
  }

  Widget getDoneAllRead() {
    return IconTheme(
      child: Icon(Icons.done_all),
      data: IconThemeData(color: Colors.lightBlueAccent, size: 18),
    );
  }

  Widget getIcon() {
    if (_deliveryState == ChatModel.DELIVERED_TO_LOCAL) {
      return IconTheme(
        child: Icon(Icons.access_time),
        data: IconThemeData(color: Colors.blueGrey[300], size: 18),
      );
    } else if (_deliveryState == ChatModel.DELIVERED_TO_SERVER) {
      return IconTheme(
        child: Icon(Icons.done),
        data: IconThemeData(color: Colors.blueGrey[300], size: 18),
      );
    } else if (_deliveryState == ChatModel.DELIVERED_TO_USER) {
      return IconTheme(
        child: Icon(Icons.done_all),
        data: IconThemeData(color: Colors.blueGrey[300], size: 18),
      );
    } else if (_deliveryState == ChatModel.READ_BY_USER) {
      return _doAnimation ? AnimatedRead() : getDoneAllRead();
    } else {
      return Container(
        width: 0,
        height: 0,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(left: 5),
      child: getIcon(),
    );
  }
}
