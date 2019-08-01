import 'package:cached_network_image/cached_network_image.dart';
import 'package:chatapp/model/UserModel.dart';
import 'package:flutter/material.dart';

class UserEnlargedImgDialog {

     static UserEnlargedImgDialog _showImgDialog;

     factory UserEnlargedImgDialog() => _showImgDialog ??=UserEnlargedImgDialog._();

     UserEnlargedImgDialog._();

     Dialog getDialog(UserModel user,dynamic maxWidth,dynamic maxHeight) {
       
         return Dialog(
             child: ConstrainedBox(
                         constraints: BoxConstraints(
                             minHeight: 0,
                             minWidth: 0,
                             
                             maxWidth: 0.5*((maxWidth < maxHeight)?maxWidth:maxHeight),
                             maxHeight: 0.6*((maxWidth < maxHeight)?maxWidth:maxHeight)
                         ),
                         child: (user.photoUrl!=null)?Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.rectangle,
                        image: DecorationImage(
                          fit: BoxFit.fill,
                          image: CachedNetworkImageProvider(user.photoUrl)
                          
                          )
                        )
                  ):ClipRRect(
                     borderRadius: BorderRadius.circular(10.0),
                     child: Image.asset('assets/images/placeholder_acc.png',fit: BoxFit.cover),
                  ),
                       ),
         );
     }
}