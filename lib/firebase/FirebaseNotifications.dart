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
  print('starting get fcm token');
  String token;
  try{
     await Utils().runSafe(()async {
         token = await _messaging.getToken().catchError((err)  {
           throw Exception(err);
           });
     });
  }on Exception catch(e){
      print('in excp get token error');
  }
    print('got fcm token ' + token);

    _messaging.configure(onMessage: (Map<String, dynamic> message) {
        print('got fcm onMessage $message');
    }, onResume: (Map<String, dynamic> message) async {
      print('got fcm onResume $message');
      
    }, onLaunch: (Map<String, dynamic> message) async {
      print('got fcm onLaunch $message');
    });
    return token;
});
    }on Exception catch(e) {
         print('error while getting token '+e.toString());
    }
    
    return null;
  }
}
