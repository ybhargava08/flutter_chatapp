import 'dart:async';

import 'package:chatapp/blocs/UserBloc.dart';
import 'package:chatapp/database/OfflineDBUser.dart';
import 'package:chatapp/firebase/Firebase.dart';
import 'package:chatapp/model/UserModel.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:contacts_service/contacts_service.dart';

class UserListener {
  static UserListener _singleUserBloc;

  factory UserListener() => _singleUserBloc ??= UserListener._();

  StreamSubscription _subsLess;

  StreamSubscription _subsGreater;
  UserListener._();

  Map<String, StreamController<UserModel>> _map = Map();

  initLisener() {
      _listenForUserActivityLess();
      _listenForUserActivityGreater();
  }

  openController(String id) {
    if (_isControllerClosed(id)) {
      _map[id] = StreamController.broadcast();
    }
  }

  _listenForUserActivityLess() {
      _subsLess =
          Firebase().getAllUserCollection().where('ph',isLessThan: UserBloc().getCurrUser().ph)
          .snapshots().listen((data) async {
        if (null != data) {
          data.documentChanges.forEach((change) async {
            if (change.type == DocumentChangeType.added ||
                change.type == DocumentChangeType.modified) {
              UserModel newUser = UserModel.fromDocSnapShot(data.documents[0]);
              checkUserInContactList(newUser);
            }
          });
        }
      });
    
  }

  _listenForUserActivityGreater() {
      _subsGreater =
          Firebase().getAllUserCollection().where('ph',isGreaterThan: UserBloc().getCurrUser().ph)
          .snapshots().listen((data) async {
        if (null != data) {
          data.documentChanges.forEach((change) async {
            if (change.type == DocumentChangeType.added ||
                change.type == DocumentChangeType.modified) {
              UserModel newUser = UserModel.fromDocSnapShot(data.documents[0]);
              checkUserInContactList(newUser);
            }
          });
        }
      });
    
  }

  checkUserInContactList(UserModel user) async {
    if(user.ph!=UserBloc().getCurrUser().ph) {
          Iterable<Contact> contacts = await ContactsService.getContactsForPhone(
        user.ph,
        withThumbnails: false);
    if (contacts != null && contacts.length > 0) {
      contacts.forEach((contact) {
        user.name = contact.displayName;
        addToController(user.id, user);
      });
    } else {
      OfflineDBUser().deleteContactFromUserContactStore(user);
    }
    }
    
  }

  _isControllerClosed(String id) {
    if (_map.containsKey(id) && _map[id] != null) {
      return _map[id].isClosed;
    }
    return true;
  }

  addToController(String id, UserModel user) {
    UserBloc().addUpdateUser(user);
    openController(id);
    OfflineDBUser().upsertInUserContactStore(user, null);
    _map[id].sink.add(user);
  }

  StreamController<UserModel> getController(String id) {
    return _map[id];
  }

  closeControllers() {
    _map.forEach((k, v) {
      if (!_isControllerClosed(k)) {
        _map[k].close();
      }
    });
    if (_subsLess != null) {
      _subsLess.cancel();
    }
    if(_subsGreater!=null) {
         _subsGreater.cancel();
    }
  }
}
