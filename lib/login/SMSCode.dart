import 'package:chatapp/blocs/VerificationBloc.dart';
import 'package:chatapp/firebase/auth/FBAuth.dart';
import 'package:chatapp/model/VerificaitionModel.dart';
import 'package:chatapp/snackbars/MessageSnackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SMSCode extends StatefulWidget {
  final String phNo;

  SMSCode(this.phNo);

  @override
  State<StatefulWidget> createState() => _SMSCodeState();
}

class _SMSCodeState extends State<SMSCode> {
  /*static const int _codeLength = 6;

  static const double _width = 25;

  List<TextEditingController> _textControllers = List(_codeLength);

  List<FocusNode> _focusNodes = List(_codeLength);

  List<String> _codes = List(_codeLength);*/

  TextEditingController _controller = TextEditingController();
  FocusNode _focusNode = FocusNode();

  final _scaffoldKey = GlobalKey<ScaffoldState>();

  bool _showLoader = false;

  @override
  void initState() {
    VerificationBloc().addToController(VerificaitionModel(false,VerificaitionModel.SHOW_PH_SC_LOADER)); 
    if (VerificationBloc().getController() != null) {
      VerificationBloc().getController().stream.listen((data) {
        if (this.mounted) {
          _scaffoldKey.currentState
              .showSnackBar(MessageSnackbar().showSnackBar(data));
          setState(() {
            _showLoader = false;
          });
        }
      });
    }

    super.initState();
  }

  @override
  void dispose() {
    //clearTextControllers();
    //clearFocusNodes();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  /* Widget generateWidgetList() {
    List<Widget> list = List.generate(_codeLength, (int i) {
      return Flexible(
        flex: 1,
        child: buildTextField(i),
      );
    });

    //FocusScope.of(context).requestFocus(_focusNodes[0]);

    return Flex(
      direction: Axis.horizontal,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: list,
    );
  }*/

  /*Widget buildTextField(int i) {
    _textControllers[i] = TextEditingController();
    _focusNodes[i] = FocusNode();
    /*_focusNodes[i].addListener(() {
      if (_focusNodes[i].hasFocus) {
        _textControllers[i].clear();
      }
    });*/
    return Container(
      width: _width,
      margin: EdgeInsets.only(right: 10),
      child: TextField(
        controller: _textControllers[i],
        focusNode: _focusNodes[i],
        keyboardType: TextInputType.number,
        inputFormatters: [LengthLimitingTextInputFormatter(1)],
        style: TextStyle(fontSize: 25, fontWeight: FontWeight.w400),
        textAlign: TextAlign.center,
        textInputAction: (i == _codeLength - 1)
            ? TextInputAction.done
            : TextInputAction.next,
        onChanged: (val) {
          if (val != null && val != '') {
             if (i < _codeLength - 1) {
              print('val changed for textfield ' + i.toString());
              FocusScope.of(context).requestFocus(_focusNodes[i + 1]);
            }
          }
          _codes[i] = val;
        },
        onSubmitted: (val) {
          _codes[i] = val;
          if (val != null && val != '') {
            if (i < _codeLength - 1) {
              print('val submitted for textfield ' + i.toString());
              FocusScope.of(context).requestFocus(_focusNodes[i + 1]);
            }
          }
        },
      ),
    );
  }*/

  bool validateCodeEntered() {
    /*for (var i = 0; i < _codes.length; i++) {
      if (_codes[i] == null || _codes[i] == '') {
        _textControllers[i].clear();
        FocusScope.of(context).requestFocus(_focusNodes[i]);
        return false;
      }
    }
    return true;*/
    return _controller != null &&
        _controller.text != null &&
        _controller.text.length == 6;
  }

  verifyCode() {
    if (validateCodeEntered()) {
      setState(() {
        _showLoader = true;
      });
      FBAuth()
          .signInWithPhoneNumber(/*_codes.join()*/ _controller.text, context);
    }
  }

  resendCode() {
    print('ph no for resend ' + widget.phNo);
    FBAuth().doPhoneAuth(widget.phNo, context, true);
  }

  /*clearTextControllers() {
    _textControllers.forEach((controller) {
      controller.dispose();
    });
  }

  clearFocusNodes() {
    _focusNodes.forEach((node) {
      node.dispose();
    });
  }*/

  Widget getBody() {
    return Center(
        child: Container(
      width: 300,
      height: 300,
      decoration: BoxDecoration(color: Colors.white, boxShadow: [
        BoxShadow(color: Colors.grey, blurRadius: 3, offset: Offset(1.0, 1.0))
      ]),
      child: Flex(
        direction: Axis.vertical,
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          Flexible(
            child: Text(
              'Step 2',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w300),
            ),
          ),
          Flexible(
            child: Text(
              'Enter Code received via SMS',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
          ),
          Flexible(
            child: Container(
              width: 250,
              child: TextField(
                autofocus: true,
                focusNode: _focusNode,
                controller: _controller,
                keyboardType: TextInputType.number,
                inputFormatters: [LengthLimitingTextInputFormatter(6)],
                style: TextStyle(fontSize: 25, fontWeight: FontWeight.w400),
                onSubmitted: (val) {
                  verifyCode();
                },
              ),
            ),
          ),
          _showLoader
              ? Container(
                 // color: Colors.teal[300],
                  alignment: Alignment.center,
                  width: 250,
                  padding: EdgeInsets.all(10),
                  child: /*Text(
                    'Verifying. Please Wait...',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.7), fontSize: 20),
                  )*/CircularProgressIndicator(),
                )
              : Flex(
                  direction: Axis.horizontal,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    /*Flexible(
                      flex: 5,
                      child: SizedBox(
                        width: 145,
                        height: 50,
                        child: RaisedButton(
                          color: Colors.teal[300],
                          elevation: 5.0,
                          splashColor: Colors.lightBlue,
                          textColor: Colors.white,
                          child: Text(
                            'Resend Code',
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.w600),
                          ),
                          onPressed: () {
                            resendCode();
                          },
                        ),
                      ),
                    ),*/
                    Flexible(
                      flex: 5,
                      child: SizedBox(
                        width: 90,
                        height: 50,
                        child: RaisedButton(
                          color: Colors.teal[300],
                          elevation: 5.0,
                          splashColor: Colors.lightBlue,
                          textColor: Colors.white,
                          child: Text(
                            'Verify',
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.w600),
                          ),
                          onPressed: () {
                            verifyCode();
                          },
                        ),
                      ),
                    )
                  ],
                )
        ],
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomRight,
              stops: [
            0.3,
            1.0
          ],
              colors: [
            Colors.lightBlueAccent[100],
            Colors.orangeAccent,
          ])),
      child: Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          backgroundColor: Colors.black.withOpacity(0.1),
          title: Text('SMS Code Verification'),
          centerTitle: true,
        ),
        backgroundColor: Colors.transparent,
        body: getBody(),
      ),
    );
  }
}

class SMSCodeArgs {
  final String phNo;

  SMSCodeArgs(this.phNo);
}
