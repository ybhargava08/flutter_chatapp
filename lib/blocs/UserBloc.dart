import 'dart:async';

import 'package:chatapp/model/UserModel.dart';

class UserBloc {
  static UserBloc _userBloc;

  factory UserBloc() => _userBloc ??= UserBloc._();

  UserBloc._();

  StreamController<List<UserModel>> _controller;

  List<UserModel> _list = List();

  UserModel _currUser;

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
      _controller.sink.add(list);
    }
  }

  List<UserModel> _setInitList(List<UserModel> list, bool isAddController) {
    _list = list;
    if (isAddController) {
      _addInUserController(_list);
    }

    return _list;
  }

  addUpdateUser(UserModel user) {
    int index = _list.indexWhere((item) => item.id == user.id);

    if (index < 0) {
      _list.add(user);
      _addInUserController(_list);
    } else {
      _list[index] = user;
    }
  }

  UserModel findUser(String  userId) {
    return _list.firstWhere((item) => item.id == userId);
  }

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
  }


  setCurrUser(UserModel user) {
    _currUser = user;
  }

  UserModel getCurrUser() {
    return _currUser;
  }
}
