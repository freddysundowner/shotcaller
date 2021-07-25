import 'package:flutter/material.dart';
import '../shared/constants.dart';
import '../shared/size_config.dart';

class OtpForm extends StatefulWidget {
  const OtpForm({
    Key key,
  }) : super(key: key);

  @override
  _OtpFormState createState() => _OtpFormState();
}

class _OtpFormState extends State<OtpForm> {
  FocusNode pin2FocusNode;
  FocusNode pin3FocusNode;
  FocusNode pin4FocusNode;
  FocusNode pin5FocusNode;
  FocusNode pin6FocusNode;

  @override
  void initState() {
    super.initState();
    pin2FocusNode = FocusNode();
    pin3FocusNode = FocusNode();
    pin4FocusNode = FocusNode();
    pin5FocusNode = FocusNode();
    pin6FocusNode = FocusNode();
  }

  @override
  void dispose() {
    super.dispose();
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
    return Row(
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
            onChanged: (value) => nextField(value, pin4FocusNode),
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
            onChanged: (value) {
              if (value.length == 1) {
                pin6FocusNode.unfocus();
                // Then you need to check is the code is correct or not
              }
            },
          ),
        ),
      ],
    );
  }
} // TODO Implement this library.
