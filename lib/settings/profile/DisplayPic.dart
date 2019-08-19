import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:chatapp/RouteConstants.dart';
import 'package:chatapp/blocs/ProgressBloc.dart';
import 'package:chatapp/enlargedview/ImageEnlargedView.dart';
import 'package:chatapp/firebase/FirebaseStorageUtil.dart';
import 'package:chatapp/model/BaseModel.dart';
import 'package:chatapp/model/ProgressModel.dart';
import 'package:chatapp/model/UserModel.dart';
import 'package:chatapp/utils.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';

class DisplayPic extends StatefulWidget {
  final UserModel user;

  DisplayPic(this.user);

  @override
  State<StatefulWidget> createState() => _DisplayPicState();
}

class _DisplayPicState extends State<DisplayPic> {
  UserModel _user;

  bool _showLoader = false;

  StreamSubscription _subs;

  @override
  void initState() {
    _user = widget.user;
    super.initState();
  }

  Widget getImage() {
    return GestureDetector(
      child: Hero(
        child: _user.photoUrl != null && (_user.photoUrl != '')
            ? _user.photoUrl.startsWith('http')
                ? CachedNetworkImage(
                    imageBuilder: (context, imageProvider) {
                      return Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            image: DecorationImage(
                                image: imageProvider, fit: BoxFit.cover)),
                      );
                    },
                    placeholder: (context, url) => CircleAvatar(
                      minRadius: 0,
                      maxRadius: 75,
                      backgroundImage:
                          ExactAssetImage('assets/images/blur_image.jpg'),
                    ),
                    errorWidget: (context, url, error) {
                      print(
                          'error occured while loading dp ' + error.toString());
                      return CircleAvatar(
                        minRadius: 0,
                        maxRadius: 75,
                        backgroundImage:
                            ExactAssetImage('assets/images/blur_image.jpg'),
                      );
                    },
                    imageUrl: _user.photoUrl,
                  )
                : CircleAvatar(
                    minRadius: 0,
                    maxRadius: 75,
                    backgroundImage: FileImage(File(_user.photoUrl)),
                  )
            : CircleAvatar(
                minRadius: 0,
                maxRadius: 75,
                backgroundImage: ExactAssetImage(
                    'assets/images/acc_placeholder_enlarged.jpg'),
              ),
        tag: _user.id,
      ),
      onTap: () {
        Navigator.pushNamed(context, RouteConstants.IMAGE_VIEW,
            arguments:
                ImageEnlargedViewArgs(BaseModel(null, _user, true), false));
      },
    );
  }

  /*Widget getImageUploadIcon() {
    return GestureDetector(
      child: Container(
        width: 50,
        height: 50,
        padding: EdgeInsets.all(5),
        decoration: BoxDecoration(
            shape: BoxShape.circle, color: Theme.of(context).accentColor),
        child: IconTheme(
          child: Icon(Icons.camera_alt),
          data: IconThemeData(color: Colors.white, size: 25),
        ),
      ),
      onTap: () {
        _showModal();
      },
    );
  }*/

  _showModal() {
    showModalBottomSheet(
        context: context,
        builder: (BuildContext bc) {
          return Flex(
            direction: Axis.horizontal,
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              Flexible(
                flex: 5,
                child: IconButton(
                  icon: Icon(Icons.camera_alt),
                  color: Colors.black,
                  iconSize: 40,
                  onPressed: () {
                    Navigator.of(context).pop();
                    pickImage(context, ImageSource.camera);
                  },
                ),
              ),
              Flexible(
                flex: 5,
                child: IconButton(
                  icon: Icon(Icons.camera),
                  color: Colors.black,
                  iconSize: 40,
                  onPressed: () {
                    Navigator.of(context).pop();
                    pickImage(context, ImageSource.gallery);
                  },
                ),
              )
            ],
          );
        });
  }

  Future<void> pickImage(BuildContext context, ImageSource source) async {
    var image = await ImagePicker.pickImage(source: source);

    if (image != null) {
      UserModel u = UserModel(_user.id, _user.name, image.path,
          _user.lastSeenTime, _user.fcmToken, _user.ph, _user.localId);
      BaseModel base = BaseModel(null, u, true);

      Navigator.pushNamed(context, RouteConstants.IMAGE_VIEW,
              arguments: ImageEnlargedViewArgs(base, true))
          .then((model) async {
        if (model is BaseModel &&
            model != null &&
            null != model.user &&
            null != model.user.photoUrl &&
            model.user.photoUrl != '' &&
            !model.user.photoUrl.startsWith('http')) {
          uploadPic(model.user);
        }
      });
    }
  }

  void uploadPic(UserModel user) {
    ProgressBloc().openProgressController();
    _subs = ProgressBloc()
        .getProgressController()
        .stream
        .where((item) => item.id == user.id)
        .listen((data) {
      if (data.data == ProgressModel.START && this.mounted) {
        setState(() {
          _showLoader = true;
        });
      } else if (data.data == ProgressModel.END && this.mounted) {
        cancelSubs();
        setState(() {
          _showLoader = false;
          _user.photoUrl = user.photoUrl;
        });
        Utils().showToast("Pic uploaded successfully", context,
            Toast.LENGTH_LONG, ToastGravity.CENTER);
      } else if (data.data == ProgressModel.ERR && this.mounted) {
        cancelSubs();
        setState(() {
          _showLoader = false;
        });
        Utils().showToast("Network unavailable. Try again later", context,
            Toast.LENGTH_LONG, ToastGravity.CENTER);
      }
    });

    FirebaseStorageUtil().addUserPhotoToFBStorage(user, true);
  }

  cancelSubs() {
    if (_subs != null) {
      _subs.cancel();
    }
  }

  @override
  void dispose() {
    cancelSubs();
    ProgressBloc().closeProgressController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      height: 0.4 * MediaQuery.of(context).size.height,
      child: Flex(
        direction: Axis.vertical,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Flexible(
            child: Stack(
              overflow: Overflow.visible,
              children: <Widget>[
                getImage(),
                Positioned(
                  left: 60,
                  child: Container(
                    decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(50)),
                    child: _showLoader
                        ? CircularProgressIndicator()
                        : Container(
                            width: 0,
                            height: 0,
                          ),
                  ),
                ),
              
              ],
            ),
          ),
          Flexible(
            child: RaisedButton(
              child: Text(
                'Add Profile Pic',
                style: TextStyle(fontSize: 17),
              ),
              textColor: Colors.white,
              color: Theme.of(context).accentColor,
              splashColor: Colors.cyan,
              elevation: 5.0,
              onPressed: () {
                _showModal();
              },
            ),
          )
        ],
      ),
    );
  }
}
