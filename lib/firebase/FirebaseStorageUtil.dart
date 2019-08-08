import 'dart:async';
import 'dart:io';

import 'package:chatapp/blocs/NotificationBloc.dart';
import 'package:chatapp/blocs/ProgressBloc.dart';
import 'package:chatapp/blocs/UserBloc.dart';
import 'package:chatapp/firebase/Firebase.dart';
import 'package:chatapp/firebase/PathConstants.dart';
import 'package:chatapp/model/ChatModel.dart';
import 'package:chatapp/model/ProgressModel.dart';
import 'package:chatapp/model/UserModel.dart';
import 'package:chatapp/utils.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_native_image/flutter_native_image.dart';
import 'package:path_provider/path_provider.dart';
import 'package:thumbnails/thumbnails.dart';

class FirebaseStorageUtil {
  static FirebaseStorageUtil _firebaseStorageUtil;

  StorageReference _ref;

  factory FirebaseStorageUtil() =>
      _firebaseStorageUtil ??= FirebaseStorageUtil._internal();

  FirebaseStorageUtil._internal() {
    FirebaseStorage.instance.setMaxDownloadRetryTimeMillis(1);
    FirebaseStorage.instance.setMaxOperationRetryTimeMillis(1);
    FirebaseStorage.instance.setMaxUploadRetryTimeMillis(1);
    _ref = FirebaseStorage.instance.ref();
  }

  Future<String> createThumbnail(ChatModel chat) async {
    if (null == chat.thumbnailPath || "" == chat.thumbnailPath) {
      chat.thumbnailPath = await Thumbnails.getThumbnail(
          videoFile: chat.localPath, imageType: ThumbFormat.PNG, quality: 11);

      print('Thumbnail generated at ' + chat.thumbnailPath);
    }

    return chat.thumbnailPath;
  }

  Future<String> createDirIfNotExists(String folder) async {
    String appDir = (await getApplicationDocumentsDirectory()).path;
    String dirPath = '$appDir/' + folder;
    bool dirExists = await Directory(dirPath).exists();
    if (!dirExists) {
      await Directory(dirPath).create();
    }
    return dirPath;
  }

  Future<bool> checkIfFileExists(String filePath) async {
    print('checking file exists ' + filePath);
    return await File(filePath).exists();
  }

  Future<String> copyFile(String fileName, String oldFilePath) async {
    String dirPath = await createDirIfNotExists(PathConstants.CHATAPP_MEDIA);
    String completeFilePath = dirPath + '/' + fileName;
    bool fileExists = await File(completeFilePath).exists();
    if (!fileExists) {
      await File(oldFilePath).copy(completeFilePath);
    }
    return completeFilePath;
  }

  addThumbnailToStorage(ChatModel chat) async {
    String fileName = chat.id.toString() + '-thumb.png';
    String path = 'Thumbnail/' +
        Utils().getChatCollectionId(chat.fromUserId, chat.toUserId) +
        '/' +
        fileName;
    final StorageReference storageReference = _ref.child(path);
    StorageUploadTask task = storageReference.putFile(File(chat.thumbnailPath));

    chat.thumbnailPath = await (await task.onComplete).ref.getDownloadURL();
  }

  Future<void> addUserPhotoToFBStorage(
      UserModel user, bool compressMedia) async {
    if (!ProgressBloc().isUploadInProgress(user.id)) {
      ProgressBloc().addToInProgressMap(user.id);
      String fileName = user.id + '.' + user.photoUrl.split('.').last;
      String path = 'UserPhotos/' + fileName;
      print('in _addUserPhotoToFB ' +
          user.photoUrl +
          ' ' +
          user.id +
          ' file name ' +
          fileName);
      File compressedImage;
      if (compressMedia) {
        compressedImage = await FlutterNativeImage.compressImage(user.photoUrl,
            quality: 70, percentage: 70);
      } else {
        compressedImage = File(user.photoUrl);
      }

      final StorageReference storageReference = _ref.child(path);
      StorageUploadTask task = storageReference.putFile(compressedImage);

      ProgressBloc()
          .addToProgressController(ProgressModel(user.id, ProgressModel.START));

      task.events.listen((data) async {
        if (data.type == StorageTaskEventType.failure) {
          ProgressBloc().addToProgressController(
              ProgressModel(user.id, ProgressModel.ERR));
          ProgressBloc().removeFromInProgressMap(user.id);
        } else if (data.type == StorageTaskEventType.success) {
          String url = await storageReference.getDownloadURL();
          await Firebase()
              .getAllUserCollection()
              .document(user.id)
              .setData({'photoUrl': url}, merge: true);
          user.photoUrl = url;
          ProgressBloc().addToProgressController(
              ProgressModel(user.id, ProgressModel.END));
          ProgressBloc().removeFromInProgressMap(user.id);
        }
      });
    }
  }

