import 'dart:async';

import 'package:chatapp/model/ProgressModel.dart';

class ProgressBloc {

    static ProgressBloc _progressBloc;

    factory ProgressBloc() =>_progressBloc ??=ProgressBloc._();

    ProgressBloc._();

    StreamController<ProgressModel> _progressController;

    Map<String,bool> _inProgressMap = Map();

    addToInProgressMap(String id) {
         _inProgressMap[id] = true;
    }

    removeFromInProgressMap(String id) {
          if(_inProgressMap.containsKey(id)) {
               _inProgressMap.remove(id);
          }
    }

    isUploadInProgress(String id) {
         return _inProgressMap.containsKey(id);
    }

    openProgressController() {
        print('opening progress controller ');
         if(isProgressControllerClosed()) {
               _progressController = StreamController.broadcast();
         }
    }

    isProgressControllerClosed() {
             if(null!=_progressController && !_progressController.isClosed) {
                 return false;
             }
             return true;
    }

    closeProgressController() {
      print('closing progress controller ');
            if(!isProgressControllerClosed()) {
                   _progressController.close(); 
            }
    }

    addToProgressController(ProgressModel data) {
                print('start adding to progress bloc  status '+isProgressControllerClosed.toString()); 
                if(!isProgressControllerClosed()) {
                    getProgressController().sink.add(data);
                }
                
    }

    StreamController<ProgressModel> getProgressController() {
              return _progressController;
    }
}