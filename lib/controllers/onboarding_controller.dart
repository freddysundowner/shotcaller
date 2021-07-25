import 'dart:io';

import 'package:get/get.dart';
import 'package:shotcaller/models/user_model.dart';

class OnboardingController extends GetxController{
  Rx<UserModel> _user = UserModel().obs;
  UserModel get onboardingUser => _user.value;
  set onboardata(UserModel value) => this._user.value = value;
  RxBool loading = false.obs;

  set imageurl(String value) => this._user.value.imageurl = value;
  set imageFile(File value) => this._user.value.imagefile = value;
  set username(String value) => this._user.value.username = value;
  set phonenumber(String value) => this._user.value.phonenumber = value;
}