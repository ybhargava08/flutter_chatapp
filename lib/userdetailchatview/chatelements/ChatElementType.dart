import 'dart:async';

import 'package:chatapp/blocs/ChatUpdateBloc.dart';
import 'package:chatapp/blocs/UserBloc.dart';
import 'package:chatapp/blocs/WebsocketBloc.dart';
import 'package:chatapp/database/ChatReceiptDB.dart';
import 'package:chatapp/database/SembastChat.dart';
import 'package:chatapp/model/ChatModel.dart';
import 'package:chatapp/model/WebSocModel.dart';
import 'package:flutter/material.dart';

class ChatElementType extends StatefulWidget {
  final ChatModel chat;
  final Widget child;

  ChatElementType(Key key, this.child, this.chat) : super(key: key);

  @override
  State<StatefulWidget> createState() => _ChatElementTypeState();
}

class _ChatElementTypeState extends State<ChatElementType> {
  ChatModel _chat;

  StreamSubscription _subs;

  @override
  void initState() {
    _chat = widget.chat;
    if (ChatUpdateBloc().getChatUpdateController() != null) {
      _subs = ChatUpdateBloc()
          .getChatUpdateController()
          .stream
          .where((item) => (item.id == _chat.id && item != _chat))
          .listen((data) {
        print('setting chat in chat element type ' + data.toString());
        setState(() {
          _chat = data;
        });
      });
    }
    _markChatRead();
    super.initState();
  }

  _markChatRead() {
    if (!_chat.isD &&
        UserBloc().getCurrUser().id == _chat.toUserId &&
        _chat.delStat != ChatModel.READ_BY_USER) {
      _chat.delStat = ChatModel.READ_BY_USER;
      SembastChat()
          .updateDeliveryReceipt(_chat.id.toString(), _chat.delStat)
          .then((isUpdated) {
        if (isUpdated) {
          ChatReceiptDB().upsertReceiptInDB(_chat).then((res) {
            WebsocketBloc().addDataToSocket(WebSocModel.RECEIPT_DEL, res);
          });
        }
      });
    }
  }

  @override
  void dispose() {
    if (null != _subs) {
      _subs.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChatInheritedWidget(chat: _chat, child: widget.child);
  }
}

class ChatInheritedWidget extends InheritedWidget {
  final ChatModel chat;

  final Widget child;

  ChatInheritedWidget({@required this.chat, @required this.child});

  @override
  bool updateShouldNotify(ChatInheritedWidget oldWidget) {
    return oldWidget.chat != chat;
  }

  static ChatInheritedWidget of(BuildContext context) {
    return context.inheritFromWidgetOfExactType(ChatInheritedWidget);
  }
}
