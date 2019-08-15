import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sembast/sembast.dart';

class ChatModel {
  int id;
  String fromUserId;
  String toUserId;
  String chat;
  int chatDate;
  String chatType;
  String localPath;
  String thumbnailPath;
  String fileName;
  String firebaseStorage;
  String delStat = DELIVERED_TO_LOCAL;
  int localChatId = 0;
 // int fbId;
 // int compareId = 0;
  

  static const String CHAT = "chat";
  static const String IMAGE = "image";
  static const String VIDEO = "video";

  static const String DELIVERED_TO_SERVER = 'ds';
  static const String DELIVERED_TO_LOCAL = 'dl';
  static const String DELIVERED_TO_USER = 'du';
  static const String READ_BY_USER = 'r';

  factory ChatModel.fromJson(Map<String, dynamic> map) {
    return ChatModel(map["id"],
        map["fromUserId"], map["toUserId"], map["chat"], map["chatDate"],map["chatType"],map["localPath"],
        map["thumbnailPath"],map["fileName"],map["firebaseStorage"],
        map["delStat"]);
  }

  factory ChatModel.fromRecordSnapshot(RecordSnapshot ds) {
    return ChatModel(ds["id"],
        ds["fromUserId"], ds["toUserId"], ds["chat"], ds["chatDate"],ds["chatType"],ds["localPath"]
        ,ds["thumbnailPath"],ds["fileName"],ds["firebaseStorage"],ds["delStat"]);
  }

  factory ChatModel.fromDocumentSnapshot(DocumentSnapshot ds) {
    return ChatModel(ds["id"],
        ds["fromUserId"], ds["toUserId"], ds["chat"], ds["chatDate"],ds["chatType"],ds["localPath"]
        ,ds["thumbnailPath"],ds["fileName"],ds["firebaseStorage"],ds["delStat"]);
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> map = Map();
    map["id"] = id;
    map["fromUserId"] = fromUserId;
    map["toUserId"] = toUserId;
    map["chat"] = chat;
    map["chatDate"] = chatDate;
    map["chatType"] = chatType;
    map["localPath"] = localPath;
    map["thumbnailPath"] = thumbnailPath;
    map["fileName"] = fileName;
    map["firebaseStorage"] = firebaseStorage;
    map["delStat"] = delStat;
    return map;
  }

  ChatModel(this.id,this.fromUserId, this.toUserId, this.chat, this.chatDate,this.chatType,this.localPath,
      this.thumbnailPath,this.fileName,this.firebaseStorage,this.delStat);

  @override
  String toString() {
    return 'fromUser ' + fromUserId + ' toUser ' + toUserId +' chat '+chat+' local chat id '+localChatId.toString()
    +' chat-id ' + id.toString()+' chattype '+chatType
    /*+fbId.toString()*/+' '+delStat+' '/*+compareId.toString()*/;
  }

  bool operator == (dynamic other) {
     return other.id == id /*&& other.fbId == fbId*/ && other.localChatId == localChatId 
     && other.delStat == delStat && other.firebaseStorage == firebaseStorage;
  }
}
