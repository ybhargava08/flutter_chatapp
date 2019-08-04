import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sembast/sembast.dart';

class UserModel {
  String id;
  String name;
  String photoUrl;
  String lastSeenTime;
  String fcmToken;
  String ph;
  int localId = 0;
  int lastActivityTime = 0;

  UserModel(this.id, this.name, this.photoUrl,
       this.lastSeenTime, this.fcmToken, this.ph,this.localId);

  bool operator ==(dynamic other) {
    return other.ph==ph && other.id == id && other.photoUrl == photoUrl && other.fcmToken==fcmToken;
  }

  factory UserModel.fromJson(Map<String, dynamic> map) {
    return UserModel(
        map["id"],
        map["name"],
        map["photoUrl"],
         map["lastSeenTime"],
        map["fcmToken"],
        map["ph"],
        map["localId"]
        );
  }

  factory UserModel.fromDocSnapShot(DocumentSnapshot ds) {
    return UserModel(ds["id"], ds["name"], ds["photoUrl"],
        ds["lastSeenTime"], ds["fcmToken"], ds["ph"],ds["localId"]);
  }

  factory UserModel.fromRecordSnapshot(RecordSnapshot ds) {
    return UserModel(ds["id"], ds["name"], ds["photoUrl"],
        ds["lastSeenTime"], ds["fcmToken"], ds["ph"],ds["localId"]);
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> map = Map();
    if (id != null) {
      map["id"] = id;
    }
    if (name != null) {
      map["name"] = name;
    }
    if (photoUrl != null) {
      map["photoUrl"] = photoUrl;
    }
        if (fcmToken != null) {
      map["fcmToken"] = fcmToken;
    }
    if (ph != null) {
      map["ph"] = ph;
    }

    if(localId > 0) {
         map["localId"] = localId;
    }

    return map;
  }

  @override
  String toString() {
    String s = 'id ' + id + ' ph ' + ph + ' photurl ';
    if (null != photoUrl) {
      s += photoUrl;
    }
    if(null!=name) {
         s+='name '+name;
    }
    return s;
  }
}
