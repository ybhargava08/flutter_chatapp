import 'package:chatapp/blocs/UserBloc.dart';
import 'package:chatapp/model/UserModel.dart';
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
  int ts;
  bool doDeleteAnimation = false;

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
        map["isD"],
        map["ts"]
        );
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
        ds["isD"],
        ds["ts"]
        );
  }

  factory ChatModel.fromDocumentSnapshot(firestore.DocumentSnapshot ds) {
    firestore.Timestamp ts = ds['chatDate'];
    firestore.Timestamp timestamp = ds['ts'];
    bool isD = ds['isD'];
    String chatType = ds['chatType']; 
    String chat = ds['chat'];
    if(isD) {
                chatType = ChatModel.CHAT;
                UserModel delUser = UserBloc().findUser(ds['fromUserId']);
                print('found delUser '+delUser.toString());
                if(delUser.name!=null || ''!=delUser.name) {
                  chat = delUser.name+' deleted the message';
                }else{
                  chat = 'This message was deleted';
                }
          }
    return ChatModel(
        ds["id"],
        ds["fromUserId"],
        ds["toUserId"],
        chat,
        ts.millisecondsSinceEpoch,
        chatType,
        ds["localPath"],
        ds["thumbnailPath"],
        ds["fileName"],
        ds["firebaseStorage"],
        ds['delStat'],
        isD,
        timestamp.millisecondsSinceEpoch
        );
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

    if (null == ts || ts == 0) {
      map["ts"] = DateTime.now().millisecondsSinceEpoch;
    } else {
      map["ts"] = ts;
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
    map['ts'] = firestore.FieldValue.serverTimestamp();
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

  Map<String, dynamic> toDeleteJson(int timestamp,int ms, bool isFirestore) {
    Map<String, dynamic> map = Map();
    if(isFirestore) {
        map['ts'] = firestore.FieldValue.serverTimestamp();
    }else{
       map['ts'] = timestamp;
    }
    
    map["id"] = id;
    map["fromUserId"] = fromUserId;
    map["toUserId"] = toUserId;
    if(!isFirestore) {
        map["chat"] = 'You deleted the message';
    }
    
    if (isFirestore) {
      map["chatDate"] = firestore.Timestamp.fromMillisecondsSinceEpoch(ms);
    } else {
      map["chatDate"] = ms;
    }
    if(!isFirestore) {
        map["chatType"] = ChatModel.CHAT;
    }
    
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
      this.isD,
      this.ts
      );

  @override
  String toString() {
    String delSta = (null==delStat)?'':delStat;
    String cha = (chat == null)?'':chat;
    return 'fromUser ' +
        fromUserId +
        ' toUser ' +
        toUserId +
        ' chat ' +
        cha +
        /*' local chat id ' +
        localChatId.toString() +*/
        ' chat-id ' +
        id.toString() +
        ' chattype ' +
        chatType +
        /*' chatDate ' +
        chatDate.toString() +*/
        ' ' +
        delSta +
        ' ' +
        isD.toString()+
        ' dodelAnim ' + doDeleteAnimation.toString();    
  }

  bool operator ==(dynamic other) {
    return other.id == id &&
        other.chatType == chatType &&
        other.thumbnailPath == thumbnailPath &&
        other.ts == ts &&
        other.chatDate == chatDate &&
        other.fileName == fileName &&
        other.isD == isD &&
        other.firebaseStorage == firebaseStorage;
  }
}
