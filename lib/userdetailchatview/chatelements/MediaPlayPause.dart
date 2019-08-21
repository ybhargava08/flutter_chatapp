import 'dart:async';

import 'package:chatapp/blocs/ProgressBloc.dart';
import 'package:chatapp/firebase/FirebaseStorageUtil.dart';
import 'package:chatapp/model/ChatModel.dart';
import 'package:chatapp/model/ProgressModel.dart';
import 'package:flutter/material.dart';

class MediaPlayPause extends StatefulWidget {
  final ChatModel chat;
  final double dimension;
  MediaPlayPause(Key key, this.chat, this.dimension) : super(key: key);
  @override
  State<StatefulWidget> createState() => _MediaPlayPauseState();
}

class _MediaPlayPauseState extends State<MediaPlayPause> {
  bool _showProgressBar = false;
  bool _showErr = false;

  StreamSubscription _subs;

  String _prevState;

  static const double PROGRESS_BAR_DIM = 60;

  static const double RETRY_HT = 50;

  static const double RETRY_WTH = 120;

  static const double PLAY_PAUSE_DIM = 80;

  @override
  void initState() {
    super.initState();
    bool isSubsNeeded =
        (null != widget.chat.localPath && "" != widget.chat.localPath) &&
            (null == widget.chat.firebaseStorage ||
                "" == widget.chat.firebaseStorage);
    if (isSubsNeeded) {
      putFileInStorage();
    }
  }

  putFileInStorage() {
    _showProgressBar = true;
    FirebaseStorageUtil().addFileToFirebaseStorage(
        widget.chat, (widget.chat.chatType == ChatModel.IMAGE));
    _subs = ProgressBloc()
        .getProgressController()
        .stream
        .where((item) => item.id == widget.chat.id.toString())
        .listen((data) {
      //print('got progress bar for chat id '+widget.chat.id.toString()+' data '+data.data);
      if ((data.data == ProgressModel.START ||
              (data.data == ProgressModel.PROGRESS) &&
                  _prevState != ProgressModel.PROGRESS) &&
          this.mounted) {
        _prevState = data.data;
        setState(() {
          _showProgressBar = true;
          _showErr = false;
        });
      } else if (data.data == ProgressModel.END && this.mounted) {
        _prevState = data.data;
        _subs.cancel();

        setState(() {
          _showProgressBar = false;
          _showErr = false;
        });
      } else if (data.data == ProgressModel.ERR && this.mounted) {
        _prevState = data.data;
        setState(() {
          _showProgressBar = false;
          _showErr = true;
        });
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    if (null != _subs) {
      _subs.cancel();
    }
  }

  Widget getProgressBar() {
    return Container(
      width: PROGRESS_BAR_DIM,
      height: PROGRESS_BAR_DIM,
      decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          borderRadius: BorderRadius.circular(50)),
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(Colors.lightBlueAccent),
      ),
    );
  }

  Widget getPlayPauseIcon() {
    return (widget.chat.chatType == ChatModel.VIDEO)
        ? Container(
            width: PLAY_PAUSE_DIM,
            height: PLAY_PAUSE_DIM,
            decoration: BoxDecoration(
              color: Color.fromRGBO(0, 0, 0, 0.5),
              borderRadius: BorderRadius.circular(50.0),
              border: Border.all(width: 2.0, color: Colors.white),
            ),
            padding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0),
            child: IconTheme(
              child: Icon(Icons.play_arrow),
              data: IconThemeData(color: Colors.white, size: 40),
            ),
          )
        : Container(
            width: 0,
            height: 0,
          );
  }

  Widget getRetryIcon() {
    return FlatButton(
            onPressed: () {
              putFileInStorage();
            },
            child: Container(
              alignment: Alignment.centerRight,
              padding: EdgeInsets.only(left: 10),
              width: RETRY_WTH,
              height: RETRY_HT,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(40),
                  color: Colors.black.withOpacity(0.5)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  IconTheme(
                    child: Icon(Icons.file_upload),
                    data: IconThemeData(color: Colors.white, size: 30),
                  ),
                  Text(
                    'Retry',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w600),
                  )
                ],
              ),
            ));
  }

  @override
  Widget build(BuildContext context) {
    if (_showProgressBar) {
      return Positioned(
        top: (widget.dimension - PROGRESS_BAR_DIM) / 2,
        left: (widget.dimension - PROGRESS_BAR_DIM) / 2,
        child: getProgressBar(),
      );
    } else if (_showErr) {
      return Positioned(
        top: (widget.dimension - RETRY_HT) / 2,
        left: (widget.dimension - RETRY_WTH) / 2,
        child: getRetryIcon(),
      );
    } else {
      return Positioned(
        top: (widget.dimension - PLAY_PAUSE_DIM) / 2,
        left: (widget.dimension - PLAY_PAUSE_DIM) / 2,
        child: getPlayPauseIcon(),
      );
    }
  }
}
