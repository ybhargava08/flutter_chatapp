import 'package:chatapp/RouteConstants.dart';
import 'package:chatapp/blocs/ChatDeleteBloc.dart';
import 'package:chatapp/blocs/UserBloc.dart';
import 'package:chatapp/database/SembastChat.dart';
import 'package:chatapp/enlargedview/ImageEnlargedView.dart';
import 'package:chatapp/enlargedview/MediaEnlargedView.dart';
import 'package:chatapp/firebase/FirebaseStorageUtil.dart';
import 'package:chatapp/model/BaseModel.dart';
import 'package:chatapp/model/ChatModel.dart';
import 'package:chatapp/model/UserModel.dart';
import 'package:chatapp/userdetailchatview/ChatViewInheritedWrapper.dart';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class CustomMediaPicker extends StatelessWidget {
  getImage(BuildContext context, UserModel toUser, ImageSource source) async {
    var image = await ImagePicker.pickImage(source: source);

    if (image != null) {
      //print('local image file path ' + image.path);
      BaseModel base = BaseModel(ChatModel(0, null, null, null, DateTime.now().millisecondsSinceEpoch, null, image.path, null, null, null,
                       null,false), toUser,false); 
                       
      Navigator.pushNamed(context, RouteConstants.IMAGE_VIEW,
              arguments: ImageEnlargedViewArgs(
                  base,
                  true))
          .then((val) async {
        if (val != null && val is BaseModel) {
          //print('val is ' + val.toString());

          if(null!=val.chat) {
                val.chat.firebaseStorage = null;
          //print('upserting to sembast ' + val.chat.id.toString() + ' ' + val.chat.chatType);
          SembastChat().upsertInChatStore(val.chat,'addImage');
          } 
          
        } else {
          getImage(context, toUser, source);
        }
      });
    }
  }

  getVideo(BuildContext context, UserModel toUser, ImageSource source) async {
    var video = await ImagePicker.pickVideo(source: source);

    if (video != null) {
      Navigator.pushNamed(context, RouteConstants.MEDIA_VIEW,
              arguments: MediaEnlargedViewArgs(
                  ChatModel(0, UserBloc().getCurrUser().id, toUser.id, null, DateTime.now().millisecondsSinceEpoch, ChatModel.VIDEO,
                      video.path, null, null, null, null,false),
                  true,
                  toUser,
                  true,
                  false))
          .then((val) async {
        if (val != null && val is BaseModel && val.chat!=null) {
          val.chat.thumbnailPath = await FirebaseStorageUtil().createThumbnail(val.chat);
          val.chat.firebaseStorage = null;
          SembastChat().upsertInChatStore(val.chat,'addVideo');
        } else {
          getVideo(context, toUser, source);
        }
      });
    }
  }

  _showAttachmentMenu(BuildContext context, UserModel toUser) {
    showModalBottomSheet(
        context: context,
        builder: (BuildContext bc) {
          return Container(
              height: 150,
              margin: EdgeInsets.fromLTRB(0, 10, 0, 10),
              child: Flex(
                direction: Axis.horizontal,
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                mainAxisSize: MainAxisSize.max,
                children: <Widget>[
                  Flexible(
                    child: IconButton(
                      icon: Icon(Icons.camera),
                      iconSize: 35,
                      onPressed: () {
                        Navigator.of(context).pop();
                        getImage(context, toUser, ImageSource.gallery);
                      },
                    ),
                  ),
                  Flexible(
                    child: IconButton(
                      icon: Icon(Icons.video_library),
                      iconSize: 35,
                      onPressed: () {
                        Navigator.of(context).pop();
                        getVideo(context, toUser, ImageSource.gallery);
                      },
                    ),
                  )
                ],
              ));
        });
  }

  @override
  Widget build(BuildContext context) {
    var inherited = ChatViewInheritedWidget.of(context);
    final toUser = inherited.toUser;
    //print('in custom media picker touser '+toUser.toString());
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Expanded(
            child: Transform.rotate(
                angle: -45,
                child: IconButton(
                  icon: Icon(Icons.attach_file),
                  color: Colors.grey,
                  onPressed: () {
                    ChatDeleteBloc().clearChatDeleteList(true);
                    _showAttachmentMenu(context, toUser);
                  },
                ))),
        Expanded(
          child: IconButton(
            icon: IconTheme(
              child: Icon(Icons.camera_alt),
              data: IconThemeData(color: Colors.grey[700]),
            ),
            onPressed: () {
              ChatDeleteBloc().clearChatDeleteList(true);
              getImage(context, toUser, ImageSource.camera);
            },
          ),
        ),
      ],
    );
  }
}
