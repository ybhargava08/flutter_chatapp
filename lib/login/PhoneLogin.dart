import 'package:chatapp/blocs/VerificationBloc.dart';
import 'package:chatapp/firebase/auth/FBAuth.dart';
import 'package:chatapp/model/VerificaitionModel.dart';
import 'package:chatapp/snackbars/MessageSnackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PhoneLogin extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _PhoneLoginState();
}

class _PhoneLoginState extends State<PhoneLogin>
    with SingleTickerProviderStateMixin {
  TextEditingController _textEditingController = TextEditingController();

  final _scaffoldKey = GlobalKey<ScaffoldState>();

  bool _showLoader = false;

  @override
  void initState() {
    _showLoader = false;
    VerificationBloc().getController().stream.listen((data) {
      if (this.mounted) {
        if (data.msg != VerificaitionModel.SHOW_PH_SC_LOADER) {
          _scaffoldKey.currentState
              .showSnackBar(MessageSnackbar().showSnackBar(data));
        }

        setState(() {
          _showLoader = false;
        });
      }
    });
    super.initState();
  }

  doPhoneAuth(String phNo) async {
    /* try{
        Utils().runSafe(() async {*/
    FBAuth().doPhoneAuth(phNo, context, false);
    /*});
    }on Exception catch(e) {
            //print('error while login in ' + e.toString());
      Navigator.popUntil(context, (currentRoute){
             return currentRoute.settings.name == RouteConstants.PHONE_AUTH;
      });
      VerificationBloc().addToController(
          VerificaitionModel(false, VerificaitionModel.AFTER_VER_ERR));
    }*/
  }

  @override
  void dispose() {
    if (null != _textEditingController) {
      _textEditingController.dispose();
    }
    super.dispose();
  }

  doOnSubmit(String phNo) {
    setState(() {
      _showLoader = true;
    });
    FocusScope.of(context).unfocus();
    doPhoneAuth(phNo);
  }

  bool isValidateNumber(String ph) {
    return ph != null && ph.length == 10;
  }

  Widget getPhoneLoginScreen() {
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
              'Step 1',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w300),
            ),
          ),
          Flexible(
            child: Text(
              'Verify Phone Number',
              style: TextStyle(fontSize: 25, fontWeight: FontWeight.w600),
            ),
          ),
          Flex(
            direction: Axis.horizontal,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              Flexible(
                flex: 3,
                child: Text(
                  '+1',
                  style: TextStyle(fontSize: 25, fontWeight: FontWeight.w500),
                ),
              ),
              Flexible(
                flex: 7,
                child: TextField(
                  controller: _textEditingController,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  inputFormatters: [LengthLimitingTextInputFormatter(10)],
                  style: TextStyle(fontSize: 25, fontWeight: FontWeight.w400),
                  onSubmitted: (val) {
                    //print('in onsubmitted ' + val);
                    if (isValidateNumber(val)) {
                      doOnSubmit(_textEditingController.text);
                    }
                  },
                ),
              )
            ],
          ),
          SizedBox(
            width: 250,
            height: 50,
            child: _showLoader
                ? Container(
                   // color: Colors.teal[300],
                    alignment: Alignment.center,
                    child: /*Text(
                      'Verifying. Please Wait...',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.7), fontSize: 20),
                    )*/CircularProgressIndicator(),
                  )
                : RaisedButton(
                    color: Colors.teal[300],
                    elevation: 5.0,
                    splashColor: Colors.lightBlue,
                    textColor: Colors.white,
                    child: Text(
                      'Verify',
                      style:
                          TextStyle(fontSize: 25, fontWeight: FontWeight.w600),
                    ),
                    onPressed: () {
                      if (isValidateNumber(_textEditingController.text)) {
                        doOnSubmit(_textEditingController.text);
                      }
                    },
                  ),
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
          title: Text('Authenticate Yourself'),
          centerTitle: true,
        ),
        backgroundColor: Colors.transparent,
        body: getPhoneLoginScreen(),
      ),
    );
  }
}
