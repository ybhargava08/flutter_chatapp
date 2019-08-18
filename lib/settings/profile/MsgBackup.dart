import 'dart:async';

import 'package:chatapp/blocs/ProgressBloc.dart';
import 'package:chatapp/blocs/UserBloc.dart';
import 'package:chatapp/firebase/FirebaseRealtimeDB.dart';
import 'package:chatapp/firebase/FirebaseStorageUtil.dart';
import 'package:chatapp/model/ProgressModel.dart';
import 'package:chatapp/utils.dart';
import 'package:flutter/material.dart';

class MsgBackup extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _MsgBackupState();
}

class _MsgBackupState extends State<MsgBackup> {
  int _lastBackMillis = 0;

  bool _showLoader = false;

  String _uploadState = '';

  StreamSubscription _subs;

  static const double FONT_SIZE = 17;

  @override
  void initState() {
    super.initState();
    _listenForLastBkpDate();
    _listenForUploadEvents();
  }

  _listenForLastBkpDate() {
    String path = 'DbBackup/' + UserBloc().getCurrUser().id;
    _subs =
        FirebaseRealtimeDB().getDBPathReference(path).onValue.listen((event) {
      if (null != event.snapshot &&
          null != event.snapshot.key &&
          null != event.snapshot.value &&
          this.mounted) {
        setState(() {
          _lastBackMillis = event.snapshot.value['tm'];
        });
      }
    });
  }

  _listenForUploadEvents() {
    String id = 'db-' + UserBloc().getCurrUser().id;
    if (ProgressBloc().getProgressController() != null) {
      ProgressBloc()
          .getProgressController()
          .stream
          .where((item) => item.id == id && this.mounted)
          .listen((data) {
        if (data.data != _uploadState) {
          if (data.data == ProgressModel.ERR ||
              data.data == ProgressModel.END) {
            setState(() {
              _uploadState = data.data;
              _showLoader = false;
            });
            ProgressBloc().closeProgressController();
          } else {
            setState(() {
              _uploadState = data.data;
              _showLoader = true;
            });
          }
        }
      });
    }
  }

  _doUpload() {
    FirebaseStorageUtil().uploadDbFile(context);
    ProgressBloc().openProgressController();
    _listenForUploadEvents();
  }

  @override
  void dispose() {
    if (null != _subs) {
      _subs.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String lastBkp = (_lastBackMillis > 0)
        ? Utils().getDateTimeInFormat(_lastBackMillis, null, 'backupDate')
        : 'Never';
    return Container(
      margin: EdgeInsets.fromLTRB(20, 40, 0, 0),
      width: 300,
      height: 200,
        child: Flex(
            direction: Axis.vertical,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Flexible(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    IconTheme(
                      data: IconThemeData(color: Theme.of(context).accentColor),
                      child: Icon(Icons.cloud_upload),
                    ),
                    Container(
                      margin: EdgeInsets.only(left: 10),
                      child: Text(
                        'Last Backup',
                        style: TextStyle(
                            color: Theme.of(context).accentColor,
                            fontWeight: FontWeight.w600,
                            fontSize: FONT_SIZE),
                      ),
                    )
                  ],
                ),
              ),
              Flexible(
                child: Text(
                  'Backup your messages',
                  style: TextStyle(fontSize: FONT_SIZE),
                ),
              ),
              Flexible(
                child: Text(
                  'Last Backup Time: ' + lastBkp,
                  style: TextStyle(fontSize: FONT_SIZE),
                ),
              ),
              Flexible(
                child: _showLoader
                    ? CircularProgressIndicator()
                    : RaisedButton(
                        color: Theme.of(context).accentColor,
                        textColor: Colors.white,
                        elevation: 5.0,
                        splashColor: Colors.blueAccent,
                        child: Text(
                          'Backup',
                          style: TextStyle(fontSize: FONT_SIZE),
                        ),
                        onPressed: () {
                          _doUpload();
                        },
                      ),
              )
            ]),
      
    );
  }
}
