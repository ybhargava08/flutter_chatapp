import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sembast/sembast.dart';

class UserModel {
  String id;
  String name;
  String photoUrl;
  //bool isOnline;
  String lastSeenTime;
  String fcmToken;
  String ph;
  int time = 0;

  UserModel(this.id, this.name, this.photoUrl,
      /* this.isOnline, */ this.lastSeenTime, this.fcmToken, this.ph);

  bool operator ==(dynamic other) {
    return other.ph==ph && other.id == id && other.photoUrl == photoUrl;
  }

  factory UserModel.fromJson(Map<String, dynamic> map) {
    return UserModel(
        map["id"],
        map["name"],
        map["photoUrl"],
        /* ,map["isOnline"], */ map["lastSeenTime"],
        map["fcmToken"],
        map["ph"]);
  }

  factory UserModel.fromDocSnapShot(DocumentSnapshot ds) {
    return UserModel(ds["id"], ds["name"], ds["photoUrl"],
        /* ds["isOnline"], */ ds["lastSeenTime"], ds["fcmToken"], ds["ph"]);
  }

  factory UserModel.fromRecordSnapshot(RecordSnapshot ds) {
    return UserModel(ds["id"], ds["name"], ds["photoUrl"],
        /* ds["isOnline"], */ ds["lastSeenTime"], ds["fcmToken"], ds["ph"]);
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
    /*if(isOnline!=null) {
           map["isOnline"] = isOnline;
      }*/
    if (fcmToken != null) {
      map["fcmToken"] = fcmToken;
    }
    if (ph != null) {
      map["ph"] = ph;
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
