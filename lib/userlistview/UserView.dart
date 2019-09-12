import 'package:chatapp/RouteConstants.dart';
import 'package:chatapp/blocs/UserBloc.dart';
import 'package:chatapp/enlargedview/ImageEnlargedView.dart';
import 'package:chatapp/model/BaseModel.dart';
import 'package:chatapp/userlistview/UserChatViewUnreadMsg.dart';
import 'package:chatapp/userlistview/UserViewLastMsg.dart';
import 'package:flutter/material.dart';

import 'package:chatapp/model/UserModel.dart';
import 'package:chatapp/userdetailchatview/UserChatView.dart';
import 'package:chatapp/CustomInheritedWidget.dart';
import './UserViewAvatar.dart';
import './UserViewName.dart';

class UserView extends StatelessWidget {
  final UserModel toUser;
  UserView(Key key,this.toUser): super(key:key);

  Widget buildContent(BuildContext context) {
    return Flex(
      direction: Axis.horizontal,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        GestureDetector(
          child: ConstrainedBox(
              constraints: BoxConstraints(
                  minWidth: 0.0, maxWidth: 60, minHeight: 0.0, maxHeight: 60),
              child: Stack(
                children: <Widget>[
                  Hero(
                     child: UserViewAvatar(),
                     tag: toUser.id,
                  )
                  ,
                 // UserViewOnlineInd(),
                ],
              )),
          onTap: ()  {
               /* showDialog(
                    context: context,
                    builder: (BuildContext context) => UserEnlargedImgDialog()
                        .getDialog(toUser, MediaQuery.of(context).size.width,
                            MediaQuery.of(context).size.height));*/
                   Navigator.pushNamed(context, RouteConstants.IMAGE_VIEW,
            arguments:
                ImageEnlargedViewArgs(BaseModel(null, toUser, true), false));         
              },
        ),
        Flexible(
          flex: 9,
          child: ListTile(    
              title: UserViewName(),
              subtitle: UserViewLastMsg(),
              trailing: UserChatViewUnreadMsg(),
              onTap: () {
                Navigator.pushNamed(context, '/chatDetail',
                    arguments: UserChatViewArgs(UserBloc().findUser(toUser.id)));
              }),
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    //print('build for ' + toUser.id + ' called');
    return Container(
      margin: EdgeInsets.only(left: 10.0),
      child: CustomInheritedWidget(toUser: toUser, child: buildContent(context)),
    );
  }
}
