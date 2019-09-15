import 'package:chatapp/utils.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class FirebaseNotifications {
  static FirebaseNotifications _notifications;
  FirebaseMessaging _messaging;

  factory FirebaseNotifications() =>
      _notifications ??= FirebaseNotifications._internal();

  FirebaseNotifications._internal() {
    _messaging = FirebaseMessaging();
  }

  Future<String> setUpListeners() async {
    try{
return Utils().runSafe(() async {
  String token;
  try{
     await Utils().runSafe(()async {
         token = await _messaging.getToken().catchError((err)  {
           throw Exception(err);
           });
     });
  }on Exception catch(e){
  }

    _messaging.configure(onMessage: (Map<String, dynamic> message) {
    }, onResume: (Map<String, dynamic> message) async {
      
    }, onLaunch: (Map<String, dynamic> message) async {
    });
    return token;
});
    }on Exception catch(e) {
    }
    
    return null;
  }
}
