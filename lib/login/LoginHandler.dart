import 'package:chatapp/RouteConstants.dart';
import 'package:chatapp/UserMainView.dart';
import 'package:chatapp/blocs/UserBloc.dart';
import 'package:chatapp/database/SembastDatabase.dart';
import 'package:chatapp/firebase/Firebase.dart';
import 'package:chatapp/firebase/FirebaseNotifications.dart';
import 'package:chatapp/firebase/FirebaseRealtimeDB.dart';
import 'package:chatapp/model/UserModel.dart';
import 'package:chatapp/utils.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:contacts_service/contacts_service.dart';

class LoginHandler {
  static LoginHandler _loginHandler;

  factory LoginHandler() => _loginHandler ??= LoginHandler._();

  LoginHandler._();

  Future<UserModel> getUserData(String uid) async {
            DocumentSnapshot snap = await Firebase().getAllUserCollection().document(uid).get();
            if(snap!=null && snap.data!=null) {
                  return UserModel.fromDocSnapShot(snap);
            }
            return null;
  }

  doAfterLogin(FirebaseUser user, BuildContext context) async {
    try {
      Utils().runSafe(() async {
        String fcmToken = await FirebaseNotifications().setUpListeners();
        if (null != fcmToken) {
          UserModel userFromDb = await getUserData(user.uid);
          if(null==userFromDb) {
                UserBloc().setCurrUser(
              UserModel(user.uid, null, null, null, fcmToken, user.phoneNumber,DateTime.now().microsecondsSinceEpoch));

          await Firebase().addUpdateUser(UserBloc().getCurrUser());
          }else if(null!=userFromDb && userFromDb.fcmToken.compareTo(fcmToken)!=0) {
                  UserBloc().setCurrUser(
              UserModel(userFromDb.id, userFromDb.name, userFromDb.photoUrl, userFromDb.lastSeenTime, fcmToken, userFromDb.ph
              ,userFromDb.localId));
              await Firebase().addUpdateUser(UserBloc().getCurrUser());
          }else{
              UserBloc().setCurrUser(
              UserModel(userFromDb.id, userFromDb.name, userFromDb.photoUrl, userFromDb.lastSeenTime, userFromDb.fcmToken
              , userFromDb.ph,userFromDb.localId));
          }
          

          int startTime = DateTime.now().millisecondsSinceEpoch;
          List<UserModel> userList = await SembastDatabase().getAllContacts();
          if(null == userList) {
                 userList = await getDataFromContactList(true);
              
          userList = await sortUserList(userList);
          }
          int diff = DateTime.now().millisecondsSinceEpoch - startTime;
          print('total time taken preparing contact list '+diff.toString()+' ms'); 
          
          UserBloc().setInitUserAvtivityCS(userList, false);

          Navigator.pushNamedAndRemoveUntil(context, RouteConstants.USER_VIEW,
              (Route<dynamic> route) => false,
              arguments: UserMainViewArgs(userList));
        } else {
          print('fcm is null');
        }
      });
    } on Exception catch (e) {
      print('got error while getting token ' + e.toString());
    }
  }

  Future<List<UserModel>> sortUserList(List<UserModel> userList) async {
    if (null != userList && userList.length > 1) {
      List<Future> futures = List();
      userList.forEach((item) {
        futures.add(getUserChatActivity(item));
      });
      await Future.wait(futures);
      int start = DateTime.now().millisecondsSinceEpoch;
      userList.sort((a, b) {
        if(a.lastActivityTime < b.lastActivityTime) {
            return a.lastActivityTime.compareTo(b.lastActivityTime);
        }else{
           return b.lastActivityTime.compareTo(a.lastActivityTime);
        }
        
      });
      int diff = DateTime.now().millisecondsSinceEpoch - start;
      print('time taken in sorting '+diff.toString()+' ms') ; 
    }
    return userList;
  }

  Future<void> getUserChatActivity(UserModel user) async {
    int start = DateTime.now().millisecondsSinceEpoch;
    /* DocumentSnapshot doc = await Firebase()
        .getChatDocRef(
            Utils().getChatCollectionId(UserBloc().getCurrUser().id, user.id))
        .get(); */
      int time = await FirebaseRealtimeDB().getUserLastActivityTime(user.id);
      int diff = DateTime.now().millisecondsSinceEpoch - start;
      print('time taken in getting time '+diff.toString()+' ms') ; 
    if (time > 0) {
      user.lastActivityTime = time;
    }
    SembastDatabase().upsertInUserContactStore(user,null);
  }

  Future<List<UserModel>> getDataFromContactList(bool checkinFirebase) async {
    List<UserModel> contactList = List();
    int starttime = DateTime.now().millisecondsSinceEpoch;
    Iterable<Contact> contacts =
        await ContactsService.getContacts(withThumbnails: false);
    int diff = DateTime.now().millisecondsSinceEpoch - starttime;
    print('timetaken in getting CS ' + diff.toString() + ' ms ');
    List<Future> futureList = List();
    contacts.forEach((contact) async {
      String name = contact.displayName;
      UserModel user = UserModel(
          DateTime.now().microsecondsSinceEpoch.toString(),
          name,
          null,
          /* false, */
          null,
          null,
          null,
          0);
      contact.phones.forEach((phone) {
        if (phone.label.toLowerCase().contains('mobile')) {
          /*  print(
              'label ' + phone.label + ' val ' + phone.value + ' name ' + name);*/
          String validPhNo = getValidPhoneNo(phone.value);
          if (validPhNo.length >= 10) {
            // print('VALID !!!!!! phn no ' + validPhNo + ' for user ' + name);
            user.ph = validPhNo;
          }
        }
      });
      if (null != user.name && null != user.ph && user.ph !=UserBloc().getCurrUser().ph) {
        if (checkinFirebase) {
          futureList.add(checkIfContactRegistered(user, contactList));
        } else {
          contactList.add(user);
        }
      }
    });
    if (checkinFirebase) {
      await Future.wait(futureList, eagerError: false);
    }

    return contactList.toSet().toList();
  }

  Future<void> checkIfContactRegistered(
      UserModel user, List<UserModel> list) async {
    QuerySnapshot snap = await Firebase()
        .getAllUserCollection()
        .where('ph', isEqualTo: user.ph)
        .getDocuments();
    if (snap != null && snap.documents.length > 0) {
      DocumentSnapshot docSnap = snap.documents[0];
      print('got snap for ph ' + docSnap['ph']);
      user.id = docSnap['id'];
      user.fcmToken = docSnap['fcmToken'];
      user.lastSeenTime = docSnap['lastSeenTime'];
      user.photoUrl = docSnap['photoUrl'];
      user.localId = docSnap['localId'];
      if (user != null) {
        list.add(user);
        
      }
    }
  }

  String getValidPhoneNo(String ph) {
    String number = '';
    for (int i = ph.length - 1; i >= 0; i--) {
      var ch = ph[i];
      if (ch.compareTo('+') == 0 || int.tryParse(ch) != null) {
        number += ch;
      }
    }
    return number.split('').reversed.join();
  }
}
