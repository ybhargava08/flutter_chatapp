import 'dart:io';

import 'package:chatapp/blocs/UserBloc.dart';
import 'package:chatapp/firebase/FirebaseStorageUtil.dart';
import 'package:chatapp/model/ChatModel.dart';
import 'package:chatapp/model/UserModel.dart';
import 'package:chatapp/userdetailchatview/chatelements/VideoPlayerWidget.dart';
import 'package:chatapp/userdetailchatview/contentpick/MediaPickerButton.dart';
import 'package:chatapp/utils.dart';
import 'package:flutter/material.dart';

class MediaEnlargedView extends StatelessWidget {
  final ChatModel chat;
  final UserModel toUser;
  final bool showPickerButton;
  final bool autoplay;

  MediaEnlargedView(
      this.chat, this.toUser, this.showPickerButton, this.autoplay);

  Widget getFileFromFuture(ChatModel chat, UserModel toUser) {
    return FutureBuilder<File>(
      future: FirebaseStorageUtil().getFileFromFirebaseStorage(chat),
      builder: (BuildContext context, AsyncSnapshot<File> snapshot) {
        if (snapshot.hasData && snapshot.data != null) {
          return VideoPlayerWidget(snapshot.data, autoplay);
        } else if (snapshot.hasError) {
          return getErrorWidget();
        } else {
          return Center(
            child: CircularProgressIndicator(
              strokeWidth: 4.0,
            ),
          );
        }
      },
    );
  }

  Widget getErrorWidget() {
    return Center(
      child: Container(
        width: 250,
        height: 50,
        alignment: Alignment.centerRight,
        padding: EdgeInsets.all(5),
        decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(40)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            IconTheme(
              child: Icon(Icons.error),
              data: IconThemeData(color: Colors.white, size: 25),
            ),
            Text(
              'Error playing media',
              style: TextStyle(color: Colors.white, fontSize: 25),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String name = "";
    if (chat.fromUserId != null && toUser != null) {
      if (chat.fromUserId == UserBloc().getCurrUser().id) {
        name = 'You';
      } else {
        name = toUser.name;
      }
    }

    String date = "";
    if (chat.chatDate != null) {
      date = Utils()
              .getDateTimeInFormat(chat.chatDate, 'date', 'userchatview') +
          '  ' +
          Utils().getDateTimeInFormat(chat.chatDate, 'time', 'userchatview');
    }

    Widget getFileWithCaption() {
      if (showPickerButton) {
        return Flex(
          direction: Axis.vertical,
          children: <Widget>[
            Flexible(
              flex: 7,
              child: getFileFromFuture(chat, toUser),
            ),
            Flexible(
              child: Container(
                padding: EdgeInsets.fromLTRB(10, 30, 90, 0),
                color: Colors.black,
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Add a Caption',
                    hintStyle: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                    ),
                    border: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                  style: TextStyle(color: Colors.white, fontSize: 18),
                  cursorColor: Colors.white,
                  autofocus: false,
                  onChanged: (text) {
                    chat.chat = text;
                  },
                ),
              ),
            )
          ],
        );
      } else if (!Utils().isStringEmpty(chat.chat)) {
        return Flex(
          direction: Axis.vertical,
          children: <Widget>[
            Flexible(
              flex: 6,
              child: getFileFromFuture(chat, toUser),
            ),
            Flexible(
                flex: 1,
                child: Align(
                  alignment: Alignment.center,
                  child: Text(
                    chat.chat,
                    style: TextStyle(fontSize: 19, color: Colors.white),
                  ),
                )),
          ],
        );
      } else {
        return getFileFromFuture(chat, toUser);
      }
    }

    return Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: <Widget>[
            Positioned(
              child: getFileWithCaption(),
            ),
            Positioned(
              bottom: 20,
              right: 20,
              child: (showPickerButton)
                  ? MediaPickerButton(chat, toUser, ChatModel.VIDEO, false)
                  : Container(
                      width: 0,
                      height: 0,
                    ),
            ),
            Positioned(
              left: 0,
              top: 0,
              right: 0,
              child: AppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  leading: IconButton(
                    color: Colors.white,
                    icon: Icon(Icons.arrow_back),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                  title: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(name,
                          style:
                              TextStyle(color: Colors.white, fontSize: 22.0)),
                      Text(date,
                          style: TextStyle(color: Colors.white, fontSize: 14.0))
                    ],
                  )),
            )
          ],
        ));
  }
}

class MediaEnlargedViewArgs {
  final ChatModel chat;
  final bool enlargedView;
  final UserModel toUser;
  final bool showPickerButton;
  final bool autoplay;

  MediaEnlargedViewArgs(this.chat, this.enlargedView, this.toUser,
      this.showPickerButton, this.autoplay);
}
