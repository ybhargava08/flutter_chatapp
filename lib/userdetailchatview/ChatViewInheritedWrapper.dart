import 'dart:async';

import 'package:chatapp/blocs/ChatBloc.dart';
import 'package:chatapp/blocs/ChatDeleteBloc.dart';
import 'package:chatapp/blocs/ProgressBloc.dart';
import 'package:chatapp/blocs/UserBloc.dart';
import 'package:chatapp/blocs/UserListener.dart';
import 'package:chatapp/blocs/ChatListener.dart';
import 'package:chatapp/blocs/WebsocketBloc.dart';
import 'package:chatapp/model/UserModel.dart';
import 'package:chatapp/model/WebSocModel.dart';

import 'package:flutter/material.dart';

class ChatViewInheritedWrapper extends StatefulWidget {
  final UserModel toUser;

  final Widget child;

  ChatViewInheritedWrapper({@required this.child, @required this.toUser});

  @override
  State<StatefulWidget> createState() => _ChatViewInheritedWrapperState();
}

class _ChatViewInheritedWrapperState extends State<ChatViewInheritedWrapper> {
  UserModel _toUser;

  UserModel _currUser;

  StreamSubscription _toUserSubs;

  StreamSubscription _singleUserListener;

  bool _typingInd = false;

  Timer _typingTimer;
  
  static const int TYPING_IND_DURATION = 4;

  @override
  void initState() {
    super.initState();
    _toUser = widget.toUser;
    _currUser = UserBloc().getCurrUser();

   ChatDeleteBloc().openController(); 

    ChatBloc().addOpenScreenId(_toUser.id);
    ChatBloc().initChatController();
    ProgressBloc().openProgressController();

    init();

    _listenForTypingInd();

    if (UserListener().getController(_toUser.id) != null) {
      _singleUserListener =
          UserListener().getController(_toUser.id).stream.listen((data) {
        if (this.mounted && (_toUser == null || _toUser != data)) {
          setState(() {
            _toUser = data;
          });
        }
      });
    }
  }

  _listenForTypingInd() {
    WebsocketBloc().getStreamController().stream.where((item) => item.fromUserId == _toUser.id).listen((data) {
      if (data.type == WebSocModel.TYPING &&
          (_typingTimer == null || !_typingTimer.isActive)) {
        if (this.mounted) {
          setState(() {
            _typingInd = true;
          });
        }

        _typingTimer = Timer(Duration(seconds: TYPING_IND_DURATION), () {
          if (this.mounted) {
            setState(() {
              _typingInd = false;
            });
          }
        });
      }
    });
  }

  init() async {
    int maxChatId = await ChatListener().getInitChatList(_toUser.id);
    ChatListener().listenForNewAddedChats(_toUser.id, maxChatId);
  }

  @override
  Widget build(BuildContext context) {
    return ChatViewInheritedWidget(
      child: widget.child,
      currUser: _currUser,
      toUser: _toUser,
      typingInd: _typingInd,
    );
  }

  @override
  void dispose() {
    ChatBloc().closeChatController();
    ChatBloc().closeOpenScreenId(_toUser.id);
    ProgressBloc().closeProgressController();
    if (_toUserSubs != null) {
      _toUserSubs.cancel();
    }
    ChatListener().closeChatDeliveryAndNewAddedListener();
    if (_singleUserListener != null) {
      _singleUserListener.cancel();
    }
    ChatListener().setDbCountPrefAtClose(_toUser.id);
    if (null != _typingTimer) {
      _typingTimer.cancel();
    }
    ChatDeleteBloc().closeController();

    super.dispose();
  }
}

class ChatViewInheritedWidget extends InheritedWidget {
  final UserModel toUser;

  final UserModel currUser;

  final Widget child;

  final bool typingInd;

  final Color backgroundListItemColor = Colors.lightBlue[50];
  final Color textColorListItem = Colors.blueGrey[800];

  ChatViewInheritedWidget(
      {@required this.child,
      @required this.toUser,
      @required this.currUser,
      @required this.typingInd});

  @override
  bool updateShouldNotify(ChatViewInheritedWidget oldWidget) {
    return true;
  }

  static ChatViewInheritedWidget of(BuildContext context) {
    return context.inheritFromWidgetOfExactType(ChatViewInheritedWidget);
  }
}
