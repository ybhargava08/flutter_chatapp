import 'dart:async';
import 'dart:io';

import 'package:chatapp/database/SembastDatabase.dart';
import 'package:chatapp/firebase/FirebaseStorageUtil.dart';
import 'package:chatapp/model/ChatModel.dart';
import 'package:connectivity/connectivity.dart';

class ConnectivityListener {
  static ConnectivityListener _connectivityListener;

  factory ConnectivityListener() =>
      _connectivityListener ??= ConnectivityListener._();

  ConnectivityListener._();

  StreamSubscription _subs;

  initListener() async {
    _subs =
        Connectivity().onConnectivityChanged.listen((connectivityResult) async {
      if (connectivityResult == ConnectivityResult.mobile ||
          connectivityResult == ConnectivityResult.wifi) {
        List<ChatModel> list = await SembastDatabase().getAllData();
        if (list != null && list.length > 0) {
          print('got connectivity ' + list.length.toString());
          list.forEach((chat) async {
          if (await pingGoogle()) {
            FirebaseStorageUtil().addFileToFirebaseStorage(
                chat, chat.chatType == ChatModel.IMAGE);
          }
        });
        } else {
          print(' got connectivity no list');
        }

        
      }
    });
  }

  Future<bool> pingGoogle() async {
    final result = await InternetAddress.lookup('google.com');
    return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
  }

  closeListener() {
    if (null != _subs) {
      _subs.cancel();
    }
  }
}
