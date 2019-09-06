import 'package:chatapp/RouteConstants.dart';
import 'package:chatapp/blocs/VerificationBloc.dart';
import 'package:chatapp/firebase/auth/FBAuth.dart';
import 'package:chatapp/login/LoginHandler.dart';
import 'package:chatapp/login/PermHandler.dart';
import 'package:chatapp/snackbars/MessageSnackbar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class MainScreen extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    VerificationBloc().openController();
    VerificationBloc().getController().stream.listen((data) {
      if (this.mounted) {
        _scaffoldKey.currentState
            .showSnackBar(MessageSnackbar().showSnackBar(data));
      }
    });
    initActivities();
    super.initState();
  }

  initActivities() async {
    await PermHandler().getContactPermissionsOnStartup();
    FirebaseUser user = await FBAuth().getCurrentUser();
    if (user != null && user.uid != null) {
      //print(' authenticated user ' + user.uid + ' ' + user.phoneNumber);
      LoginHandler().doAfterLogin(user, context);
    } else {
      //print('user not found routing to phone login screen');
      Navigator.pushReplacementNamed(context, RouteConstants.PHONE_AUTH);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      body: Center(
        child: Container(
            width: 500,
            height: 500,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                SizedBox(
                  width: 200,
                  height: 200,
                  child: Image.asset(
                    'assets/images/chat-app-logo.jpg',
                    fit: BoxFit.fill,
                  ),
                ),
                SizedBox(
                    width: 300,
                    height: 50,
                    child: /*MainScreenLoad(5,2500)*/ Image.asset(
                      'assets/images/loading.gif',
                      fit: BoxFit.cover,
                    ))
              ],
            )),
      ),
    );
  }
}
