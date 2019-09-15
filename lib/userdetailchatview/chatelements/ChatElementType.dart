import 'dart:async';

import 'package:chatapp/blocs/ChatUpdateBloc.dart';
import 'package:chatapp/blocs/UserBloc.dart';
import 'package:chatapp/blocs/WebsocketBloc.dart';
import 'package:chatapp/database/ChatReceiptDB.dart';
import 'package:chatapp/database/OfflineDBChat.dart';
import 'package:chatapp/model/ChatModel.dart';
import 'package:chatapp/model/UserModel.dart';
import 'package:chatapp/model/WebSocModel.dart';
import 'package:chatapp/userdetailchatview/ChatViewInheritedWrapper.dart';
import 'package:flutter/material.dart';

class ChatElementType extends StatefulWidget {
  final ChatModel chat;
  final Widget child;

  ChatElementType(Key key, this.child, this.chat) : super(key: key);

  @override
  State<StatefulWidget> createState() => _ChatElementTypeState();
}

class _ChatElementTypeState extends State<ChatElementType> with SingleTickerProviderStateMixin{
  ChatModel _chat;

  StreamSubscription _subs;

  AnimationController _controller;

  Animation _animation;

  _doAnimate() {
       Color endColor = (_chat.fromUserId == UserBloc().getCurrUser().id)?Colors.lightBlue[50]:Colors.white;
       _controller = AnimationController(vsync: this,duration: Duration(milliseconds: 1000));
       _animation = ColorTween(begin: Colors.redAccent,end: endColor).animate(_controller);
       _controller.forward();
  }

  @override
  void initState() {
    _chat = widget.chat;
    if (ChatUpdateBloc().getChatUpdateController() != null) {
      _subs = ChatUpdateBloc()
          .getChatUpdateController()
          .stream
          .where((item) => (item.id == _chat.id && item != _chat))
          .listen((data) {
        data.doDeleteAnimation = data.isD;
        if(data.doDeleteAnimation) {
          _doAnimate();
        }
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
      OfflineDBChat()
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

  Widget _getChatWithBGColor(double h,double w,UserModel currUser,Color bgColor) {
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
            child: ChatInheritedWidget(chat: _chat, child: widget.child),
            ),
         );
  }

  @override
  Widget build(BuildContext context) {
    final inherited = ChatViewInheritedWidget.of(context);
    final bgColor = inherited.backgroundListItemColor;
    final currUser = inherited.currUser;

     double h = MediaQuery.of(context).size.height;
    double w = MediaQuery.of(context).size.width;

    if(_chat.chatType == ChatModel.CHAT) {
         return (_chat.doDeleteAnimation && null!=_animation)?
         AnimatedBuilder(
             animation: _animation,
             builder: (context,child){
                 return _getChatWithBGColor(h,w,currUser,_animation.value);
             },
         ):_getChatWithBGColor(h,w,currUser,(_chat.fromUserId == currUser.id)?bgColor:Colors.white);
    }else{
      return ChatInheritedWidget(chat: _chat, child: widget.child);
    }
    
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
