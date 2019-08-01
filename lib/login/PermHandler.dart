import 'package:permission_handler/permission_handler.dart';


class PermHandler {

     static  PermHandler _permissionHandler;

     factory PermHandler() => _permissionHandler??=PermHandler._();

     PermHandler._();

     // Map<PermissionGroup,PermissionStatus> _permissions;

     Future<void> getContactPermissionsOnStartup() async{
          PermissionStatus status =await  PermissionHandler().checkPermissionStatus(PermissionGroup.contacts);
          if(status.value != PermissionStatus.granted.value) {
await PermissionHandler().requestPermissions([PermissionGroup.contacts]);
          }
         
     }
}