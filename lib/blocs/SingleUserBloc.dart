import 'dart:async';

import 'package:chatapp/model/UserModel.dart';

class SingleUserBloc {

   static SingleUserBloc _singleUserBloc;

   factory SingleUserBloc() => _singleUserBloc??=SingleUserBloc._();

   SingleUserBloc._();

   Map<String,StreamController<UserModel>> _map = Map();

   openController(String id) {
        if(_isControllerClosed(id)) {
               _map[id] = StreamController.broadcast();
        }
   }

   _isControllerClosed(String id) {
          if(_map.containsKey(id) && _map[id]!=null) {
               return _map[id].isClosed;
          }
          return true;
   }

   addToController(String id,UserModel user) {
     print('adding to single user bloc controller '+id+' status '+_isControllerClosed(id).toString());
     openController(id);
              _map[id].sink.add(user);
         
   }

   StreamController<UserModel> getController(String id) {
           return _map[id];
   }

   closeControllers() {
          _map.forEach((k,v) {
              if(!_isControllerClosed(k)) {
              _map[k].close();
         }
          });
         
   }
}