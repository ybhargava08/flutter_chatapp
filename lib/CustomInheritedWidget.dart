import 'dart:async';

import 'package:chatapp/blocs/LastChatListener.dart';
import 'package:chatapp/blocs/UserLatestChatBloc.dart';
import 'package:chatapp/blocs/UserListener.dart';
import 'package:chatapp/blocs/ChatListener.dart';
import 'package:chatapp/model/ChatModel.dart';
import 'package:chatapp/model/UserLatestChatModel.dart';
import 'package:flutter/material.dart';

import 'package:chatapp/model/UserModel.dart';
import 'package:chatapp/blocs/UserBloc.dart';

class CustomInheritedWidget extends StatefulWidget {
  final Widget child;

  final UserModel toUser;

  CustomInheritedWidget({this.toUser, @required this.child});

  @override
  State<StatefulWidget> createState() => _CustomInheritedWidgetState();
}

class _CustomInheritedWidgetState extends State<CustomInheritedWidget> {
  UserModel _toUser;

  int _unreadMsg = 0;

  ChatModel _chatModel;

  StreamSubscription _unreadChatSubs;

  StreamSubscription _chatListenerSubs;

  @override
  void initState() {
    super.initState();

    _toUser = widget.toUser;

    listenForUserUpdates();
    listenForNewChats();
    listenForChatCounts();
  }

  listenForUserUpdates() {
    UserListener().openController(_toUser.id);
    if (UserListener().getController(_toUser.id) != null) {
      UserListener().getController(_toUser.id).stream.listen((data) {
        if (this.mounted && (_toUser == null || _toUser != data)) {
          setState(() {
            _toUser = data;
          });
        }
      });
    }
  }

  listenForChatCounts() {
    UserLatestChatBloc().openChatCountController();

    print('opening chat count listener for ' + _toUser.id);
    if (null != UserLatestChatBloc().getChatCountController()) {
      print('listening to UserLatestChatBloc controller ' + _toUser.id);
      _unreadChatSubs = UserLatestChatBloc()
          .getChatCountController()
          .stream
          .where((item) => item.toUserId.trim() == _toUser.id.trim())
          .listen((data) {
        print('got chat count data in listener ' + data.toString());
        if (UserLatestChatModel.COUNT == data.key && _unreadMsg != data.value) {
          setState(() {
            _unreadMsg = data.value;
          });
        }
      });
    }
    LastChatListener()
        .initLatestChatListeners(UserBloc().getCurrUser().id, _toUser.id);
  }

  listenForNewChats() async {
    ChatListener().openFirebaseListener(_toUser.id);
    if (ChatListener().getController(_toUser.id) != null) {
      _chatListenerSubs =
          ChatListener().getController(_toUser.id).stream.where((item) => (_chatModel == null || item.chatDate >= _chatModel.chatDate))
          .listen((data) {
        setState(() {
          _chatModel = data;
        });
      });
    }
  }

  @override
  void dispose() {
    if (_unreadChatSubs != null) {
      _unreadChatSubs.cancel();
    }
    if (_chatListenerSubs != null) {
      _chatListenerSubs.cancel();
    }
    LastChatListener().closeIndividualListener(_toUser.id);

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ActualInheritedWidget(
        user: _toUser,
        child: widget.child,
        unreadMsgCount: _unreadMsg,
        chatModel: _chatModel);
  }
}

class ActualInheritedWidget extends InheritedWidget {
  final UserModel user;

  final Widget child;

  final int unreadMsgCount;

  final ChatModel chatModel;

  ActualInheritedWidget(
      {@required this.user,
      @required this.child,
      this.unreadMsgCount,
      this.chatModel});

  @override
  bool updateShouldNotify(ActualInheritedWidget oldWidget) {
    return oldWidget.user != user ||
        chatModel != oldWidget.chatModel ||
        oldWidget.unreadMsgCount != unreadMsgCount;
  }

  static ActualInheritedWidget of(BuildContext context) {
    return context.inheritFromWidgetOfExactType(ActualInheritedWidget);
  }
}
