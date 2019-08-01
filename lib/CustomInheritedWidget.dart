import 'dart:async';

import 'package:chatapp/blocs/SingleUserBloc.dart';
import 'package:chatapp/database/SembastDatabase.dart';
import 'package:chatapp/firebase/ChatListener.dart';
import 'package:chatapp/firebase/Firebase.dart';
import 'package:chatapp/model/ChatModel.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

  StreamSubscription _chatNotSubs;

  StreamSubscription _chatListenerSubs;

  @override
  void initState() {
    super.initState();

    _toUser = widget.toUser;

    print('got to user in custom inerited widget '+_toUser.toString());

    setInitData();

   // UserBloc().initLastChatController(_toUser.id);
    
    if(ChatListener().getLatestChat(_toUser.id)!=null) {
         _chatModel = ChatListener().getLatestChat(_toUser.id);
    }
    SingleUserBloc().openController(_toUser.id);
    if(SingleUserBloc().getController(_toUser.id)!=null) {
      print('opening single user bloc stream '+_toUser.id);
         SingleUserBloc().getController(_toUser.id).stream.listen((data){
           print('got single user bloc data '+data.toString());
                if(this.mounted && (_toUser == null || _toUser!=data)) {
                      setState(() {
                       _toUser = data;
                  });
                }
                  
          });
    }
    listenForNewChats();

    _unreadChatSubs = Firebase()
        .unreadChatReference(UserBloc().getCurrUser().id)
        .document(_toUser.id)
        .snapshots()
        .listen((data) {
      if (data.exists) {
        int unreadMsgCount = data["count"];
        if (unreadMsgCount != _unreadMsg) {
          setState(() {
            _unreadMsg = unreadMsgCount;
          });
        }
      }
    });
  }

  listenForNewChats() async {
    ChatModel localLastChat =
        await SembastDatabase().getLastChatForUser(_toUser.id);
    if (null != localLastChat && localLastChat.chatType != ChatModel.CHAT) {
      print('got last chat from local ' + localLastChat.toString());

      if (_chatModel == null || _chatModel != localLastChat) {
        setState(() {
          _chatModel = localLastChat;
        });
      }
    }
    ChatListener().openFirebaseListener(_toUser.id);
    if(ChatListener().getController(_toUser.id)!=null) {
       _chatListenerSubs= ChatListener().getController(_toUser.id).stream.listen((data){
                print('listening for id '+_toUser.id+' got data '+data.toString()) ;
                setState(() {
                    _chatModel = data; 
                });
        });
    }

    /*UserBloc().getLastChatControllerStream(_toUser.id).stream.listen((data) {
      print('got data from last chat controller ' + data.toString());
      if (_chatModel == null ||
          data.fbId > _chatModel.fbId ||
          (data.fbId == _chatModel.fbId &&
              data.delStat != _chatModel.delStat)) {
        setState(() {  
          _chatModel = data;
        });
      }
    });*/
  }


  setInitData() async {
    try {
      DocumentSnapshot ds = await Firebase()
          .unreadChatReference(UserBloc().getCurrUser().id)
          .document(_toUser.id)
          .get();

      if (ds != null && ds.exists) {
        int unreadMsgCount = ds["count"];
        if (unreadMsgCount != _unreadMsg) {
          setState(() {
            _unreadMsg = unreadMsgCount;
          });
        }
      }
    } on Exception catch (e) {
      print('got error while retriving doc from fb ' + e.toString());
    }
  }

  @override
  void dispose() {
   // UserBloc().closeLastChatController(_toUser.id);
    /* if (_userSubs != null) {
      _userSubs.cancel();
    } */
    if (_unreadChatSubs != null) {
      _unreadChatSubs.cancel();
    }
    /* if (_chatReceiveSubs != null) {
      _chatReceiveSubs.cancel();
    } */
    if (_chatNotSubs != null) {
      _chatNotSubs.cancel();
    }
    if(_chatListenerSubs!=null) {
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