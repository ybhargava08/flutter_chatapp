import 'dart:async';

import 'package:chatapp/blocs/UserBloc.dart';
import 'package:chatapp/blocs/WebsocketBloc.dart';
import 'package:chatapp/firebase/Firebase.dart';
import 'package:chatapp/model/WebSocModel.dart';
import 'package:chatapp/userdetailchatview/ChatViewInheritedWrapper.dart';
import 'package:chatapp/userdetailchatview/contentpick/CustomMediaPicker.dart';
import 'package:flutter/material.dart';

import 'package:chatapp/model/ChatModel.dart';

class UserChatViewInput extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _UserChatViewInput();
}

class _UserChatViewInput extends State<UserChatViewInput> {
  TextEditingController _textEditingcontroller;

  Timer _timer;

  @override
  void initState() {
    _textEditingcontroller = TextEditingController();
    super.initState();
  }

  void sendIndtoWS(String text, String targetUserId) {
    if (null == _timer || !_timer.isActive) {
      WebSocModel model = WebSocModel(WebSocModel.TYPING,
          UserBloc().getCurrUser().id, targetUserId, null, null);
      WebsocketBloc().addDataToSocket(WebSocModel.TYPING, model);
      _timer = Timer(Duration(milliseconds: 500), () {
        _timer.cancel();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final inherited = ChatViewInheritedWidget.of(context);
    final currUser = inherited.currUser;
    final toUser = inherited.toUser;

    return Container(
      alignment: Alignment.bottomCenter,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          Expanded(
            flex: 9,
            child: Container(
                margin: EdgeInsets.fromLTRB(15.0, 0, 0, 5.0),
                padding: EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                          color: Colors.grey,
                          blurRadius: 1,
                          offset: Offset(1.0, 1.0))
                    ],
                    borderRadius: BorderRadius.circular(20.0)),
                child: Flex(
                  direction: Axis.horizontal,
                  children: <Widget>[
                    Expanded(
                      flex: 7,
                      child: TextField(
                        style: TextStyle(fontSize: 17.0, color: Colors.black),
                        decoration: InputDecoration(
                          contentPadding: EdgeInsets.fromLTRB(10, 0, 0, 0),
                          hintText: 'Enter message',
                          border: InputBorder.none,
                        ),
                        controller: _textEditingcontroller,
                        onChanged: (text) {
                          if (text.length > 0) {
                            sendIndtoWS(text, toUser.id);
                          }
                        },
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: CustomMediaPicker(),
                    )
                  ],
                )),
          ),
          Expanded(
            flex: 2,
            child: Container(
              margin: EdgeInsets.only(bottom: 5.0),
              child: RaisedButton(
                padding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0),
                child: IconTheme(
                  data: IconThemeData(color: Colors.white),
                  child: Icon(Icons.send),
                ),
                color: Theme.of(context).accentColor,
                splashColor: Theme.of(context).primaryColorLight,
                shape: CircleBorder(),
                onPressed: () {
                  var txt = _textEditingcontroller.text;
                  if (null != txt && txt != "") {
                    ChatModel chat = ChatModel(
                      DateTime.now().millisecondsSinceEpoch,
                      currUser.id,
                      toUser.id,
                      txt,
                      DateTime.now().millisecondsSinceEpoch,
                      ChatModel.CHAT,
                      null,
                      null,
                      null,
                      null,
                      ChatModel.DELIVERED_TO_LOCAL,
                    false,0);
                    Firebase()
                        .addUpdateChat(chat, Firebase.CHAT_COL_COMPLETE, true);
                    _textEditingcontroller.clear();
                  }
                },
              ),
            ),
          )
        ],
      ),
    );
  }

  @override
  void dispose() {
    _textEditingcontroller.dispose();
    super.dispose();
  }
}
