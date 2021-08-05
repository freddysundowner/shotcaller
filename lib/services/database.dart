import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get/get.dart';
import 'package:http/io_client.dart';
import 'package:shotcaller/controllers/controllers.dart';
import 'package:shotcaller/models/user_model.dart';
import 'package:shotcaller/screen/startcall_screen.dart';
import 'package:shotcaller/shared/configs.dart';
import 'package:shotcaller/utils/firebase_refs.dart';
import 'package:path/path.dart';

class Database {
  //get profile user data
  Future<UserModel> getUserProfile(String id) async {
    return await usersRef.doc(id).get().then((value) {
      if (value.exists) {

        UserModel user = UserModel.fromJson(value.data());
        Get.find<UserController>().user = user;
        return user;
      }
      return null;
    });
  }

  //upload image to firebase store and then returns image url
  uploadImage(String id, {bool update = false}) async {
    UserModel user = Get.find<OnboardingController>().onboardingUser;
    if (user.imagefile != null) {
      String fileName = basename(user.imagefile.path);
      Reference firebaseSt =
          FirebaseStorage.instance.ref().child('profile/$fileName');
      UploadTask uploadTask = firebaseSt.putFile(user.imagefile);

      await uploadTask.whenComplete(() async {
        String storagePath = await firebaseSt.getDownloadURL();
        user.imageurl = storagePath;
      });

      if (update == true) {
        Reference storageReferance = FirebaseStorage.instance.ref();
        storageReferance
            .child(Get.find<UserController>().user.imageurl)
            .delete()
            .then((_) => print(
                'Successfully deleted ${Get.find<UserController>().user.imageurl} storage item'));
      }
    }
  }

  //create user profile with the extra data and save them in firestore
  Future createUserInfo(String uid) async {
    UserModel user = Get.find<OnboardingController>().onboardingUser;
    await uploadImage(uid);
    var data = {
      "username": user.username,
      "uid": uid,
      "stared": false,
      "firebasetoken": await FirebaseMessaging.instance.getToken(),
      "usertype": user.usertype,
      "imageurl": user.imageurl,
      "phonenumber": user.phonenumber,
      "countrycode": user.countrycode,
      "countryname": user.countryname,
      "lastAccessTime": DateTime.now().microsecondsSinceEpoch,
    };
    await usersRef.doc(uid).set(data);
    UserModel userModel = await Database().getUserProfile(FirebaseAuth.instance.currentUser.uid);
    if(userModel != null){
      Get.to(() => StartCall());
    }
  }

  //update profile data

  updateProfileData(String userid, data) {
    usersRef.doc(userid).update(data);
  }

  //the script to generate this is a nodejs script
  Future<String> getCallToken(String channel, String uid) async {
    try {
      final ioc = new HttpClient();
      ioc.badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
      final http = new IOClient(ioc);
      var url = Uri.parse(
          '${tokenpath}/generaltokenkoodle?channel=$channel&uid=$uid');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        print(jsonDecode(response.body));
        return jsonDecode(response.body)["token"];
      } else {
        throw Exception('Failed to load token');
      }
    } catch (e) {
      print(e.toString());
    }
  }

  Future<QueryDocumentSnapshot> getSettings() async {
    return settingsRef.get().then((value){
      return value.docs[0];
    });
  }

}
