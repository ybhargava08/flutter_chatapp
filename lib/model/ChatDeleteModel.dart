import 'package:chatapp/model/ChatModel.dart';

class ChatDeleteModel{

   ChatModel chat;

   String fbStoragePath;
   String localPath;
   String thumbnailPath;

   ChatDeleteModel(this.chat,this.fbStoragePath,this.localPath,this.thumbnailPath);
}