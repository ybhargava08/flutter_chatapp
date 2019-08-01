import 'dart:async';

import 'package:chatapp/model/NotificationModel.dart';

class NotificationBloc {
    static NotificationBloc _progressBloc;

    factory NotificationBloc() =>_progressBloc ??=NotificationBloc._();

    NotificationBloc._();

    StreamController<NotificationModel> _notificationController;

    openNotificationController() {
         if(isNotificationControllerClosed()) {
               _notificationController = StreamController.broadcast();
         }
    }

    isNotificationControllerClosed() {
             if(null!=_notificationController && !_notificationController.isClosed) {
                 return false;
             }
             return true;
    }

    closeNotificationController() {
            if(!isNotificationControllerClosed()) {
                   _notificationController.close(); 
            }
    }

    addToNotificationController(int chatId,String status) {
                openNotificationController();
                getNotificationController().sink.add(NotificationModel(chatId, status));
                
    }

    StreamController<NotificationModel> getNotificationController() {
              return _notificationController;
    }
}