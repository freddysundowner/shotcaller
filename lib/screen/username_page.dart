import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shotcaller/controllers/controllers.dart';
import 'package:shotcaller/screen/pick_photo_page.dart';
import 'package:shotcaller/shared/colors.dart';
import 'package:shotcaller/widgets/common_widgets.dart';
import 'package:shotcaller/widgets/round_button.dart';

class UsernamePage extends StatefulWidget {
  @override
  _UsernamePageState createState() => _UsernamePageState();
}

class _UsernamePageState extends State<UsernamePage> {
  final _userNameController = TextEditingController();
  final _userNameformKey = GlobalKey<FormState>();
  Function onNextButtonClick;
  bool loading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeColor1,
      body: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.only(
          top: 30,
          bottom: 60,
        ),
        child: Column(
          children: [
            logoWidget(),
            SizedBox(
              height: 50,
            ),
            buildTitle(),
            SizedBox(
              height: 50,
            ),
            buildForm(),
            Spacer(),
            buildBottom(),
          ],
        ),
      ),
    );
  }

  Widget buildTitle() {
    return Text(
      'Pick a username',
      style: TextStyle(
        fontSize: 20,
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
      child: Form(
        key: _userNameformKey,
        child: TextFormField(
          textAlign: TextAlign.center,
          onChanged: (value) {
            _userNameformKey.currentState.validate();
          },
          validator: (value) {
            if (value.isEmpty) {
              setState(() {
                onNextButtonClick = null;
              });
            } else {
              setState(() {
                onNextButtonClick = next;
              });
            }
            return null;
          },
          controller: _userNameController,
          autocorrect: false,
          autofocus: false,
          decoration: InputDecoration(
            hintText: 'username',
            hintStyle: TextStyle(
              fontSize: 20,
            ),
            border: InputBorder.none,
            focusedBorder: InputBorder.none,
            enabledBorder: InputBorder.none,
            errorBorder: InputBorder.none,
            disabledBorder: InputBorder.none,
          ),
          keyboardType: TextInputType.text,
          style: TextStyle(
            fontSize: 20,
            color: Colors.black,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
    );
  }

  Widget buildBottom() {
    return CustomButton(
      color: Colors.red,
      minimumWidth: 230,
      disabledColor: Colors.grey.withOpacity(0.3),
      onPressed: onNextButtonClick,
      child: Container(
        child: Row(
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
    );
  }

  next() {
    Get.find<OnboardingController>().username = _userNameController.text;
    Get.to(()=> PickPhotoPage());
  }
}