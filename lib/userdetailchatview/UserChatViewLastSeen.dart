import 'package:chatapp/utils.dart';
import 'package:flutter/material.dart';

class UserChatViewLastSeen extends StatelessWidget {

  getLastSeenText() {
      String result = '';
     String date =  Utils().getDateTimeInFormat(0,'date','userchatview');
     if(date == 'TODAY' || date == 'YESTERDAY') {
         result = 'last seen '+date.toLowerCase()+' at ';
     }else{
       result = 'last seen on '+date+' at ';
     }

     result += Utils().getDateTimeInFormat(0,'time','userchatview');
     return result;
  }
    @override
  Widget build(BuildContext context) {
    

    return Align(
                    alignment: Alignment.topLeft,
                    child: (/* !user.isOnline */false)
                      ? Text(
                          getLastSeenText(),
                          style: TextStyle(fontSize: 13),
                        )
                      : Container(
                          width: 0,
                          height: 0,
                        ),
                  );
  }
}