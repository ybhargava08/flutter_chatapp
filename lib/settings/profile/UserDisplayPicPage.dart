import 'package:chatapp/model/UserModel.dart';
import 'package:chatapp/settings/profile/DisplayPic.dart';
import 'package:chatapp/settings/profile/MsgBackup.dart';
import 'package:flutter/material.dart';

class UserDisplayPicPage extends StatelessWidget {
  final UserModel user;

  UserDisplayPicPage(this.user);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
            backgroundColor: Theme.of(context).accentColor,
            elevation: 0,
            leading: IconButton(
              color: Colors.white,
              icon: Icon(Icons.arrow_back),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            title: Text(
              'Profile',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
            )),
        body: Column(
          children: <Widget>[
            Container(
              alignment: Alignment.topCenter,
              margin: EdgeInsets.only(top: 50),
              child: DisplayPic(user),
            ),
            MsgBackup()
          ],
        ));
  }
}

class UserDisplayPicPageArgs {
  final UserModel user;

  UserDisplayPicPageArgs(this.user);
}
