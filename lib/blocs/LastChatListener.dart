import 'dart:async';

import 'package:chatapp/blocs/UserLatestChatBloc.dart';
import 'package:chatapp/firebase/FirebaseRealtimeDB.dart';
import 'package:chatapp/model/UserLatestChatModel.dart';

class LastChatListener {
  static LastChatListener _lastChatListener;

  factory LastChatListener() => _lastChatListener ?? LastChatListener._();

  LastChatListener._();

  Map<String, StreamSubscription> _chatCountListeners = Map();
  
  initLatestChatListeners(String fromUserId, String toUserId) {
    _listenForChatCounts(fromUserId, toUserId);
  }

  _listenForChatCounts(String fromUserId, String toUserId) {
    if (!_chatCountListeners.containsKey(toUserId)) {
      String path =
          'ChatActivity/' + fromUserId + '/UnreadChat/' + toUserId+'/'+UserLatestChatModel.COUNT;
          print('init listening for chat count at path '+path);
      _chatCountListeners[toUserId] = FirebaseRealtimeDB()
          .getDBPathReference(path)
          .onValue
          .listen((event) {
        print('got data from path ' +
            path +
            ' key ' +
            event.snapshot.key +
            ' value ' +
            event.snapshot.value.toString());
        sendDataToBloc(toUserId, event.snapshot.key,event.snapshot.value);
      });
    }
  }

  closeIndividualListener(String toUserId) {
    if (_chatCountListeners.containsKey(toUserId) &&
        _chatCountListeners[toUserId] != null) {
      _chatCountListeners[toUserId].cancel().then((_) {
        _chatCountListeners.remove(toUserId);
      });
    }
  }

  closeAllListeners() {
    _chatCountListeners.forEach((k, v) {
      closeIndividualListener(k);
    });
  }

  sendDataToBloc(String toUserId, String key,int value) {
    if(key!=null && value!=null) {
          UserLatestChatBloc().addToChatCountController(UserLatestChatModel(
        toUserId, key, value));
    }
  }
}
