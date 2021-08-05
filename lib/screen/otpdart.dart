
import 'package:flutter/material.dart';
import 'package:shotcaller/screen/waitlist.dart';
import 'package:shotcaller/services/authenticate.dart';
import 'package:shotcaller/shared/colors.dart';
import 'package:shotcaller/shared/constants.dart';
import 'package:shotcaller/widgets/common_widgets.dart';
import '../shared/size_config.dart';
import 'otp_form.dart';
class OtpScreen extends StatefulWidget {
  final String verificationId;

  const OtpScreen({Key key, this.verificationId}) : super(key: key);
  static String routeName = "/OtpForm";

  @override
  _OtpScreenState createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {


  FocusNode pin1FocusNode;
  FocusNode pin2FocusNode;
  FocusNode pin3FocusNode;
  FocusNode pin4FocusNode;
  FocusNode pin5FocusNode;
  FocusNode pin6FocusNode;

  var code1 =TextEditingController();
  var code2 =TextEditingController();
  var code3 =TextEditingController();
  var code4 =TextEditingController();
  var code5 =TextEditingController();
  var code6 =TextEditingController();
  bool loading = false;

  @override
  void initState() {
    super.initState();
    pin1FocusNode = FocusNode();
    pin2FocusNode = FocusNode();
    pin3FocusNode = FocusNode();
    pin4FocusNode = FocusNode();
    pin5FocusNode = FocusNode();
    pin6FocusNode = FocusNode();
  }

  @override
  void dispose() {
    super.dispose();
    pin1FocusNode.dispose();
    pin2FocusNode.dispose();
    pin3FocusNode.dispose();
    pin4FocusNode.dispose();
    pin5FocusNode.dispose();
    pin6FocusNode.dispose();
  }

  void nextField(String value, FocusNode focusNode) {
    if (value.length == 1) {
      focusNode.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    return Scaffold(
      backgroundColor: ThemeColor1,
      body: SingleChildScrollView(
        child: Container(
          color: ThemeColor1,
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            children: [
              SizedBox(
                height: 40,
              ),
              // logoWidget(),
              SizedBox(
                height: 80,
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text("OTP Verification",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 21,
                            fontWeight: FontWeight.bold)),
                  ),
                  SizedBox(
                    height: 40,
                  ),
                  Center(
                    child: Text(
                      "We sent OTP  code to verify your number",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 30,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SizedBox(
                        width: getProportionateScreenWidth(50),
                        child: TextFormField(
                          autofocus: true,
                          style: TextStyle(fontSize: 20),
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          decoration: otpInputDecoration,
                          controller: code1,
                          onChanged: (value) {
                            nextField(value, pin2FocusNode);
                          },
                        ),
                      ),
                      SizedBox(
                        width: getProportionateScreenWidth(50),
                        child: TextFormField(
                          focusNode: pin2FocusNode,
                          style: TextStyle(fontSize: 20),
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          decoration: otpInputDecoration,
                          controller: code2,
                          onChanged: (value) => nextField(value, pin3FocusNode),
                        ),
                      ),
                      SizedBox(
                        width: getProportionateScreenWidth(50),
                        child: Container(
                          child: TextFormField(
                            focusNode: pin3FocusNode,
                            style: TextStyle(fontSize: 20),
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            decoration: otpInputDecoration,
                            controller: code3,
                            onChanged: (value) => nextField(value, pin4FocusNode),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: getProportionateScreenWidth(50),
                        child: TextFormField(
                          focusNode: pin4FocusNode,
                          style: TextStyle(fontSize: 20),
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          decoration: otpInputDecoration,
                          controller: code4,
                          onChanged: (value) => nextField(value, pin5FocusNode),
                        ),
                      ),
                      SizedBox(
                        width: getProportionateScreenWidth(50),
                        child: TextFormField(
                          focusNode: pin5FocusNode,
                          style: TextStyle(fontSize: 20),
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          decoration: otpInputDecoration,
                          controller: code5,
                          onChanged: (value) => nextField(value, pin6FocusNode),
                        ),
                      ),
                      SizedBox(
                        width: getProportionateScreenWidth(50),
                        child: TextFormField(
                          focusNode: pin6FocusNode,
                          style: TextStyle(fontSize: 20),
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          decoration: otpInputDecoration,
                          controller: code6,
                          onChanged: (value) {
                            if (value.length == 1) {
                              pin6FocusNode.unfocus();
                              // Then you need to check is the code is correct or not
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 30,
                  ),
                  Center(
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                          text: "Didn't receive OTP? ",
                          style: TextStyle(color: Colors.white, fontSize: 15),
                          children: [
                            TextSpan(
                                text: "RESEND",
                                style: TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16))
                          ]),
                    ),
                  ),
                  SizedBox(
                    height: 40,
                  ),
                  Padding(
                    padding: const EdgeInsets.all(40.0),
                    child: InkWell(
                      onTap: loading  == true ? null : () {
                        String otp = code1.text+code2.text+code3.text+code4.text+code5.text+code6.text;
                        setState(() {
                          loading = true;
                        });
                        if(otp.length == 6){
                          AuthService().signInWithOTP(
                              context, otp, widget.verificationId);
                        }

                        setState(() {
                          loading = false;
                        });
                      },
                      child: Container(
                        height: 55,
                        decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Color(0xffFF0000),
                                Color(0xffFF0000),
                              ],
                            ),
                            borderRadius: BorderRadius.all(Radius.circular(50))),
                        child: Center(
                          child: Text(
                            loading  == true ? "Please Wait.." :'verify & continue',
                            style: TextStyle(
                                color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 140,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}