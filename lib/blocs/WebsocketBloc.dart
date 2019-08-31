import 'dart:async';
import 'package:adhara_socket_io/adhara_socket_io.dart';
import 'package:chatapp/blocs/NotificationBloc.dart';
import 'package:chatapp/blocs/UserBloc.dart';
import 'package:chatapp/database/ChatReceiptDB.dart';
import 'package:chatapp/database/SembastChat.dart';
import 'package:chatapp/model/WebSocModel.dart';

class WebsocketBloc {
  static WebsocketBloc _websocketBloc;

  factory WebsocketBloc() => _websocketBloc ??= WebsocketBloc._();

  WebsocketBloc._();

  StreamController<WebSocModel> _controller;

  SocketIO socket;

  SocketIOManager manager;

  static const String uri = 'https://chatapp-socketio-server.herokuapp.com';

  openSocketConnection() async {
    _openStreamController();
  
      manager = SocketIOManager();
     socket = await manager.createInstance(SocketOptions(uri
    ,query:{'userId':UserBloc().getCurrUser().id},enableLogging:true,nameSpace: '/')); 
    
    socket.connect();

    socket.onConnect((data){
          print('connected');
    });

    socket.on(WebSocModel.TYPING, (data) {
               _addInStreamController(WebSocModel.fromJson(data));
    }); 
    socket.on(WebSocModel.RECEIPT_DEL,(data) {
        if(data is List) {
            data.forEach((item) {
                doOnChatReceiptsReceived(item,socket);
            });
        }else{
          doOnChatReceiptsReceived(data,socket);
        }
         
    });

    socket.onConnectError((data) {
        print('got error '+data);  
    });

    socket.onDisconnect((data){
                print('client dissconnected '+data.toString());
    }); 
  }

  doOnChatReceiptsReceived(Map<String,dynamic> data,SocketIO socket) async {
      WebSocModel model = WebSocModel.fromJson(data);
            SembastChat()
            .updateDeliveryReceipt(model.chatId, model.value)
            .then((_) {
             NotificationBloc().addToNotificationController(int.parse(model.chatId), model.value); 
             socket.emit(WebSocModel.RECEIVED_FROM_SERVER, [model.chatId]);
        });
  }

  addDataToSocket(String event, WebSocModel modelData) {
    if (null != socket) {
      if (event == WebSocModel.TYPING) {
        socket.emit(event, [modelData.toJson()]);
      } else if (event == WebSocModel.RECEIPT_DEL) {
        socket.emitWithAck(event, [modelData.toJson()]).then((chatId) {
          print('callback called got data ' + chatId[0]);
          ChatReceiptDB().deleteReceiptInDB(chatId[0]);
        });
      }
    }
  }

  closeSocket() {
    if (null != manager && null != socket) {
      manager.clearInstance(socket);
    }
    _closeStreamController();
  }

  _openStreamController() {
    if (_isStreamControllerClosed()) {
      _controller = StreamController.broadcast();
    }
  }

  _addInStreamController(WebSocModel data) {
    _openStreamController();
    _controller.sink.add(data);
  }

  StreamController<WebSocModel> getStreamController() {
    return _controller;
  }

  _isStreamControllerClosed() {
    return null == _controller || _controller.isClosed;
  }

  _closeStreamController() {
    if (!_isStreamControllerClosed()) {
      _controller.close();
    }
  }
}
