import 'package:chatapp/blocs/SingleUserBloc.dart';
import 'package:chatapp/userdetailchatview/UserChatViewLastSeen.dart';
import 'package:chatapp/userdetailchatview/UserChatViewList.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:chatapp/userdetailchatview/ChatViewInheritedWrapper.dart';
import 'package:chatapp/model/UserModel.dart';
import './UserChatViewInput.dart';

class UserChatView extends StatelessWidget {
  final UserModel toUser;

  UserChatView(this.toUser);

  Widget buildContent(UserModel user, BuildContext context) {
    return ChatViewInheritedWrapper(
      toUser: user,
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        resizeToAvoidBottomPadding: false,
        appBar: AppBar(
            automaticallyImplyLeading: false,
            centerTitle: false,
            titleSpacing: 0.0,
            title: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                IconButton(
                  alignment: Alignment.centerLeft,
                  color: Colors.white,
                  icon: Icon(Icons.arrow_back),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
                (user.photoUrl != null)
                    ? Container(
                        margin: EdgeInsets.fromLTRB(0, 0, 10, 0),
                        padding: EdgeInsets.all(0.0),
                        child: CircleAvatar(
                            backgroundImage:
                                CachedNetworkImageProvider(user.photoUrl)))
                    : Container(
                        width: 40,
                        height: 40,
                        margin: EdgeInsets.fromLTRB(0, 0, 10, 0),
                        decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            image: DecorationImage(
                                image: AssetImage(
                                    'assets/images/placeholder_acc.png'))),
                      ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    Align(
                      alignment: Alignment.topLeft,
                      child: Text(user.name),
                    ),
                    UserChatViewLastSeen(),
                  ],
                )
              ],
            )),
        body: ConstrainedBox(
          constraints: BoxConstraints(
              minHeight: 0,
              minWidth: 0,
              maxHeight: double.maxFinite,
              maxWidth: double.maxFinite),
          child: Container(
            decoration: BoxDecoration(color: Colors.orange[100]),
            child: Flex(
              direction: Axis.vertical,
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                Flexible(flex: 9, child: UserChatViewList(user.id)),
                //ChatViewOfflineMsg(),
                Container(
                  child: UserChatViewInput(),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      initialData: toUser,
      stream: SingleUserBloc().getController(toUser.id).stream,
      builder: (BuildContext context, AsyncSnapshot<UserModel> snap) {
        if (snap != null && snap.hasData) {
          return buildContent(snap.data, context);
        }
        return buildContent(toUser, context);
      },
    );
  }
}

class UserChatViewArgs {
  final UserModel toUser;

  UserChatViewArgs(this.toUser);
}
