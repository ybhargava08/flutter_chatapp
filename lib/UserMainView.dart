import 'package:chatapp/RouteConstants.dart';
import 'package:chatapp/blocs/ConnectivityListener.dart';
import 'package:chatapp/blocs/NotificationBloc.dart';
import 'package:chatapp/blocs/UserLatestChatBloc.dart';
import 'package:chatapp/blocs/UserListener.dart';
import 'package:chatapp/blocs/VerificationBloc.dart';
import 'package:chatapp/blocs/ChatListener.dart';
import 'package:chatapp/blocs/WebsocketBloc.dart';
import 'package:chatapp/firebase/Firebase.dart';
import 'package:chatapp/settings/profile/UserDisplayPicPage.dart';
import 'package:chatapp/utils.dart';
import 'package:flutter/material.dart';

import 'package:chatapp/userlistview/UserView.dart';
import 'package:chatapp/model/UserModel.dart';
import 'package:chatapp/blocs/UserBloc.dart';

class UserMainView extends StatefulWidget {
  final List<UserModel> initUserList;

  UserMainView(this.initUserList);

  @override
  State<StatefulWidget> createState() => _UserMainViewState();
}

class _UserMainViewState extends State<UserMainView> {
  @override
  void initState() {
    WebsocketBloc().openSocketConnection();
    VerificationBloc().closeController();
    UserListener().initLisener();
    UserBloc().initUserController();
    NotificationBloc().openNotificationController();
    ConnectivityListener().initListener();
    UserLatestChatBloc().openChatCountController();
    super.initState();
  }

  setUserOffline() {
    UserModel user = UserBloc().getCurrUser();
    /* user.isOnline = false; */
    user.lastSeenTime = Utils().getDateInFormat();
    Firebase().addUpdateUser(user);
  }

  @override
  void dispose() {
    WebsocketBloc().closeSocket();
    setUserOffline();
    UserBloc().closeUserController();
    NotificationBloc().closeNotificationController();
    ChatListener().closeAllListeners();
    UserListener().closeControllers();
    ConnectivityListener().closeListener();
    UserLatestChatBloc().closeChatCountController();
    Utils().clearSoundCache();
    super.dispose();
  }

  Widget buildContent(List<UserModel> list) {
    return Container(
        child: ListView.separated(
      itemBuilder: (BuildContext context, int index) {
        UserModel user = list[index];
        if (user.id != UserBloc().getCurrUser().id) {
          ChatListener().createListener(user.id);
          return Column(
            children: <Widget>[
              UserView(ValueKey(user.id), user),
            ],
          );
        }
        return Container(width: 0, height: 0);
      },
      separatorBuilder: (BuildContext context, int index) {
        return Container(
          alignment: Alignment.centerRight,
          margin: EdgeInsets.only(right: 10),
          child: SizedBox(
            width: 0.8 * MediaQuery.of(context).size.width,
            height: 1,
            child: Container(
              color: Colors.blueGrey[100],
            ),
          ),
        );
      },
      itemCount: list.length,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return getScaffold();
  }

  Widget getPopMenu() {
    return PopupMenuButton<int>(
      child: Container(
          margin: EdgeInsets.only(right: 15), child: Icon(Icons.more_vert)),
      onSelected: (value) {
        if (value == 1) {
          Navigator.pushNamed(context, RouteConstants.SETTINGS,
              arguments: UserDisplayPicPageArgs(UserBloc().getCurrUser()));
        }
        /*else if (value == 2) {
          popUpDeleteDialog();
        }else if(value == 3) {
             checkDbfileUpload();
        }*/
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          child: Text('Settings'),
          value: 1,
        ),
        /* PopupMenuItem(
          child: Text('Del Chats'),
          value: 2,
        ),
        PopupMenuItem(
          child: Text('Upload DB'),
          value: 3,
        )*/
      ],
    );
  }

  Widget getScaffold() {
    return Stack(
      children: <Widget>[
        Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            color: Colors.white,
            ),
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: Text('ChatApp'),
            actions: <Widget>[getPopMenu()],
            elevation: 5.0,
            backgroundColor: Theme.of(context).accentColor,
          ),
          body: StreamBuilder<List<UserModel>>(
            initialData: widget.initUserList,
            stream: UserBloc().getUserStreamController().stream,
            builder: (BuildContext context,
                AsyncSnapshot<List<UserModel>> snapshot) {
              if (snapshot.hasData && snapshot.data != null) {
                return buildContent(snapshot.data);
              }
              return ListView.builder(
                itemBuilder: (BuildContext context, int index) {
                  return Container(width: 0, height: 0);
                },
                itemCount: 0,
              );
            },
          ),
        )
      ],
    );

    ;
  }
}

class UserMainViewArgs {
  final List<UserModel> list;

  UserMainViewArgs(this.list);
}
