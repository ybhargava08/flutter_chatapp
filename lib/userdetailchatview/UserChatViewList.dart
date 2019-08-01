import 'dart:async';

import 'package:chatapp/blocs/ChatBloc.dart';
import 'package:chatapp/blocs/UserBloc.dart';
import 'package:chatapp/firebase/Firebase.dart';
import 'package:chatapp/model/ChatModel.dart';
import 'package:chatapp/userdetailchatview/GeneralNotificationWidget.dart';
import 'package:chatapp/userdetailchatview/chatelements/ChatMediaWidget.dart';
import 'package:chatapp/userdetailchatview/chatelements/ChatTextWidget.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:chatapp/userdetailchatview/ChatViewInheritedWrapper.dart';
import 'package:chatapp/utils.dart';

class UserChatViewList extends StatefulWidget {
  final String toUserId;

  UserChatViewList(this.toUserId);

  @override
  State<StatefulWidget> createState() => _UserChatViewListState();
}

class _UserChatViewListState extends State<UserChatViewList> {
  Map<String, bool> _dateShownMap = Map();

  //List<ChatModel> _markedChatAsRead = List();

  ScrollController _scrollController;

  @override
  void initState() {
    _scrollController = ScrollController();


    _scrollController.addListener(() {
     // print('last scroll offset is '+_scrollController.offset.toString());
    
      FocusScope.of(context).requestFocus(FocusNode());

      if (_scrollController.position.pixels <=
          _scrollController.position.minScrollExtent) {
        ChatBloc().getMoreData(widget.toUserId);
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    _scrollController.removeListener(() {
      
      _scrollController.dispose();
    });
    super.dispose();
  }

  void scrollToPos(double pos, bool isAnimate) {
      Timer(Duration(milliseconds: 100), () {
            if (_scrollController.hasClients) {
          if (isAnimate) {
            _scrollController.animateTo(pos,
                duration: Duration(milliseconds: 500), curve: Curves.ease);
          } else {
            _scrollController.jumpTo(pos);
          }
        }
      });
        
  }

  Widget getChatType(ChatModel chat,int index,int totalLength) {
    if (chat.chatType == ChatModel.CHAT) {
      return ChatTextWidget(ValueKey(chat.id), chat,index,totalLength,_scrollController);
    } else if (chat.chatType == ChatModel.IMAGE ||
        chat.chatType == ChatModel.VIDEO) {
      return ChatMediaWidget(ValueKey(chat.id), chat,index,totalLength,_scrollController);
    }
    return Container(
      width: 0,
      height: 0,
    );
  }

  Widget buildListElement(ChatModel currChat, var currUser,int index,int totalLength) {
    return Align(
        alignment: (currChat.fromUserId == currUser.id)
            ? Alignment.centerRight
            : Alignment.centerLeft,
        child: getChatType(currChat,index,totalLength));
  }

  checkIfDateShown(String date) {
    String datePart = date.substring(0, date.indexOf(' '));
    return _dateShownMap.containsKey(datePart) && _dateShownMap[datePart];
  }

  Widget loaderList() {
    return ListView.builder(
      itemBuilder: (BuildContext context, int index) {
        return Center(
          child: CircularProgressIndicator(),
        );
      },
      itemCount: 1,
    );
  }

  Widget emptyList() {
    return ListView.builder(
      itemBuilder: (BuildContext context, int index) {
        return Container(width: 0, height: 0);
      },
      itemCount: 0,
    );
  }

  @override
  Widget build(BuildContext context) {
    final inherited = ChatViewInheritedWidget.of(context);

    final currUser = inherited.currUser;

    return StreamBuilder<List<ChatModel>>(
      stream: ChatBloc().getChatStream(),
      initialData: [],
      builder: (BuildContext context, AsyncSnapshot<List<ChatModel>> snapshot) {
        if (snapshot.hasData) {
          _dateShownMap.clear();
        //  _markedChatAsRead.clear();
          return ListView.builder(
            controller: _scrollController,
            shrinkWrap: false,
              
            
            itemBuilder: (BuildContext context, int index) {
             /* if (UserBloc().getCurrUser().id ==
                      snapshot.data[index].toUserId &&
                  snapshot.data[index].delStat != ChatModel.READ_BY_USER) {
                print('adding chat to list ' + snapshot.data[index].chat);
                snapshot.data[index].delStat = ChatModel.READ_BY_USER;
                _markedChatAsRead.add(snapshot.data[index]);
              }
              if (index == snapshot.data.length - 1 &&
                  snapshot.data[index] != null) {
                if (_markedChatAsRead.length > 0) {
                  Firebase().markChatsAsReadOrDelivered(widget.toUserId,
                      _markedChatAsRead, true, ChatModel.READ_BY_USER);
                }      
              }*/

              ChatModel currChat = snapshot.data[index];
              if (!checkIfDateShown(currChat.chatDate)) {
                _dateShownMap[currChat.chatDate
                    .substring(0, currChat.chatDate.indexOf(' '))] = true;
                return Flex(
                  direction: Axis.vertical,
                  children: <Widget>[
                    Center(
                        child: GeneralNotificationWidget(Utils()
                            .getDateTimeInFormat(
                                currChat.chatDate, 'date', 'userchatview'))),
                    buildListElement(currChat, currUser,index,snapshot.data.length)
                  ],
                );
              } else {
                return buildListElement(currChat, currUser,index,snapshot.data.length);
              }
            },
            itemCount: snapshot.data.length,
          );
        } else if (snapshot.connectionState == ConnectionState.waiting) {
          return loaderList();
        } else if (snapshot.connectionState == ConnectionState.done) {
          return emptyList();
        } else if (snapshot.hasError) {
          return Center(
            child: Text('Oops problem occurred !!'),
          );
        }
        return emptyList();
      },
    );
  }
}
