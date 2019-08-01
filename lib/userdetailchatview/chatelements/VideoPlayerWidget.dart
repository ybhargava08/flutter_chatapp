import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoPlayerWidget extends StatefulWidget {
  final File file;

  final bool autoplay;

  VideoPlayerWidget(this.file,this.autoplay);

  @override
  State<StatefulWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  VideoPlayerController _playerController;

  @override
  void initState() {
    _playerController = VideoPlayerController.file(widget.file)
      ..initialize().then((_) {
        print('complete duration '+_playerController.value.duration.inSeconds.toString()
        +' total size '+_playerController.value.volume.toString());
        setState(() {});
        if(widget.autoplay) {
             _playerController.play();
        }
      });

      

      _playerController.addListener(() {
           print('current duration '+_playerController.value.position.inMilliseconds.toString());
      });
      
    super.initState();
  }

  @override
  void dispose() {
    if (null != _playerController) {
      _playerController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var width = MediaQuery.of(context).size.width;
    var height = MediaQuery.of(context).size.height;
    double iconDimension = 80;
    return Stack(
      children: <Widget>[
        _playerController.value.initialized
               
            ? ConstrainedBox(
              constraints: BoxConstraints(maxHeight: height,maxWidth: width,minHeight: 0,minWidth: 0), 
              child: Container(
                alignment: Alignment.center,
                child: AspectRatio(
                  aspectRatio: _playerController.value.aspectRatio,
                  child: VideoPlayer(_playerController),
                ),
              ),)
            
            : Container(
                width: 0,
                height: 0,
              ),
              Positioned(
                left: (width-iconDimension)/2,
                top: (height-iconDimension)/2,
                child: Container(
            width: iconDimension,
            height: iconDimension,
            decoration: BoxDecoration(
              color: Color.fromRGBO(0, 0, 0, 0.5),
              borderRadius: BorderRadius.circular(50.0),
              border: Border.all(width: 2.0, color: Colors.white),
            ),
            padding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0),
            child: IconButton(
              icon: _playerController.value.isPlaying
                  ? Icon(Icons.pause)
                  : Icon(Icons.play_arrow),
              color: Colors.white,
              iconSize: 40,
              onPressed: () {
                print('icon was pressed');
                setState(() {
                  _playerController.value.isPlaying
                      ? _playerController.pause()
                      : _playerController.play();
                });
              },
            ),
            
          ),
              )
          ,
        
      ],
    );
  }
}
