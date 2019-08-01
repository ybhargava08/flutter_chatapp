import 'package:chatapp/model/VerificaitionModel.dart';
import 'package:flutter/material.dart';

class MessageSnackbar{
   static MessageSnackbar _messageSnackbar;

   factory MessageSnackbar() => _messageSnackbar??=MessageSnackbar._();

   MessageSnackbar._();


Widget showSnackBar(VerificaitionModel data) {
    
    return SnackBar(
        content: Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: <Widget>[
        Icon(
          data.isSuccess ? Icons.check_circle : Icons.error,
          color: data.isSuccess ? Colors.green : Colors.red,
        ),
        Container(
          margin: EdgeInsets.only(left: 10),
          child: Text(
            data.msg,
            style: TextStyle(color: Colors.white, fontSize: 20),
          ),
        )
      ],
    ));
  }
}
