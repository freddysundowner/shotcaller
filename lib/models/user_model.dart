import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
   String username;
   String uid;
   String imageurl;
   String firebasetoken;
   String usertype;
   String phonenumber;
   bool stared;
   bool blocked;
   File imagefile;
   String countrycode;
   String countryname;

  UserModel({
    this.uid,
    this.firebasetoken,
    this.countryname,
    this.countrycode,
    this.usertype,
    this.blocked,
    this.stared,
    this.username,
    this.phonenumber,
    this.imageurl,
    this.imagefile,
  });


   Map<String, dynamic>  toMap({bool stared = false}) {
       return {
         "firebasetoken": firebasetoken,
         "imageurl": imageurl,
         "blocked": blocked,
         "uid": uid,
         "stared": this.stared == true ? this.stared : stared ,
         "usertype": usertype,
         "username": username,
         "countrycode": countrycode,
         "countryname": countryname,
         "phonenumber": phonenumber,
       };
   }

  factory UserModel.fromJson(json) {
    return UserModel(
      imageurl: json['imageurl'],
      firebasetoken: json['firebasetoken'],
      stared: json['stared'],
      blocked: json['blocked'],
      username: json['username'],
      countryname: json['countryname'],
      countrycode: json['countrycode'],
      uid: json['uid'],
      usertype: json['usertype'],
      phonenumber: json['phonenumber'],
    );
  }
}
