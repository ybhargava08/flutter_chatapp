import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:chatapp/RouteConstants.dart';
import 'package:chatapp/blocs/UserBloc.dart';
import 'package:chatapp/enlargedview/ImageEnlargedView.dart';
import 'package:chatapp/enlargedview/MediaEnlargedView.dart';
import 'package:chatapp/firebase/Firebase.dart';
import 'package:chatapp/firebase/FirebaseStorageUtil.dart';
import 'package:chatapp/model/BaseModel.dart';
import 'package:chatapp/model/ChatModel.dart';
import 'package:chatapp/model/UserModel.dart';
import 'package:chatapp/userdetailchatview/ChatViewInheritedWrapper.dart';
import 'package:chatapp/userdetailchatview/chatelements/ChatDeliveryNotification.dart';
import 'package:chatapp/userdetailchatview/chatelements/MediaPlayPause.dart';
import 'package:chatapp/utils.dart';
import 'package:flutter/material.dart';

class ChatMediaWidget extends StatefulWidget {
  final ChatModel chat;

  final int index;

  final int totalLength;

  final ScrollController scrollController;

  ChatMediaWidget(Key key, this.chat,this.index,this.totalLength,this.scrollController) : super(key: key);

  @override
  State<StatefulWidget> createState() => _ChatMediaWidgetState();
  
}

class _ChatMediaWidgetState extends State<ChatMediaWidget> {

   ScrollController _scrollController;

  @override
  void initState() {
    _scrollController = widget.scrollController;
    if(UserBloc().getCurrUser().id == widget.chat.toUserId && widget.chat.delStat!=ChatModel.READ_BY_USER) {
           widget.chat.delStat = ChatModel.READ_BY_USER;
           List<ChatModel> _markedChatAsRead = List();
_markedChatAsRead.add(widget.chat);
           Firebase().markChatsAsReadOrDelivered((widget.chat.fromUserId == UserBloc().getCurrUser().id?widget.chat.toUserId
           :widget.chat.fromUserId),
                      _markedChatAsRead, true, ChatModel.READ_BY_USER);
    }
    super.initState();
  
  }

      Widget getVideoThumbnail(ChatModel chat, BuildContext context,
      UserModel toUser, double dimension) {
    return GestureDetector(
      child: Stack(
        children: <Widget>[
          chat.thumbnailPath.startsWith('http')
              ? 

               CachedNetworkImage(
                  placeholder: (context,url) => Image.asset('assets/images/blur_image.jpg',
                  width: dimension,height: dimension,fit: BoxFit.cover,), 
                  imageUrl: chat.thumbnailPath,
                  fit: BoxFit.cover,
                  width: dimension,
                  height: dimension,
                )
              : SizedBox(
                  width: dimension,
                  height: dimension,
                  child: Image.file(
                    File(chat.thumbnailPath),
                    fit: BoxFit.cover,
                  ),
                ),
          MediaPlayPause(UniqueKey(),chat)
        ],
      ),
      onTap: () {
        Navigator.pushNamed(context, RouteConstants.MEDIA_VIEW,
            arguments: MediaEnlargedViewArgs(chat, true, toUser, false,true));
      },
    );
  }

  Widget getImage(ChatModel chat, BuildContext context, UserModel toUser,
      double dimension) {
    return FutureBuilder<File>(
      future: FirebaseStorageUtil().getFileFromFirebaseStorage(chat),
      builder: (BuildContext context, AsyncSnapshot<File> snapshot) {
        if (snapshot.hasData && snapshot.data != null) {
          return GestureDetector(
            child: Stack(
              children: <Widget>[
                Hero(
                  child: SizedBox(
                    width: dimension,
                    height: dimension,
                    child: Image.file(
                      snapshot.data,
                      fit: BoxFit.cover,
                    ),
                  ),
                  tag: chat.id.toString(),
                ),
                MediaPlayPause(UniqueKey(),chat)
              ],
            ),
            onTap: () {
              BaseModel base = BaseModel(chat,toUser,false);
              Navigator.pushNamed(context, RouteConstants.IMAGE_VIEW,
                  arguments: ImageEnlargedViewArgs(base, false));
            },
          );
        } else if (snapshot.hasError) {
          print('snapshot has error');
          return Icon(Icons.error);
        } else if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              strokeWidth: 4.0,
            ),
          );
        }
        return Center(
          child: CircularProgressIndicator(
            strokeWidth: 4.0,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final inherited = ChatViewInheritedWidget.of(context);

    final toUser = inherited.toUser;

    final currUser = inherited.currUser;

    final bgColor = inherited.backgroundListItemColor;

    var width = MediaQuery.of(context).size.width;

    var height = MediaQuery.of(context).size.height;

    var dimension = 0.7 * ((width < height) ? width : height);

    bool isVideo = widget.chat.chatType == ChatModel.VIDEO;

    return Stack(
      children: <Widget>[
        Container(
          child: Flex(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            direction: Axis.vertical,
            children: <Widget>[
              Flexible(
                flex: 12,
                child: isVideo
                    ? getVideoThumbnail(widget.chat, context, toUser, dimension)
                    : getImage(widget.chat, context, toUser, dimension),
              ),
              Flexible(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    Text(
                      Utils().getDateTimeInFormat(
                          widget.chat.chatDate, 'time', 'userchatview'),
                      style:
                          TextStyle(color: Colors.blueGrey[400], fontSize: 12),
                    ),
                    (widget.chat.fromUserId == UserBloc().getCurrUser().id)
                        ? ChatDeliveryNotification(UniqueKey(),widget.chat)
                        : Container(
                            width: 0,
                            height: 0,
                          ),
                  ],
                ),
              )
            ],
          ),
          margin: EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 10.0),
          padding: EdgeInsets.all(5),
          decoration: BoxDecoration(
              color: (widget.chat.fromUserId != currUser.id) ? Colors.white : bgColor,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                    color: Colors.grey, blurRadius: 1, offset: Offset(1.0, 1.0))
              ]),
          width: dimension,
          height: dimension,
        ),
        
        isVideo
            ? Positioned(
                left: 30,
                bottom: 45,
                child: IconTheme(
                    child: Icon(Icons.videocam),
                    data: IconThemeData(color: Colors.white)),
              )
            : Container(
                width: 0,
                height: 0,
              ),
      ],
    );
  }
}