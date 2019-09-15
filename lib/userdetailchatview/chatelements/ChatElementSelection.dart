import 'dart:async';

import 'package:chatapp/RouteConstants.dart';
import 'package:chatapp/blocs/ChatDeleteBloc.dart';
import 'package:chatapp/blocs/UserBloc.dart';
import 'package:chatapp/enlargedview/ImageEnlargedView.dart';
import 'package:chatapp/enlargedview/MediaEnlargedView.dart';
import 'package:chatapp/model/BaseModel.dart';
import 'package:chatapp/model/ChatModel.dart';
import 'package:chatapp/model/UserModel.dart';
import 'package:chatapp/userdetailchatview/ChatViewInheritedWrapper.dart';
import 'package:chatapp/utils.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class ChatElementSelection extends StatefulWidget {
  final ChatModel chat;

  ChatElementSelection(Key key, this.chat) : super(key: key);
  @override
  State<StatefulWidget> createState() => _ChatElementSelectionState();
}

class _ChatElementSelectionState extends State<ChatElementSelection> {
  bool _isSetForDelete = false;

  StreamSubscription _subs;

  bool checkListContainsCurrChat(List<ChatModel> list) {
    int index = list.indexWhere((item) => item.id == widget.chat.id);
    return index >= 0;
  }

  void handleImageMediaTaps(UserModel toUser) {
    if (widget.chat.chatType == ChatModel.IMAGE) {
      BaseModel base = BaseModel(widget.chat, toUser, false);
      Navigator.pushNamed(context, RouteConstants.IMAGE_VIEW,
          arguments: ImageEnlargedViewArgs(base, false));
    } else if (widget.chat.chatType == ChatModel.VIDEO) {
      Navigator.pushNamed(context, RouteConstants.MEDIA_VIEW,
          arguments:
              MediaEnlargedViewArgs(widget.chat, true, toUser, false, true));
    }
  }

  @override
  void initState() {
    super.initState();
    _isSetForDelete =
        checkListContainsCurrChat(ChatDeleteBloc().getDeleteList());
    _subs = ChatDeleteBloc().getStreamController().stream.listen((data) {
      if (checkListContainsCurrChat(data) && !_isSetForDelete) {
        setState(() {
          _isSetForDelete = true;
        });
      } else if (!checkListContainsCurrChat(data) && _isSetForDelete) {
        setState(() {
          _isSetForDelete = false;
        });
      }
    });
  }

  @override
  void dispose() {
    if (null != _subs) {
      _subs.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inherited = ChatViewInheritedWidget.of(context);

    final toUser = inherited.toUser;

    return GestureDetector(
        onTap: () {
          if (widget.chat.isD) {
            Utils().showToast('Message already deleted', context,
                Toast.LENGTH_LONG, ToastGravity.CENTER);
          } else {
            if (ChatDeleteBloc().getDeleteList().length > 0) {
              ChatDeleteBloc().addRemoveDeleteList(widget.chat);
            } else {
              handleImageMediaTaps(toUser);
            }
          }
        },
        onLongPress: () {
          if (widget.chat.fromUserId == UserBloc().getCurrUser().id) {
            if (!widget.chat.isD) {
              Utils().doVibrate(100);
              ChatDeleteBloc().addRemoveDeleteList(widget.chat);
            } else {
              Utils().showToast('Message already deleted', context,
                  Toast.LENGTH_LONG, ToastGravity.CENTER);
            }
          }
        },
        onLongPressEnd: (LongPressEndDetails details) {
          if (widget.chat.fromUserId != UserBloc().getCurrUser().id) {
            setState(() {
              _isSetForDelete = false;
            });
          }
        },
        child: Container(
          width: MediaQuery.of(context).size.width,
          margin: EdgeInsets.fromLTRB(0, 5, 0, 5),
          color: _isSetForDelete
              ? Colors.blueGrey.withOpacity(0.3)
              : Colors.transparent,
        ));
  }
}
