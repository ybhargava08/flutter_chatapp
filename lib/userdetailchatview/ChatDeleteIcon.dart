import 'package:chatapp/blocs/ChatDeleteBloc.dart';
import 'package:chatapp/firebase/Firebase.dart';
import 'package:chatapp/model/ChatDeleteModel.dart';
import 'package:chatapp/model/ChatModel.dart';
import 'package:flutter/material.dart';

class ChatDeleteIcon extends StatelessWidget {
  handleOnPressDel() {
    List<ChatDeleteModel> deleteList = ChatDeleteBloc().getDeleteList().map((chat) => 
    ChatDeleteModel(_getDeleteChat(chat), chat.firebaseStorage, chat.localPath, chat.thumbnailPath)).toList();
    Firebase().markChatAsDeleted(deleteList);
    ChatDeleteBloc().clearChatDeleteList(true);
  }

 ChatModel _getDeleteChat(ChatModel chat)  {
    return ChatModel(
        chat.id,
        chat.fromUserId,
        chat.toUserId,
        'You deleted the message',
        chat.chatDate,
        ChatModel.CHAT,
        null,
        null,
        null,
        null,
        null,
        true,0);
 }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ChatModel>>(
      stream: ChatDeleteBloc().getStreamController().stream,
      initialData: [],
      builder: (BuildContext context, AsyncSnapshot<List<ChatModel>> snap) {
        if (snap != null && snap.hasData && snap.data.length > 0) {
          return IconButton(
            icon: Icon(Icons.delete),
            color: Colors.white,
            onPressed: () {
              handleOnPressDel();
            },
          );
        }
        return Container(
          width: 0,
          height: 0,
        );
      },
    );
  }
}
