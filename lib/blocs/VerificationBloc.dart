import 'dart:async';

import 'package:chatapp/model/VerificaitionModel.dart';

class VerificationBloc {
  static VerificationBloc _verificationBloc;

  factory VerificationBloc() => _verificationBloc ??= VerificationBloc._();

  VerificationBloc._();

  StreamController<VerificaitionModel> _controller;

  openController() {
    if (isControllerClosed()) {
      _controller = StreamController.broadcast();
    }
  }

  StreamController<VerificaitionModel> getController() {
    if (!isControllerClosed()) {
      return _controller;
    }
    return null;
  }

  addToController(VerificaitionModel data) {
    if (!isControllerClosed()) {
      _controller.sink.add(data);
    }
  }

  isControllerClosed() {
    if (_controller != null) {
      return _controller.isClosed;
    }
    return true;
  }

  closeController() {
    if (!isControllerClosed()) {
      _controller.close();
    }
  }
}