  Future<void> addFileToFirebaseStorage(
      ChatModel chat, bool compressMedia) async {
    print('calling addFileToFirebaseStorage id ' + chat.id.toString());
    if (!ProgressBloc().isUploadInProgress(chat.id.toString())) {
      StorageUploadTask task;
      ProgressBloc().addToInProgressMap(chat.id.toString());
      String filetype =
          (chat.chatType == ChatModel.IMAGE) ? 'UserImages' : 'UserMedia';
      String fileName =
          chat.id.toString() + '.' + chat.localPath.split(".").last;
      chat.fileName = fileName;
      chat.localPath = await copyFile(fileName, chat.localPath);
      String path = filetype +
          '/' +
          Utils().getChatCollectionId(chat.fromUserId, chat.toUserId) +
          '/' +
          fileName;
      print('path created ' + path);
      final StorageReference storageReference = _ref.child(path);
      if (compressMedia) {
        File compressedImage = await FlutterNativeImage.compressImage(
            chat.localPath,
            quality: 80,
            percentage: 80);
        task = storageReference.putFile(compressedImage);
      } else {
        task = storageReference.putFile(File(chat.localPath));
      }

      ProgressBloc().addToProgressController(
          ProgressModel(chat.id.toString(), ProgressModel.START));
         /* NotificationBloc().addToNotificationController(
              chat.id, ChatModel.DELIVERED_TO_LOCAL);*/

      task.events.listen((data) async {
        if (data.type == StorageTaskEventType.failure) {
          print('error while uploading file');
          ProgressBloc().addToProgressController(
              ProgressModel(chat.id.toString(), ProgressModel.ERR));
          ProgressBloc().removeFromInProgressMap(chat.id.toString());
        }else if (data.type == StorageTaskEventType.progress) {
            ProgressBloc().addToProgressController(
              ProgressModel(chat.id.toString(), ProgressModel.PROGRESS));
        } 
        
        else if (data.type == StorageTaskEventType.success) {
          if (filetype == 'UserMedia') {
            await addThumbnailToStorage(chat);
          }

          print('closing progress controller after adding end for id ' +
              chat.id.toString());

          chat.firebaseStorage = path;
          await Firebase()
              .addUpdateChat(chat, Firebase.CHAT_COL_COMPLETE, true);
          ProgressBloc().addToProgressController(
              ProgressModel(chat.id.toString(), ProgressModel.END));
          ProgressBloc().removeFromInProgressMap(chat.id.toString());
         /* NotificationBloc().addToNotificationController(
              chat.id, ChatModel.DELIVERED_TO_SERVER);*/
          
        }
      });
    }
  }

  Future<File> getFileFromFirebaseStorage(ChatModel chat) async {
    try {
      return await Utils().runSafe(() async {
        if (chat.fromUserId == UserBloc().getCurrUser().id &&
            chat.localPath != null &&
            chat.localPath != '') {
          return File(chat.localPath);
        }
        String dirPath =
            await createDirIfNotExists(PathConstants.CHATAPP_MEDIA);
        if (chat.localPath == null || "" == chat.localPath) {
          chat.localPath = dirPath + '/' + chat.id.toString() + '.jpg';
        }

        bool isFileExists = await checkIfFileExists(chat.localPath);
        print('file exists ' +
            isFileExists.toString() +
            ' for chat id ' +
            chat.id.toString());
        if (!isFileExists) {
          print('downloading file from network path ' + chat.firebaseStorage);
          final StorageReference storageReference =
              _ref.child(chat.firebaseStorage);
          StorageFileDownloadTask task =
              storageReference.writeToFile(File(chat.localPath));

          await task.future;

          return File(chat.localPath);
        }

        return File(chat.localPath);
      });
    } on Exception catch (e) {
      print('got error while download ' + e.toString());
      throw Exception();
    }
  }
}
