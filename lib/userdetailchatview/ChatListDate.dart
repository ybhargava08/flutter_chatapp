import 'package:flutter/material.dart';

class ChatListDate extends StatelessWidget {

  final String text;

  ChatListDate(this.text);

    @override
  Widget build(BuildContext context) {
    return Container(
            margin: EdgeInsets.only(top: 10),
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: Colors.blueGrey[50],
                borderRadius: BorderRadius.circular(5),
                boxShadow: [
                  BoxShadow(
                      color: Colors.grey,
                      blurRadius: 1,
                      offset: Offset(1.0, 1.0))
                ]),
            child: Text(
               text,
              style: TextStyle(fontSize: 12),
            ),
          );
  }
}