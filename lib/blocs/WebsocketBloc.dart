import 'dart:async';
import 'package:adhara_socket_io/adhara_socket_io.dart';
import 'package:chatapp/blocs/NotificationBloc.dart';
import 'package:chatapp/blocs/UserBloc.dart';
import 'package:chatapp/blocs/UserLatestChatBloc.dart';
import 'package:chatapp/database/ChatReceiptDB.dart';
import 'package:chatapp/database/OfflineDBChat.dart';
import 'package:chatapp/firebase/PathConstants.dart';
import 'package:chatapp/model/UserLatestChatModel.dart';
import 'package:chatapp/model/WebSocModel.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class WebsocketBloc {
  static WebsocketBloc _websocketBloc;

  factory WebsocketBloc() => _websocketBloc ??= WebsocketBloc._();

  WebsocketBloc._();

  StreamController<WebSocModel> _controller;

  SocketIO socket;

  SocketIOManager manager;

  openSocketConnection() async {
    _openStreamController();

    manager = SocketIOManager();
    socket = await manager.createInstance(SocketOptions(PathConstants.BASE_REST_URI,
        query: {'userId': UserBloc().getCurrUser().id},
        enableLogging: true,
        nameSpace: '/'));

    socket.connect();

    socket.onConnect((data) {
      print('connected');
    });

    socket.on(WebSocModel.TYPING, (data) {
      _addInStreamController(WebSocModel.fromJson(data));
    });
    socket.on(WebSocModel.RECEIPT_DEL, (data) {
      print('got websocket receipt '+data.toString());
      if (data is List) {
        data.forEach((item) {
          doOnChatReceiptsReceived(item, socket);
        });
      } else {
        doOnChatReceiptsReceived(data, socket);
      }
    });

    socket.on(WebSocModel.DELIVERED_COUNT, (data) {
      UserLatestChatModel userLatestChatModel =
          UserLatestChatModel(data['fromUserId'], UserLatestChatModel.COUNT, 1);
      UserLatestChatBloc().addToChatCountController(userLatestChatModel);
    });

    socket.onConnectError((data) {
      print('got error ' + data);
    });

    socket.onDisconnect((data) {
      print('client disconnected ' + data.toString());
    });
  }

  doOnChatReceiptsReceived(Map<String, dynamic> data, SocketIO socket) async {
    WebSocModel model = WebSocModel.fromJson(data);
    OfflineDBChat()
        .updateDeliveryReceipt(model.chatId, model.value)
        .then((_) {
        NotificationBloc()
            .addToNotificationController(int.parse(model.chatId), model.value);
        socket.emit(WebSocModel.RECEIVED_FROM_SERVER, [model.chatId]);
    });
  }

  addDataToSocket(String event, WebSocModel modelData) async {
    if (null != socket) {
      if (event == WebSocModel.TYPING) {
        socket.emit(event, [modelData.toJson()]);
      } else if (event == WebSocModel.RECEIPT_DEL) {
        UserLatestChatBloc().addToChatCountController(UserLatestChatModel(
            modelData.fromUserId, UserLatestChatModel.COUNT, -1));
        http.Response resp = await http.post(
            PathConstants.BASE_REST_URI+'/delivery',
            body: modelData.toJson()).catchError((err) {
                      print('got err while sending delivery '+err.toString()); 
            });
        if (200 == resp.statusCode) {
          if (null != resp.body) {
            Map<String, dynamic> response =
                json.decode(resp.body);
            ChatReceiptDB().deleteReceiptInDB(response['resp']);
          }
        }
      }
    }
  }

  deleteChatReceiptsFromServer(List<int> chatIdList) async {
     String chatIdJson = json.encode(chatIdList);
     print('deleting chat reeipts '+chatIdJson);
     Map<String, String> requestHeaders = {
       'Content-type': 'application/json',
       'Accept': 'application/json',
     };
      http.Response response = await http.post(
       PathConstants.BASE_REST_URI+'/deleteReceipts',headers: requestHeaders,body: chatIdJson 
      ).catchError((err) {
print('got err while deleteChatReceiptsFromServer '+err.toString()); 
      });
      if(200 == response.statusCode) {
          print('got resp '+response.body);
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
