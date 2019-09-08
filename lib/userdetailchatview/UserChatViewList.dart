import 'package:chatapp/blocs/ChatBloc.dart';
import 'package:chatapp/model/ChatModel.dart';
import 'package:chatapp/model/UserModel.dart';
import 'package:chatapp/userdetailchatview/ChatListDate.dart';
import 'package:chatapp/userdetailchatview/chatelements/ChatElementSelection.dart';
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

  ScrollController _scrollController;

  @override
  void initState() {
    _scrollController = ScrollController();

    _scrollController.addListener(() {
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

  Widget getChatType(ChatModel chat, int index, int totalLength) {
    if (chat.chatType == ChatModel.CHAT) {
      return ChatTextWidget(
          ValueKey(chat.id), chat, index, totalLength, _scrollController);
    } else if (chat.chatType == ChatModel.IMAGE ||
        chat.chatType == ChatModel.VIDEO) {
      return ChatMediaWidget(
          ValueKey(chat.id), chat, index, totalLength, _scrollController);
    }
    return Container(
      width: 0,
      height: 0,
    );
  }

  Widget buildListElement(
      ChatModel currChat, var currUser, int index, int totalLength) {
    return IntrinsicHeight(
      child: Stack(
        children: <Widget>[
          Align(
            alignment: (currChat.fromUserId == currUser.id)
                ? Alignment.centerRight
                : Alignment.centerLeft,
            child: getChatType(currChat, index, totalLength),
          ),
          ChatElementSelection(currChat)
        ],
      ),
    );
  }

  checkIfDateShown(int ts) {
    String datePart = getDatePart(ts);

    return _dateShownMap.containsKey(datePart) && _dateShownMap[datePart];
  }

  String getDatePart(int ts) {
    DateTime date = DateTime.fromMillisecondsSinceEpoch(ts);
    return date.day.toString() +
        '/' +
        date.month.toString() +
        '/' +
        date.year.toString();
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

  Widget getDisplayWidget(ChatModel currChat, UserModel currUser, int index,
      AsyncSnapshot<List<ChatModel>> snapshot) {
    if (!checkIfDateShown(currChat.chatDate) &&
        (index == snapshot.data.length - 1 ||
            getDatePart(snapshot.data[index].chatDate) !=
                getDatePart(snapshot.data[index + 1].chatDate))) {
      _dateShownMap[getDatePart(currChat.chatDate)] = true;
      return Flex(
        direction: Axis.vertical,
        children: <Widget>[
          Center(
              child: ChatListDate(Utils().getDateTimeInFormat(
                  currChat.chatDate, 'date', 'userchatview'))),
          buildListElement(currChat, currUser, index, snapshot.data.length),
        ],
      );
    } else {
      return buildListElement(currChat, currUser, index, snapshot.data.length);
    }
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
          return ListView.builder(
            controller: _scrollController,
            shrinkWrap: true,
            reverse: true,
            itemBuilder: (BuildContext context, int index) {
              ChatModel currChat = snapshot.data[index];

              return getDisplayWidget(currChat, currUser, index, snapshot);
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
