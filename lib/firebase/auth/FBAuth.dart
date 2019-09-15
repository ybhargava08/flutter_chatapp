import 'package:chatapp/RouteConstants.dart';
import 'package:chatapp/blocs/VerificationBloc.dart';
import 'package:chatapp/login/LoginHandler.dart';
import 'package:chatapp/model/VerificaitionModel.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';

import 'package:chatapp/login/SMSCode.dart';

class FBAuth {
  static FBAuth _auth;

  factory FBAuth() => _auth ??= FBAuth._();

  static String _verificationId;

  static int _forceResendingToken;

  bool doAutoVerification = true;

  FBAuth._();
  

  Future<FirebaseUser> getCurrentUser() async {
    return await FirebaseAuth.instance.currentUser();
  }


  doPhoneAuth(String phoneNo, BuildContext context, bool resendCode) async {
    String phoneNumber;
    if (phoneNo.length == 10) {
      phoneNumber = '+1' + phoneNo;
    } else {
      phoneNumber = phoneNo;
    }

    doAutoVerification = true;

    final PhoneVerificationCompleted verficationCompleted =
        (AuthCredential credential) async {
     FirebaseUser user = await FirebaseAuth.instance.currentUser();
        if (user == null) {
          user = await FirebaseAuth.instance.signInWithCredential(credential);
        }
        _verificationId = null;
        _forceResendingToken = -1;
        try {
          await LoginHandler().doAfterLogin(user, context);
        } on Exception catch (e) {
          Navigator.popUntil(context, (currentRoute) {
            return currentRoute.settings.name == RouteConstants.PHONE_AUTH;
          });
          VerificationBloc().addToController(
              VerificaitionModel(false, VerificaitionModel.AFTER_VER_ERR));
        }
    //  }
    };

    final PhoneVerificationFailed verficationFailed = (AuthException excp) {
      Navigator.popUntil(context, (currentRoute) {
        return currentRoute.settings.name == RouteConstants.PHONE_AUTH;
      });
      VerificationBloc().addToController(
          VerificaitionModel(false, VerificaitionModel.VER_FAILED));
    };

    final PhoneCodeSent codeSent =
        (String verificationId, [int forceResendingToken]) {
      _verificationId = verificationId;
      _forceResendingToken = forceResendingToken;
      doAutoVerification = false;
        Navigator.pushNamed(context, RouteConstants.SMS_CODE,
            arguments: SMSCodeArgs(phoneNumber));
    };

    final PhoneCodeAutoRetrievalTimeout codeAutoRetrievalTimeout =
        (String verificationId) {
    };
    if (resendCode) {
      await FirebaseAuth.instance.verifyPhoneNumber(
          phoneNumber: phoneNumber,
          timeout: Duration(seconds: 5),
          verificationCompleted: verficationCompleted,
          verificationFailed: verficationFailed,
          codeSent: codeSent,
          forceResendingToken: _forceResendingToken,
          codeAutoRetrievalTimeout: codeAutoRetrievalTimeout);
    } else {
      await FirebaseAuth.instance.verifyPhoneNumber(
          phoneNumber: phoneNumber,
          timeout: Duration(seconds: 5),
          verificationCompleted: verficationCompleted,
          verificationFailed: verficationFailed,
          codeSent: codeSent,
          codeAutoRetrievalTimeout: codeAutoRetrievalTimeout);
    }
  }

  Future<void> signInWithPhoneNumber(
      String smsCode, BuildContext context) async {
    doAutoVerification = true;
    try {
    final AuthCredential authCredential = PhoneAuthProvider.getCredential(
        verificationId: _verificationId, smsCode: smsCode);

    FirebaseUser user =
        await FirebaseAuth.instance.signInWithCredential(authCredential).catchError((e){
                   throw Exception(e);
        });
    
      await LoginHandler().doAfterLogin(user, context);
    } on Exception catch (e) {
      Navigator.popUntil(context, (currentRoute){
             return currentRoute.settings.name == RouteConstants.PHONE_AUTH;
      });
      VerificationBloc().addToController(
          VerificaitionModel(false, VerificaitionModel.AFTER_VER_ERR));
    }
  }
}
