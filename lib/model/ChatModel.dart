import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
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
  bool isD = false;

  static const String CHAT = "c";
  static const String IMAGE = "i";
  static const String VIDEO = "v";

  static const String DELIVERED_TO_SERVER = 'ds';
  static const String DELIVERED_TO_LOCAL = 'dl';
  static const String DELIVERED_TO_USER = 'du';
  static const String READ_BY_USER = 'r';

  factory ChatModel.fromJson(Map<String, dynamic> map) {
    return ChatModel(
        map["id"],
        map["fromUserId"],
        map["toUserId"],
        map["chat"],
        map["chatDate"],
        map["chatType"],
        map["localPath"],
        map["thumbnailPath"],
        map["fileName"],
        map["firebaseStorage"],
        map["delStat"],
        map["isD"]);
  }

  factory ChatModel.fromRecordSnapshot(RecordSnapshot ds) {
    return ChatModel(
        ds["id"],
        ds["fromUserId"],
        ds["toUserId"],
        ds["chat"],
        ds["chatDate"],
        ds["chatType"],
        ds["localPath"],
        ds["thumbnailPath"],
        ds["fileName"],
        ds["firebaseStorage"],
        ds["delStat"],
        ds["isD"]);
  }

  factory ChatModel.fromDocumentSnapshot(firestore.DocumentSnapshot ds) {
    firestore.Timestamp ts = ds['chatDate'];
    return ChatModel(
        ds["id"],
        ds["fromUserId"],
        ds["toUserId"],
        ds["chat"],
        ts.millisecondsSinceEpoch,
        ds["chatType"],
        ds["localPath"],
        ds["thumbnailPath"],
        ds["fileName"],
        ds["firebaseStorage"],
        ds["delStat"],
        ds["isD"]);
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> map = Map();
    map["id"] = id;
    map["fromUserId"] = fromUserId;
    map["toUserId"] = toUserId;
    map["chat"] = chat;
    if (null == chatDate || chatDate == 0) {
      map["chatDate"] = DateTime.now().millisecondsSinceEpoch;
    } else {
      map["chatDate"] = chatDate;
    }

    map["chatType"] = chatType;
    map["localPath"] = localPath;
    map["thumbnailPath"] = thumbnailPath;
    map["fileName"] = fileName;
    map["firebaseStorage"] = firebaseStorage;
    map["delStat"] = delStat;
    map["isD"] = isD;
    return map;
  }

  Map<String, dynamic> toFirestoreJson() {
    Map<String, dynamic> map = Map();
    map["chatDate"] = firestore.FieldValue.serverTimestamp();
    putNotNullMap(map, "id", id);
    putNotNullMap(map, "fromUserId", fromUserId);
    putNotNullMap(map, "toUserId", toUserId);
    putNotNullMap(map, "chat", chat);
    putNotNullMap(map, "chatType", chatType);
    putNotNullMap(map, "localPath", localPath);
    putNotNullMap(map, "thumbnailPath", thumbnailPath);
    putNotNullMap(map, "fileName", fileName);
    putNotNullMap(map, "firebaseStorage", firebaseStorage);
    putNotNullMap(map, "isD", isD);
    return map;
  }

  Map<String, dynamic> toDeleteJson(int ms, bool isFirestore) {
    Map<String, dynamic> map = Map();
    map["id"] = id;
    map["fromUserId"] = fromUserId;
    map["toUserId"] = toUserId;
    map["chat"] = 'This message was deleted';
    if (isFirestore) {
      map["chatDate"] = firestore.Timestamp.fromMillisecondsSinceEpoch(ms);
    } else {
      map["chatDate"] = ms;
    }

    map["chatType"] = ChatModel.CHAT;
    map["isD"] = true;
    return map;
  }

  void putNotNullMap(Map<String, dynamic> map, String key, dynamic value) {
    if (null != value) {
      map[key] = value;
    }
  }

  ChatModel(
      this.id,
      this.fromUserId,
      this.toUserId,
      this.chat,
      this.chatDate,
      this.chatType,
      this.localPath,
      this.thumbnailPath,
      this.fileName,
      this.firebaseStorage,
      this.delStat,
      this.isD);

  @override
  String toString() {
    return 'fromUser ' +
        fromUserId +
        ' toUser ' +
        toUserId +
        ' chat ' +
        chat +
        ' local chat id ' +
        localChatId.toString() +
        ' chat-id ' +
        id.toString() +
        ' chattype ' +
        chatType +
        ' chatDate ' +
        chatDate.toString() +
        ' ' +
        delStat +
        ' ' +
        isD.toString();
  }

  bool operator ==(dynamic other) {
    return other.id == id &&
        other.localChatId == localChatId &&
        other.thumbnailPath == thumbnailPath &&
        other.fileName == fileName &&
        other.isD == isD &&
        other.firebaseStorage == firebaseStorage;
  }
}
