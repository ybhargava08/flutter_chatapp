import 'dart:async';

import 'package:chatapp/blocs/UserBloc.dart';
import 'package:chatapp/database/SembastDatabase.dart';
import 'package:chatapp/firebase/Firebase.dart';
import 'package:chatapp/model/UserModel.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:contacts_service/contacts_service.dart';

class UserListener {
  static UserListener _singleUserBloc;

  factory UserListener() => _singleUserBloc ??= UserListener._();

  StreamSubscription _subs;
  UserListener._();

  Map<String, StreamController<UserModel>> _map = Map();

  openController(String id) {
    if (_isControllerClosed(id)) {
      _listenForUserActivity();
      _map[id] = StreamController.broadcast();
    }
  }

  _listenForUserActivity() {
    if (_subs == null) {
      _subs =
          Firebase().getAllUserCollection().snapshots().listen((data) async {
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
  }

  checkUserInContactList(UserModel user) async {
    Iterable<Contact> contacts = await ContactsService.getContactsForPhone(
        user.ph,
        withThumbnails: false);
    if (contacts != null && contacts.length > 0) {
      contacts.forEach((contact) {
        print('in contact list found user with name ' + contact.displayName);
        user.name = contact.displayName;
        addToController(user.id, user);
      });
    } else {
      SembastDatabase().deleteContactFromUserContactStore(user);
    }
  }

  _isControllerClosed(String id) {
    if (_map.containsKey(id) && _map[id] != null) {
      return _map[id].isClosed;
    }
    return true;
  }

  addToController(String id, UserModel user) {
    print('adding to single user bloc controller ' +
        id +
        ' status ' +
        _isControllerClosed(id).toString());
    UserBloc().addUpdateUser(user);
    openController(id);
    SembastDatabase().upsertInUserContactStore(user, null);
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
    if (_subs != null) {
      _subs.cancel().then((val) {
        _subs = null;
      });
    }
  }
}
