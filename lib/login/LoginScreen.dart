import 'package:chatapp/RouteConstants.dart';
import 'package:chatapp/UserMainView.dart';
import 'package:chatapp/blocs/UserBloc.dart';
import 'package:chatapp/firebase/Firebase.dart';
import 'package:chatapp/firebase/FirebaseNotifications.dart';
import 'package:chatapp/login/PermHandler.dart';
import 'package:chatapp/model/UserModel.dart';
import 'package:chatapp/utils.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:contacts_service/contacts_service.dart';

class LoginScreen extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  GoogleSignIn _googleSignIn = GoogleSignIn(scopes: <String>[
    'email',
    'https://www.googleapis.com/auth/drive.readonly'
  ]);

  @override
  void initState() {
    super.initState();

    _googleLogin();
   //getContacts();
  }


  getContacts() async {
      await PermHandler().getContactPermissionsOnStartup();
      Iterable<Contact> contacts =  await ContactsService.getContacts();
      contacts.forEach((contact){
           print('contact name '+contact.displayName); 
           contact.phones.forEach((phone){
                    if(null!=phone) {
                         print('ph no '+phone.label+' '+phone.value);
                    }
           });
      });
     
  }
  _googleLogin() async {
    try {
      Utils().runSafe(() async {
        bool isSignedin = await _googleSignIn.isSignedIn();
        print('user signed in '+isSignedin.toString());
        GoogleSignInAccount _googleUser = _googleSignIn.currentUser;
        if (null != _googleUser) {
          print('in google login ' + _googleUser.displayName);
        }

        if (null == _googleUser) {
          _googleUser = await _googleSignIn.signInSilently();
        }
        if (null == _googleUser) {
          _googleUser = await _googleSignIn.signIn();
        }

        if (null != _googleUser) {
          print('got google user ' + _googleUser.displayName);
          _doOnLogin(_googleUser);
        } else {
          print('dint get google user');
        }
      });
    } on Exception catch (e) {
      print('got login error ' + e.toString());
    }
  }

  _doOnLogin(loggedInUser) async {
    try {
      Utils().runSafe(() async {
        String fcmToken = await FirebaseNotifications().setUpListeners();
        if (null != fcmToken) {
          UserBloc().setCurrUser(UserModel(
              loggedInUser.id,
              loggedInUser.displayName,
              loggedInUser.photoUrl,
             /*  true, */
              "",
              fcmToken,""));
          await Firebase().addUpdateUser(UserBloc().getCurrUser());
          List<UserModel> userList =
              /*await UserBloc().initFirebaseUserActivity()*/List();
          userList = userList
              .where((item) => item.id != UserBloc().getCurrUser().id)
              .toList();
          Navigator.pushReplacementNamed(context, RouteConstants.USER_VIEW,
              arguments: UserMainViewArgs(userList));
        } else {
          print('fcm is null');
        }
      });
    } on Exception catch (e) {
      print('got error while getting token ' + e.toString());
    }
  }

  @override
  void dispose() {
    
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Center(
      child: RaisedButton(
        onPressed: () {
          _googleLogin();
        },
        padding: EdgeInsets.all(3),
        splashColor: Colors.lightBlue,
        color: Colors.blue,
        elevation: 5,
        child: SizedBox(
          width: 190,
          height: 50,
          child: Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(5),
                    color: Colors.white),
                child: Image.asset(
                  'assets/images/google_img.jpg',
                  height: 30.0,
                ),
              ),
              Container(
                  padding: EdgeInsets.only(left: 10.0, right: 10.0),
                  child: Text(
                    "Sign in with Google",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold),
                  )),
            ],
          ),
        ),
      ),
    ));
  }
}
