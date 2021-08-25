import 'package:country_code_picker/country_code_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:shotcaller/controllers/controllers.dart';
import 'package:shotcaller/models/user_model.dart';
import 'package:shotcaller/services/authenticate.dart';
import 'package:shotcaller/shared/colors.dart';
import 'package:shotcaller/utils/utils.dart';
import 'package:shotcaller/widgets/common_widgets.dart';
import 'package:shotcaller/widgets/round_button.dart';

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
  String error = "";
  Function onSignUpButtonClick;
  UserModel user = Get.put(OnboardingController()).onboardingUser;
  String verificationId;
  String countrycode;
  String countryname;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    SystemChrome.setEnabledSystemUIOverlays([]);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeColor1,
      body: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.only(
          top: 80,
          bottom: 60,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            buildTitle(),
            SizedBox(
              height: 50,
            ),
            Center(child: buildForm()),
            SizedBox(
              height: 10,
            ),
            Text(error,style: TextStyle(color: Colors.red),),
            Spacer(),

            buildBottom(),
          ],
        ),
      ),
    );
  }

  Widget buildTitle() {
    return Text(
      'Enter your phone #',
      style: TextStyle(
        fontSize: 25,
        color: Colors.white
      ),
    );
  }
  Widget buildForm() {
    return Container(
      width: 330,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          CountryCodePicker(
            initialSelection: 'US',
            showCountryOnly: false,
            alignLeft: false,
            onInit: (code) {
              countrycode = code.dialCode;
              countryname = code.name;
              user.countrycode = code.dialCode;
              user.countryname = code.name;

              print("on init ${code.name} ${code.dialCode} ${code.name}");
            },
            onChanged: (code){
              countrycode = code.dialCode;
              countryname = code.name;
              user.countrycode = code.dialCode;
              user.countryname = code.name;

            },
            padding: const EdgeInsets.all(8),
            textStyle: TextStyle(
              fontSize: 20,
            ),
          ),
          Expanded(
            child: Form(
              key: _formKey,
              child: TextFormField(
                onChanged: (value) {
                  _formKey.currentState.validate();
                },
                validator: (value) {
                  if (value.isEmpty) {
                    setState(() {
                      onSignUpButtonClick = null;
                    });
                  } else {
                    setState(() {
                      onSignUpButtonClick = signUp;
                    });
                  }
                  return null;
                },
                controller: _phoneNumberController,
                autocorrect: false,
                autofocus: false,
                decoration: InputDecoration(
                  hintText: 'Phone Number',
                  hintStyle: TextStyle(
                    fontSize: 20,
                  ),
                  border: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                ),
                keyboardType: TextInputType.numberWithOptions(
                    signed: true, decimal: true),
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.black,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildBottom() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'By entering your number, you are agreeing to \nour Terms or Services and Privacy Policy',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 12,
                height: 1.5
            ),
            textAlign: TextAlign.center,
          ),
        ),
        SizedBox(
          height: 30,
        ),
        CustomButton(
          color: Colors.red,
          minimumWidth: 230,
          disabledColor: Style.AccentBlue.withOpacity(0.3),
          onPressed: onSignUpButtonClick,
          child: Container(
            width: 100,
            child: loading == true ? Center(
              child: CircularProgressIndicator(),
            ) : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Next',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                  ),
                ),
                Icon(
                  Icons.arrow_right_alt,
                  color: Colors.white,
                ),
              ],
            ),
          ),
        ),
      ],
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
      Get.offAll(OtpScreen(
        verificationId: this.verificationId,
      ));
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
    if (_phoneNumberController.text.isEmpty) {
      setState(() {
        error = "Enter Phone Number";
      });
    } else {
      setState(() {
        loading = true;
        error = "";
      });
      verifyPhone(countrycode+_phoneNumberController.text);
    }
  }
}
