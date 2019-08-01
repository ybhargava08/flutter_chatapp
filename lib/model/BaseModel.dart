import 'package:chatapp/model/ChatModel.dart';
import 'package:chatapp/model/UserModel.dart';

class BaseModel {

  final UserModel user;

  final ChatModel chat;

  final bool isUser;

  BaseModel(this.chat,this.user,this.isUser);
}