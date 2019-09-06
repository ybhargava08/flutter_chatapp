import 'package:chatapp/userdetailchatview/ChatViewInheritedWrapper.dart';
import 'package:flutter/material.dart';

class UserChatViewLastSeen extends StatefulWidget {


@override
  State<StatefulWidget> createState() => _UserChatViewLastSeenState();
}

class _UserChatViewLastSeenState extends State<UserChatViewLastSeen> {

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

     @override
  Widget build(BuildContext context) {
    
    final inherited = ChatViewInheritedWidget.of(context);
    return Align(
                    alignment: Alignment.centerLeft,
                    child: (inherited.typingInd)
                      ? Text(
                          'typing...',
                          style: TextStyle(fontSize: 15,color: Colors.white,fontWeight: FontWeight.w400),
                        )
                      : Container(
                          width: 0,
                          height: 0,
                        ),
                  );
  }
}