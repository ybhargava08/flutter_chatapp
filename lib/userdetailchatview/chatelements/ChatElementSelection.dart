import 'package:chatapp/model/ChatModel.dart';
import 'package:flutter/material.dart';

class ChatElementSelection extends StatefulWidget {
  final ChatModel chat;

  ChatElementSelection(this.chat);
  @override
  State<StatefulWidget> createState() => _ChatElementSelectionState();
}

class _ChatElementSelectionState extends State<ChatElementSelection> {
  Color _bgColor = Colors.transparent;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        
        onLongPress: () {
          setState(() {
            _bgColor = Colors.blueGrey.withOpacity(0.4);
          });
        },
        onLongPressEnd: (LongPressEndDetails details) {
          setState(() {
            _bgColor = Colors.transparent;
          });
        },
        child: Container(
          width: MediaQuery.of(context).size.width,
          margin: EdgeInsets.fromLTRB(0, 5, 0, 5),
          color: _bgColor,
        ));
  }
}
