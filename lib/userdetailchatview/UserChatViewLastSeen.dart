import 'package:chatapp/userdetailchatview/ChatViewInheritedWrapper.dart';
import 'package:chatapp/utils.dart';
import 'package:flutter/material.dart';

class UserChatViewLastSeen extends StatelessWidget {

  getLastSeenText(String inputDate) {
      String result = '';
     String date =  Utils().getDateTimeInFormat(inputDate,'date','userchatview');
     if(date == 'TODAY' || date == 'YESTERDAY') {
         result = 'last seen '+date.toLowerCase()+' at ';
     }else{
       result = 'last seen on '+date+' at ';
     }

     result += Utils().getDateTimeInFormat(inputDate,'time','userchatview');
     return result;
  }
    @override
  Widget build(BuildContext context) {
    
    var inherited = ChatViewInheritedWidget.of(context);
    final user = inherited.toUser;

    return Align(
                    alignment: Alignment.topLeft,
                    child: (/* !user.isOnline */false)
                      ? Text(
                          getLastSeenText(user.lastSeenTime),
                          style: TextStyle(fontSize: 13),
                        )
                      : Container(
                          width: 0,
                          height: 0,
                        ),
                  );
  }
}