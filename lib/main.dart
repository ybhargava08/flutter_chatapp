import 'package:chatapp/PageSlideRightRoute.dart';
import 'package:chatapp/RouteConstants.dart';
import 'package:chatapp/UserMainView.dart';
import 'package:chatapp/enlargedview/ImageEnlargedView.dart';
import 'package:chatapp/login/MainScreen.dart';
import 'package:chatapp/login/PhoneLogin.dart';
import 'package:chatapp/login/SMSCode.dart';
import 'package:chatapp/settings/profile/UserDisplayPicPage.dart';
import 'package:chatapp/userdetailchatview/UserChatView.dart';
import 'package:flutter/material.dart';

import 'enlargedview/MediaEnlargedView.dart';

main() => runApp(MaterialApp(
      home: MainScreen(),
     // home: SMSCode('4014285043'),
      //showPerformanceOverlay: true,
      debugShowCheckedModeBanner:false,
      onGenerateRoute: (RouteSettings settings) {
        //print('route name ' + settings.name);
        switch (settings.name) { 
          case RouteConstants.PHONE_AUTH:
            return MaterialPageRoute(builder: (context)=> PhoneLogin());
          case RouteConstants.USER_VIEW:
            UserMainViewArgs args = settings.arguments; 
            return MaterialPageRoute(builder: (context) => UserMainView(args.list));
            break;
          case RouteConstants.CHAT_DETAIL:
            UserChatViewArgs userViewArgs = settings.arguments;

            return PageSlideRightRoute(
                widget:
                    UserChatView(userViewArgs.toUser));
            break;
          case RouteConstants.MEDIA_VIEW:
            MediaEnlargedViewArgs args = settings.arguments;
            return MaterialPageRoute(
              builder: (context) => MediaEnlargedView(args.chat, args.toUser, args.showPickerButton,args.autoplay)
            );
            break;
          case RouteConstants.IMAGE_VIEW:
           ImageEnlargedViewArgs args = settings.arguments;
           return MaterialPageRoute(
               builder: (context) => ImageEnlargedView(args.base,args.showMediaPickerButton)
           );          
           break;
           case RouteConstants.SMS_CODE:
           SMSCodeArgs args = settings.arguments;
           return MaterialPageRoute(
             builder: (context) => SMSCode(args.phNo)
           );
           break;
           case RouteConstants.SETTINGS:
            UserDisplayPicPageArgs args = settings.arguments;
            return MaterialPageRoute(builder: (context) => UserDisplayPicPage(args.user)); 
           default: return MaterialPageRoute(builder: (context)=> MainScreen());   
        }
      },
    ));
