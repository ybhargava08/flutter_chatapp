import 'dart:async';

import 'package:chatapp/blocs/ChatBloc.dart';
import 'package:chatapp/blocs/NotificationBloc.dart';
import 'package:chatapp/blocs/ProgressBloc.dart';
import 'package:chatapp/blocs/UserBloc.dart';
import 'package:chatapp/blocs/UserListener.dart';
import 'package:chatapp/database/DBConstants.dart';
import 'package:chatapp/database/SembastDatabase.dart';
import 'package:chatapp/firebase/Firebase.dart';
import 'package:chatapp/model/ChatModel.dart';
import 'package:chatapp/model/UserModel.dart';
import 'package:chatapp/utils.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  StreamSubscription _deliverySubs;

  StreamSubscription _newChatSubs;

  SharedPreferences _prefs;

  StreamSubscription _singleUserListener;

  @override
  void initState() {
    super.initState();
    _toUser = widget.toUser;
    _currUser = UserBloc().getCurrUser();

    ChatBloc().addOpenScreenId(_toUser.id);
    ChatBloc().initChatController();
    ProgressBloc().openProgressController();


    init();

    if(UserListener().getController(_toUser.id)!=null) {
         _singleUserListener= UserListener().getController(_toUser.id).stream.listen((data){
                if(this.mounted && (_toUser == null || _toUser!=data)) {
                      setState(() {
                       _toUser = data;
                  });
                }
                  
          });
    }

  }

  listenForChatDelivery() {
    _deliverySubs = Firebase()
        .getChatCollectionRef(
            Utils().getChatCollectionId(UserBloc().getCurrUser().id, _toUser.id),
            Firebase.CHAT_COL_COMPLETE)
        .where('fromUserId', isEqualTo: UserBloc().getCurrUser().id)
        .where('delStat', isLessThanOrEqualTo: ChatModel.READ_BY_USER)
        .snapshots()
        .listen((data) {
      data.documentChanges.forEach((change) {
        if (change.type == DocumentChangeType.modified) {
          data.documents.forEach((snapshot) {
            ChatModel c = ChatModel.fromDocumentSnapshot(snapshot);
            print('got data from chat delivery listener ' + c.toString());
            NotificationBloc().addToNotificationController(c.id, c.delStat);
          });
        }
      });
    });
  }

  listenForNewAddedChats() {
    _newChatSubs = Firebase()
        .getChatCollectionRef(
            Utils().getChatCollectionId(UserBloc().getCurrUser().id, _toUser.id),
            Firebase.CHAT_COL_COMPLETE)
        .where('toUserId', isEqualTo: UserBloc().getCurrUser().id)
        .where('delStat', isEqualTo: ChatModel.DELIVERED_TO_SERVER)
        .snapshots()
        .listen((data) {
      data.documentChanges.forEach((change) {
        if (change.type == DocumentChangeType.added) {
          if (data != null && data.documents.length > 0) {
            data.documents.forEach((snapshot) {
              ChatModel c = ChatModel.fromDocumentSnapshot(snapshot);
              print('got to user chat ' + c.toString());
              if (c.toUserId == UserBloc().getCurrUser().id &&
                  c.delStat != ChatModel.READ_BY_USER) {
                c.fbId = DateTime.now().microsecondsSinceEpoch;
              }
              ChatBloc().addInChatController(c);
              //UserBloc().addToLastChatController(_toUser.id, c);
            });
          }
        }
      });
    });
  }

  init() async {
    await getInitChatList();
    listenForNewAddedChats();
    listenForChatDelivery();
  }

  getInitChatList() async {
    if (null == _prefs) {
      _prefs = await SharedPreferences.getInstance();
    }

    int chatLength =
        _prefs.getInt(_toUser.id) ?? DBConstants.DATA_RETREIVE_COUNT;
    QuerySnapshot chatComplete = await Firebase()
        .getChatCollectionRef(
            Utils().getChatCollectionId(UserBloc().getCurrUser().id, _toUser.id),
            Firebase.CHAT_COL_COMPLETE)
        .orderBy("fbId", descending: true)
        .limit(chatLength)
        .getDocuments();

    List<ChatModel> completeList = List();

    if (chatComplete != null && chatComplete.documents.length > 0) {
      completeList = chatComplete.documents
          .map((item) => ChatModel.fromDocumentSnapshot(item))
          .toList();
    }
    print(
        'init list from firebase after compare id ' + completeList.toString());
    List<ChatModel> localList =
        await SembastDatabase().getDataFromStore(_toUser.id);
    if (null != localList && localList.length > 0) {
      completeList.addAll(localList);
    }
    if (null != completeList && completeList.length > 0) {
      ChatBloc().setInitList(completeList);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChatViewInheritedWidget(
      child: widget.child,
      currUser: _currUser,
      toUser: _toUser,
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
    if (_newChatSubs != null) {
      _newChatSubs.cancel();
    }
    if (_deliverySubs != null) {
      _deliverySubs.cancel();
    }
    if(_singleUserListener!=null) {
        _singleUserListener.cancel();
    }
    _prefs.setInt(
        _toUser.id,
        ChatBloc().getChatListLength() <= DBConstants.DATA_RETREIVE_COUNT
            ? DBConstants.DATA_RETREIVE_COUNT
            : ChatBloc().getChatListLength());
    super.dispose();
  }
}

class ChatViewInheritedWidget extends InheritedWidget {
  final UserModel toUser;

  final UserModel currUser;

  final Widget child;

  final Color backgroundListItemColor = Colors.lightBlue[50];
  final Color textColorListItem = Colors.blueGrey[800];

  ChatViewInheritedWidget(
      {@required this.child, @required this.toUser, @required this.currUser});

  @override
  bool updateShouldNotify(ChatViewInheritedWidget oldWidget) {
    return true;
  }

  static ChatViewInheritedWidget of(BuildContext context) {
    return context.inheritFromWidgetOfExactType(ChatViewInheritedWidget);
  }
}
