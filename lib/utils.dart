import 'dart:async';

import 'package:audioplayers/audio_cache.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import 'package:chatapp/model/UserModel.dart';
import 'package:chatapp/model/ChatModel.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:vibration/vibration.dart';

class Utils {
  static Utils _utils;

  factory Utils() => _utils ??= Utils._();

  Utils._();

  static const String _timeFormat = 'h:mm a';
  static const String _dfShort = 'M/d/yy';
  static const String _dfLong = 'yMMMMd';
  static const String _dfLongTime = 'M/d/yy h:mm a';

  static AudioCache _cache = AudioCache();

  getUserModelFromMsg(Map<String, dynamic> map) {
    return UserModel.fromJson(map);
  }

  getChatFromMsg(Map<String, dynamic> map) {
    //print('got chat message ' + map.toString());
    return ChatModel.fromJson(map);
  }

  String getDateInFormat() {
    return DateFormat('yyyyMMdd HH:mm:ss').format(DateTime.now());
  }

  String getDateTimeInFormat(int timeMillis, String type, String from) {
    if (null != timeMillis && timeMillis > 0) {
      DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(timeMillis);
      DateTime currTime = DateTime.now();
      if (from == 'userview') {
        if (currTime.year == dateTime.year &&
            currTime.month == dateTime.month &&
            currTime.day == dateTime.day) {
          return DateFormat(_timeFormat).format(dateTime);
        } else if (currTime.year == dateTime.year &&
            currTime.month == dateTime.month &&
            (currTime.day - dateTime.day) == 1) {
          return 'Yesterday';
        } else {
          return DateFormat(_dfShort).format(dateTime);
        }
      } else if (from == 'userchatview') {
        if (type == 'date') {
          if (currTime.year == dateTime.year &&
              currTime.month == dateTime.month &&
              currTime.day == dateTime.day) {
            return 'TODAY';
          } else if (currTime.year == dateTime.year &&
              currTime.month == dateTime.month &&
              (currTime.day - dateTime.day) == 1) {
            return 'YESTERDAY';
          } else {
            return DateFormat(_dfLong).format(dateTime);
          }
        } else if (type == 'time') {
          return DateFormat(_timeFormat).format(dateTime);
        }
      } else if (from == 'backupDate') {
        return DateFormat(_dfLongTime).format(dateTime);
      }
    }
    return "";
  }

  String getChatCollectionId(String fromId, String toId) {
    if (fromId.compareTo(toId) > 0) {
      return toId + fromId;
    }
    return fromId + toId;
  }

  Future<T> runSafe<T>(Future<T> Function() func) {
    final onDone = Completer<T>();
    runZoned(
      func,
      onError: (e, s) {
        if (!onDone.isCompleted) {
          onDone.completeError(e, s as StackTrace);
        }
      },
    ).then((result) {
      if (!onDone.isCompleted) {
        onDone.complete(result);
      }
    });
    return onDone.future;
  }

  playSound(String mp3) {
    _cache.play(mp3);
  }

  showToast(
      String msg, BuildContext context, Toast duration, ToastGravity gravity) {
    Fluttertoast.showToast(
        msg: msg,
        gravity: gravity,
        toastLength: duration,
        backgroundColor: Colors.black.withOpacity(0.5),
        fontSize: 15,
        textColor: Colors.white);
  }

  bool isStringEmpty(String s) {
    return s == null || s.trim().length == 0;
  }

  doVibrate(int duration) async {
    bool hasVibrator = await Vibration.hasVibrator();
    if (hasVibrator) {
      bool hasAmplitude = await Vibration.hasAmplitudeControl();
      if (hasAmplitude) {
        Vibration.vibrate(duration: duration, amplitude: 128);
      } else {
        Vibration.vibrate(duration: duration);
      }
    }
  }
}
