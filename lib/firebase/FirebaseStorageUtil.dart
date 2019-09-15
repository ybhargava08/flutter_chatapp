import 'dart:async';
import 'dart:io';

import 'package:chatapp/blocs/ProgressBloc.dart';
import 'package:chatapp/blocs/UserBloc.dart';
import 'package:chatapp/firebase/Firebase.dart';
import 'package:chatapp/firebase/FirebaseRealtimeDB.dart';
import 'package:chatapp/firebase/PathConstants.dart';
import 'package:chatapp/model/ChatDeleteModel.dart';
import 'package:chatapp/model/ChatModel.dart';
import 'package:chatapp/model/ProgressModel.dart';
import 'package:chatapp/model/UserModel.dart';
import 'package:chatapp/utils.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_native_image/flutter_native_image.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:path_provider/path_provider.dart';
import 'package:thumbnails/thumbnails.dart';
import 'package:path/path.dart';

class FirebaseStorageUtil {
  static FirebaseStorageUtil _firebaseStorageUtil;

  StorageReference _ref;

  static StorageUploadTask _dbUploadTask;

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

      task.events.listen((data) async {
        if (data.type == StorageTaskEventType.failure) {
          ProgressBloc().addToProgressController(
              ProgressModel(chat.id.toString(), ProgressModel.ERR));
          ProgressBloc().removeFromInProgressMap(chat.id.toString());
        } else if (data.type == StorageTaskEventType.progress) {
          ProgressBloc().addToProgressController(
              ProgressModel(chat.id.toString(), ProgressModel.PROGRESS));
        } else if (data.type == StorageTaskEventType.success) {
          if (filetype == 'UserMedia') {
            await addThumbnailToStorage(chat);
          }
    chat.firebaseStorage = path;
          await Firebase()
              .addUpdateChat(chat, Firebase.CHAT_COL_COMPLETE, true);
          ProgressBloc().addToProgressController(
              ProgressModel(chat.id.toString(), ProgressModel.END));
          ProgressBloc().removeFromInProgressMap(chat.id.toString());
        }
      });
    }
  }

  Future<File> getFileFromFirebaseStorage(ChatModel chat) async {
    try {
      return await Utils().runSafe(() async {
        String dirPath =
            await createDirIfNotExists(PathConstants.CHATAPP_MEDIA);
        if (chat.localPath == null || "" == chat.localPath) {
          chat.localPath = dirPath + '/' + chat.firebaseStorage.split("/").last;
        }
        bool isFileExists =
            await checkIfFileExists(chat.localPath).catchError((e) {
          throw Exception(e);
        });
        if (!isFileExists) {
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
      throw Exception();
    }
  }

  Future uploadDbFile(BuildContext context) async {
    final docDir = await getApplicationDocumentsDirectory();

    final localDbPath = join(docDir.path, 'chatapp.db');

    if (await checkIfFileExists(localDbPath)) {
      String fbPath = 'db/' + UserBloc().getCurrUser().id + '/chatapp.db';
      final StorageReference storageReference = _ref.child(fbPath);

      _dbUploadTask = storageReference.putFile(File(localDbPath));

      String id = 'db-' + UserBloc().getCurrUser().id;
      ProgressBloc().openProgressController();
      _dbUploadTask.events.listen((data) async {
        if (data.type == StorageTaskEventType.failure) {
          ProgressBloc()
              .addToProgressController(ProgressModel(id, ProgressModel.ERR));
          Utils().showToast('Error while backing up. Pls retry', context,
              Toast.LENGTH_LONG, ToastGravity.CENTER);
          ProgressBloc().closeProgressController();
        } else if (data.type == StorageTaskEventType.progress) {
          ProgressBloc()
              .addToProgressController(ProgressModel(id, ProgressModel.START));
        } else if (data.type == StorageTaskEventType.success) {
          ProgressBloc()
              .addToProgressController(ProgressModel(id, ProgressModel.END));
          await FirebaseRealtimeDB().writeLastBackUpTime();
          Utils().showToast('Backup Successful', context, Toast.LENGTH_LONG,
              ToastGravity.CENTER);
          ProgressBloc().closeProgressController();
        }
      });
    } else {
    }
  }

  Future removeChatFromFBandLocalStorage(
      ChatDeleteModel chatDeleteModel) async {
    String fbPath = chatDeleteModel.fbStoragePath;
    String localPath = chatDeleteModel.localPath;
    
    _checkPathInFBStorageAndDelete(fbPath);
      if(chatDeleteModel.thumbnailPath!=null && ''!=chatDeleteModel.thumbnailPath) {
        String thumbnailPath = _getThumbnailPath(chatDeleteModel);
      _checkPathInFBStorageAndDelete(thumbnailPath);
    
      }
     
    _checkPathInLocalAndDelete(localPath);
  }

  Future<bool> _checkPathInFBStorageAndDelete(String path) async {
    if (null != path && '' != path.trim()) {
      try {        
        StorageReference _reference = _ref.child(path);
        StorageMetadata storageMetadata = await _reference.getMetadata();
        if (storageMetadata != null && storageMetadata.sizeBytes > 0) {
          await _reference.delete();
          print('deleted file from fb storage ' + path);
          return true;
        }
      } catch (e) {
        print('got error while deleting file ' + path + ' ' + e.toString());
      }
    }

    return false;
  }

  Future<bool> _checkPathInLocalAndDelete(String path) async {
    if (null != path && '' != path.trim()) {
      if (await checkIfFileExists(path) && path.contains(PathConstants.CHATAPP_MEDIA)) {
        File file = File(path);
        file.deleteSync();
        print('deleted file from local ' + path);
        return true;
      }else{
        print('not deleting local path '+path);
      }
    }
    return false;
  }

  String _getThumbnailPath(ChatDeleteModel deleteModel) {
       ChatModel chat = deleteModel.chat;
       String path = 'Thumbnail/'+Utils().getChatCollectionId(chat.fromUserId, chat.toUserId)+'/'
       +chat.id.toString()+'-thumb.png';
       return path;
  }

  Future<bool> downloadLocalDB(String path) async {
    if (!await checkIfFileExists(path)) {
      //print('downloading db from fb storage');
      try {
        String fbPath = 'db/' + UserBloc().getCurrUser().id + '/chatapp.db';
        final StorageReference storageReference = _ref.child(fbPath);
        StorageMetadata metaData = await storageReference.getMetadata();
        if (metaData.path != null && metaData.sizeBytes > 0) {
          StorageFileDownloadTask task =
              storageReference.writeToFile(File(path));
          await task.future;

          return true;
        }
      } catch (e) {
        /*print(
            'error occured while accessing file in fb storage ' + e.toString());*/
      }
    }
    return false;
  }
}
