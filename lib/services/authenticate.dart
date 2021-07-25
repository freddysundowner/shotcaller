import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shotcaller/controllers/controllers.dart';
import 'package:shotcaller/models/user_model.dart';
import 'package:shotcaller/screen/admin_screen.dart';
import 'package:shotcaller/screen/phone_number.dart';
import 'package:shotcaller/screen/startcall_screen.dart';
import 'package:shotcaller/screen/username_page.dart';
import 'package:shotcaller/services/database.dart';
import 'package:shotcaller/shared/colors.dart';

class AuthService {
  /// returns the initial screen depending on the authentication results
  handleAuth() {
    if(FirebaseAuth.instance.currentUser == null){
      return PhoneNumber();
    }

    return FutureBuilder(
      future: Database().getUserProfile(FirebaseAuth.instance.currentUser.uid),
      builder: (BuildContext context, snapshot) {
        //print(snapshot.error);
        if(snapshot.connectionState == ConnectionState.waiting){
          return Container(
            color: ThemeColor1,
            child: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        if (snapshot.hasData ==true) {
          Get.put(UserController()).user = snapshot.data;
          if(Get.put(UserController()).user.usertype== "admin"){
            return Admin();
          }
          return StartCall();
        } else {
          return UsernamePage();
        }
      },
    );
  }

  signIn(BuildContext context, AuthCredential authCreds) async {
    var result = await FirebaseAuth.instance.signInWithCredential(authCreds);

    if (result.user != null) {
      UserModel userModel = await Database().getUserProfile(FirebaseAuth.instance.currentUser.uid);
      if(userModel == null){
        Get.to(() => UsernamePage());
      }else{
        Get.to(() => StartCall());
      }

    } else {
      print("Error");
    }
  }

  signInWithOTP(BuildContext context, smsCode, verId) {
    PhoneAuthCredential authCreds = PhoneAuthProvider.credential(verificationId: verId, smsCode: smsCode);
    signIn(context, authCreds);
  }

}