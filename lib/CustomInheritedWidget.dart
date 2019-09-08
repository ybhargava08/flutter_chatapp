import 'dart:async';
import 'dart:convert';

import 'package:chatapp/blocs/UserLatestChatBloc.dart';
import 'package:chatapp/blocs/UserListener.dart';
import 'package:chatapp/blocs/ChatListener.dart';
import 'package:chatapp/model/ChatModel.dart';
import 'package:chatapp/model/UserLatestChatModel.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

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

  int _unreadMsg=0;

  ChatModel _chatModel;

  StreamSubscription _unreadChatSubs;

  StreamSubscription _chatListenerSubs;

  @override
  void initState() {
    super.initState();

    _toUser = widget.toUser;

    listenForUserUpdates();
    listenForNewChats();
    getInitChatCount();
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

  getInitChatCount() async {
        String uri  = 'https://chatapp-socketio-server.herokuapp.com/getUnreadChatCount?fromUserId='+_toUser.id+'&toUserId='
          +UserBloc().getCurrUser().id;
         var response = await http.get(uri);
          Map<String,dynamic> responseData = jsonDecode(response.body);
          setState(() {
            _unreadMsg = responseData['count'];
          });    
         listenForChatCounts();
  }

  listenForChatCounts() {
    if (null != UserLatestChatBloc().getChatCountController()) {
      _unreadChatSubs = UserLatestChatBloc()
          .getChatCountController()
          .stream
          .where((item) => item.toUserId.trim().compareTo(_toUser.id.trim()) == 0)
          .listen((data) {
        if (UserLatestChatModel.COUNT == data.key && (_unreadMsg+data.value >=0)) {
          setState(() {
            _unreadMsg = _unreadMsg+data.value;
          });
        }
      });
    }
  }

  listenForNewChats() async {
    ChatListener().openFirebaseListener(_toUser.id);
    if (ChatListener().getController(_toUser.id) != null) {
      _chatListenerSubs =
          ChatListener().getController(_toUser.id).stream.listen((data) {
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

  final Color mainColor = Colors.black;
  final Color otherColor = Colors.grey[700];

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
