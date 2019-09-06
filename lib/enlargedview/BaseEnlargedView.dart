import 'package:chatapp/model/ChatModel.dart';
import 'package:flutter/material.dart';

class BaseEnlargedView {
  Widget layoutFileWithAddCaption(ChatModel chat, BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      color: Colors.black.withOpacity(0.6),
      child: Container(
        width: 0.7 * MediaQuery.of(context).size.width,
        margin: EdgeInsets.only(right: 100),
        padding: EdgeInsets.fromLTRB(20, 5, 0, 5),
        child: TextField(
          keyboardType: TextInputType.multiline,
          maxLines: 10,
          minLines: 1,
          decoration: InputDecoration(
            hintText: 'Add a Caption',
            hintStyle: TextStyle(
              color: Colors.white,
              fontSize: 20,
            ),
            border: InputBorder.none,
            focusedBorder: InputBorder.none,
          ),
          style: TextStyle(color: Colors.white, fontSize: 18),
          cursorColor: Colors.white,
          autofocus: false,
          onChanged: (text) {
            chat.chat = text;
          },
        ),
      ),
    );
  }

  Widget layoutFileWithShowCaption(ChatModel chat, BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      color: Colors.black.withOpacity(0.4),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Center(
            child: Text(
          chat.chat,
          style: TextStyle(color: Colors.white, fontSize: 18),
        )),
      ),
    );
  }
}
