import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:shotcaller/controllers/controllers.dart';
import 'package:shotcaller/models/user_model.dart';
import 'package:shotcaller/services/authenticate.dart';
import 'package:shotcaller/shared/colors.dart';
import 'package:shotcaller/widgets/common_widgets.dart';

import 'otpdart.dart';


class PhoneNumber extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _PhoneNumberState();
  }
}

class _PhoneNumberState extends State<PhoneNumber> {
  var _phoneNumberController = TextEditingController();
  bool loading = false;
  String error="";
  Function onSignUpButtonClick;
  UserModel user = Get.put(OnboardingController()).onboardingUser;
  String verificationId;

  @override
  void initState() {
    SystemChrome.setEnabledSystemUIOverlays([]);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeColor1,
      body: Column(
        children: <Widget>[
          SizedBox(
          height: 50,
        ),
          logoWidget(sz1: 50 , sz2: 16),
          Expanded(
            flex: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.all(40.0),
                  child: Align(
                    alignment: Alignment.center,
                    child: Text(
                      "Enter your phone number ",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
                Container(
                  width: MediaQuery.of(context).size.width / 1.2,
                  height: 55,
                  padding:
                      EdgeInsets.only(top: 4, left: 16, right: 16, bottom: 4),
                  decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.white38,  // red as border color
                      ),
                      borderRadius: BorderRadius.all(Radius.circular(50)),
                      color:  Color(0xff5c5d62),
                   ),
                  child: TextFormField(
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: '+1 1234567890',
                      hintStyle:
                          TextStyle(fontSize: 20.0, color: Colors.grey),
                    ),
                    controller: _phoneNumberController,
                  ),
                ), SizedBox(
                  height: 5,
                ),
                if(error.isNotEmpty) Text(error,style: TextStyle(color: Colors.red),),
                SizedBox(
                  height: 60,
                ),
                InkWell(
                  onTap: loading  == true ?  null : () {
                    if (_phoneNumberController.text.isNotEmpty) {
                      signUp();
                    } else {
                      setState(() {
                        error = "enter phone number first";
                      });
                    }
                  },
                  child: Container(
                    width: MediaQuery.of(context).size.width / 1.2,
                    height: 55,
                    decoration: BoxDecoration(
                        color: loading == true ? Colors.red[300] : Colors.red,
                        borderRadius: BorderRadius.all(Radius.circular(50))),
                    child: Center(
                      child: Text(
    loading  == true ? "Please Wait.." : 'Continue'.toUpperCase(),
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Future<void> verifyPhone(phoneNumber) async {
    final PhoneVerificationCompleted verified = (AuthCredential authResult) {
      AuthService().signIn(context, authResult);
    };

    final PhoneVerificationFailed verificationfailed = (authException) {
      setState(() {
        loading = false;
        error = "Technical error happened";
      });
      print('ttt ${authException.message}');
    };

    final PhoneCodeSent smsSent = (String verId, [int forceResend]) {
      this.verificationId = verId;

      setState(() {
        loading = false;
        error = "Technical error happened";
      });
      Get.offAll(OtpScreen(verificationId: this.verificationId,));
    };

    final PhoneCodeAutoRetrievalTimeout autoTimeout = (String verId) {
      this.verificationId = verId;
    };

    await FirebaseAuth.instance.verifyPhoneNumber(

      /// Make sure to prefix with your country code
        phoneNumber: phoneNumber,

        ///No duplicated SMS will be sent out upon re-entry (before timeout).
        timeout: const Duration(seconds: 5),

        /// If the SIM (with phoneNumber) is in the current device this function is called.
        /// This function gives `AuthCredential`. Moreover `login` function can be called from this callback
        /// When this function is called there is no need to enter the OTP, you can click on Login button to sigin directly as the device is now verified
        verificationCompleted: verified,

        /// Called when the verification is failed
        verificationFailed: verificationfailed,

        /// This is called after the OTP is sent. Gives a `verificationId` and `code`
        codeSent: smsSent,

        /// After automatic code retrival `tmeout` this function is called
        codeAutoRetrievalTimeout: autoTimeout);
  }


  signUp() {
    if(_phoneNumberController.text.isEmpty){
      setState(() {
        error = "Enter Phone Number";
      });
    }else{
      setState(() {
        loading = true;
        error = "";
      });
      verifyPhone(_phoneNumberController.text);
    }

  }
}
