import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:chatapp/blocs/UserBloc.dart';
import 'package:chatapp/model/BaseModel.dart';
import 'package:chatapp/model/ChatModel.dart';
import 'package:chatapp/userdetailchatview/contentpick/MediaPickerButton.dart';
import 'package:chatapp/utils.dart';
import 'package:flutter/material.dart';

class ImageEnlargedView extends StatelessWidget {
  final BaseModel baseModel;

  final bool showMediaPickerButton;

  ImageEnlargedView(this.baseModel, this.showMediaPickerButton);

  @override
  Widget build(BuildContext context) {
    var w = MediaQuery.of(context).size.width;

    String name = "";
    if (null != baseModel &&
        null != baseModel.chat &&
        baseModel.chat.fromUserId != null &&
        baseModel.user != null) {
      if (baseModel.chat.fromUserId == UserBloc().getCurrUser().id) {
        name = 'You';
      } else {
        name = baseModel.user.name;
      }
    }

    String date = "";
    if (null != baseModel &&
        null != baseModel.chat &&
        baseModel.chat.chatDate != null) {
      date = Utils().getDateTimeInFormat(
              baseModel.chat.chatDate, 'date', 'userchatview') +
          '  ' +
          Utils().getDateTimeInFormat(
              baseModel.chat.chatDate, 'time', 'userchatview');
    }

    Widget getImageForChat() {
      if (showMediaPickerButton) {
        return Flex(
          direction: Axis.vertical,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Flexible(
              flex: 7,
              child: (baseModel.chat.id != null)
                  ? Hero(
                      child: Image.file(
                        File(baseModel.chat.localPath),
                        fit: BoxFit.cover,
                      ),
                      tag: baseModel.chat.id.toString(),
                    )
                  : Image.file(File(baseModel.chat.localPath)),
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
                      baseModel.chat.chat = text;
                    },
                  ),
                ),
              ),
            
          ],
        );
      } else if (!Utils().isStringEmpty(baseModel.chat.chat)) {
           return  Flex(
          direction: Axis.vertical,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Flexible(
              flex: 6,
              child: (baseModel.chat.id != null)
                  ? Hero(
                      child: Image.file(
                        File(baseModel.chat.localPath),
                        fit: BoxFit.cover,
                      ),
                      tag: baseModel.chat.id.toString(),
                    )
                  : Image.file(File(baseModel.chat.localPath)),
            ),
            Flexible(
              flex: 1,
                child: Align(
                  alignment: Alignment.center,
                   child: Text(baseModel.chat.chat,style: TextStyle(fontSize: 19,color: Colors.white),),
                )
              ),
            
          ],
        );
      } else {
        return (baseModel.chat.id != null)
            ? Hero(
                child: Image.file(File(baseModel.chat.localPath)),
                tag: baseModel.chat.id.toString(),
              )
            : Image.file(File(baseModel.chat.localPath));
      }
    }

    Widget getImageForUser() {
      return (baseModel.user != null)
          ? Hero(
              child: (baseModel.user.photoUrl != null &&
                      baseModel.user.photoUrl != '')
                  ? (baseModel.user.photoUrl.startsWith('http'))
                      ? CachedNetworkImage(
                          placeholder: (context, url) =>
                              Image.asset('assets/images/blur_image.jpg'),
                          errorWidget: (context, url, error) {
                            /*print('error occured while loading dp ' +
                                error.toString());*/
                            return Image.asset('assets/images/blur_image.jpg');
                          },
                          imageUrl: baseModel.user.photoUrl,
                        )
                      : Image.file(
                          File(baseModel.user.photoUrl),
                        )
                  : Image.asset(
                      'assets/images/placeholder_acc.png',
                    ),
              tag: baseModel.user.id,
            )
          : Container(
              width: 0,
              height: 0,
            );
    }

    Widget getAppBarChat() {
      //print('date is '+date);
      return AppBar(
          backgroundColor: Colors.black,
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
              Text(name, style: TextStyle(color: Colors.white, fontSize: 20.0)),
              Text(date, style: TextStyle(color: Colors.white, fontSize: 13.0))
            ],
          ));
    }

    Widget getAppBarUser() {
      if (showMediaPickerButton) {
        return AppBar(
          backgroundColor: Colors.transparent,
        );
      } else {
        return AppBar(
            backgroundColor: Colors.black,
            leading: IconButton(
              color: Colors.white,
              icon: Icon(Icons.arrow_back),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            title: Text(
              'Profile Photo',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ));
      }
    }

    return Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: <Widget>[
            SafeArea(
              child: SizedBox.expand(
                  child: (null != baseModel.chat)
                      ? getImageForChat()
                      : getImageForUser()),
            ),
            Positioned(
              bottom: 20,
              right: 20,
              child: (showMediaPickerButton)
                  ? MediaPickerButton(baseModel.chat, baseModel.user,
                      ChatModel.IMAGE, baseModel.isUser)
                  : Container(
                      width: 0,
                      height: 0,
                    ),
            ),
            Positioned(
              top: 0,
              left: 0,
              child: SizedBox(
                width: w,
                child: (baseModel.chat != null)
                    ? getAppBarChat()
                    : getAppBarUser(),
              ),
            )
          ],
        ));
  }
}

class ImageEnlargedViewArgs {
  final BaseModel base;

  final bool showMediaPickerButton;

  ImageEnlargedViewArgs(this.base, this.showMediaPickerButton);
}
