class VerificaitionModel {

    bool isSuccess;
    String msg;

    static const String VER_FAILED = 'Verification Failed';
    static const String VER_SUC = 'Verification Success';
    static const String AFTER_VER_ERR = 'Error Occurred';
    static const String SHOW_PH_SC_LOADER ='phone screen loader';

    VerificaitionModel(this.isSuccess,this.msg);
}