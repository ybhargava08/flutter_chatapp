
import 'package:chatapp/model/BaseModel.dart';
import 'package:chatapp/model/ChatModel.dart';
import 'package:chatapp/model/UserModel.dart';
import 'package:chatapp/blocs/UserBloc.dart';

import 'package:flutter/material.dart';

class MediaPickerButton extends StatelessWidget {
  final ChatModel chat;
  final UserModel toUser;
  final String type;

  final bool isUser;


  MediaPickerButton(this.chat, this.toUser,this.type,this.isUser);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
            width: 60,
            height: 60,
            child: RaisedButton(
              padding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0),
              child: IconTheme(
                data: IconThemeData(color: Colors.white,size: 30),
                child: Icon(Icons.send),
              
              ),
              color: Theme.of(context).accentColor,
              splashColor: Theme.of(context).primaryColorLight,
              shape: CircleBorder(),
              onPressed: () async {
                BaseModel base;
                if(isUser) {
                  base = BaseModel(null, toUser, isUser);
                }else{
                  base = BaseModel(ChatModel(
                    DateTime.now().millisecondsSinceEpoch,
                    UserBloc().getCurrUser().id,
                    toUser.id,
                    chat.chat,
                    DateTime.now().millisecondsSinceEpoch,
                    type,
                    chat.localPath,
                    "",
                    "",
                    "",
                    ChatModel.DELIVERED_TO_LOCAL,
                    ), toUser, isUser);
                }
                Navigator.of(context).pop(base);
              },
            ),
          );
  }
  
}
