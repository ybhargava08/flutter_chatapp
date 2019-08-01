import 'dart:async';

import 'package:chatapp/blocs/SingleUserBloc.dart';
import 'package:chatapp/firebase/Firebase.dart';
import 'package:chatapp/login/LoginHandler.dart';
import 'package:chatapp/model/UserModel.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserBloc {
  static UserBloc _userBloc;

  factory UserBloc() => _userBloc ??= UserBloc._();

  UserBloc._();

  StreamController<List<UserModel>> _controller;

  //Map<String, StreamController<ChatModel>> _lastChatController = Map();

  List<UserModel> _list = List();

  UserModel _currUser;

  /*initLastChatController(String toUserId) {
    if (_isLastChatControllerClosed(toUserId)) {
      _lastChatController[toUserId] = StreamController.broadcast();
    }
  }

  closeLastChatController(String toUserId) {
    if (!_isLastChatControllerClosed(toUserId)) {
      _lastChatController[toUserId].close();
    }
  }

  _isLastChatControllerClosed(String toUserId) {
    if (null != _lastChatController[toUserId] &&
        !_lastChatController[toUserId].isClosed) {
      return false;
    }
    return true;
  }

  addToLastChatController(String toUserId, ChatModel chat) {
    if (!_isLastChatControllerClosed(toUserId)) {
      getLastChatControllerStream(toUserId).sink.add(chat);
    }
  }

  StreamController<ChatModel> getLastChatControllerStream(String toUserId) {
    return _lastChatController[toUserId];
  }*/

  initUserController() {
    closeUserController();
    _controller = StreamController.broadcast();
  }

  StreamController<List<UserModel>> getUserStreamController() {
    return _controller;
  }

  closeUserController() {
    if (_controller != null && !_controller.isClosed) {
      _controller.close();
    }
  }

  _addInUserController(List<UserModel> list) {
    if (_controller != null && !_controller.isClosed) {
      print('adding user list to user sink ' + list.toString());
      _controller.sink.add(list);
    }
  }

  List<UserModel> _setInitList(List<UserModel> list, bool isAddController) {
    print('setting init list is  ' + _list.toString());
    _list = list;
    if (isAddController) {
      _addInUserController(_list);
    }

    return _list;
  }

  addUpdateUser(UserModel user) {
    print('adding user ' + user.toString() + ' list is  ' + _list.toString());
    int index = _list.indexWhere((item) => item.id == user.id);

    if (index < 0) {
      _list.add(user);
      _addInUserController(_list);
    } else {
      _list[index] = user;
    }
    SingleUserBloc().addToController(user.id, user);
  }

  UserModel findUser(UserModel user) {
    return _list.firstWhere((item) => item.id == user.id);
  }

  /* _findUserAndRemove(UserModel user) {
    print('removing user '+user.toString()+' list is  '+_list.toString());
    int index = _list.indexWhere((item) => item.id == user.id);
    if (index >= 0) {
      _list.removeAt(index);
      _addInUserController(_list);
    }
  } */

  reorderList(String toUserId) {
    if (_list.length > 1) {
      int index = _list.indexWhere((item) => item.id == toUserId);
      if (index >= 1) {
        UserModel user = _list.removeAt(index);
        _list.insert(0, user);

        _addInUserController(_list);
      }
    }
  }

  void setInitUserAvtivityCS(List<UserModel> list, bool isAddController) {
    _setInitList(list, isAddController);
    _listenForUserActivity();
  }

  _listenForUserActivity() async {
    Firebase().getAllUserCollection().snapshots().listen((data) async {
      if (null != data) {
        data.documentChanges.forEach((change) async {
          if (change.type == DocumentChangeType.added ||
              change.type == DocumentChangeType.modified) {
            UserModel newUser = UserModel.fromDocSnapShot(data.documents[0]);
            LoginHandler().getUserDetailsFromContacts(newUser);
            /*print('got new user '+newUser.toString());
            if (newUser != null && newUser.name != null) {
              print('listen for user activity '+newUser.toString());
              addUpdateUser(newUser);
            }*/
          }
        });
      }
    });
  }

  setCurrUser(UserModel user) {
    _currUser = user;
  }

  UserModel getCurrUser() {
    return _currUser;
  }
}
