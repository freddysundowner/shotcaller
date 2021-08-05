import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shotcaller/screen/phone_number.dart';

logoWidget({double sz1= 30, double sz2 = 12, String from = ""}){
  return Container(
    margin: EdgeInsets.only(left: 30,  top: 20, right: 10),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          child: Image.asset("assets/images/logoshotcaller.png", width: sz1,),
        ),
        if(from =="home") InkWell(
              onTap: (){
                Get.defaultDialog(
                    middleText: "Are you sure you want to logout?",
                    backgroundColor: Colors.green,
                    titleStyle: TextStyle(color: Colors.white),
                    middleTextStyle: TextStyle(color: Colors.white),
                    onConfirm: (){
                      FirebaseAuth.instance.signOut();
                      Get.to(() => PhoneNumber());
                    },
                    onCancel: (){
                      Get.back();
                    },
                  textConfirm: "Yes",
                  textCancel: "No",
                  confirmTextColor: Colors.white,
                  buttonColor: Colors.red

                );

              },
                child: Icon(Icons.logout, color: Colors.white,))
      ],
    ),
  );
  // return Container(
  //   margin: EdgeInsets.only(left: 30,  top: 20),
  //   child: ListTile(
  //     subtitle: Row(
  //       mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //       children: [
  //         Column(
  //           mainAxisAlignment: MainAxisAlignment.start,
  //           crossAxisAlignment: CrossAxisAlignment.start,
  //           children: [
  //             Text('powerer by',
  //                 style: TextStyle(color: Colors.white, fontSize: sz2)),
  //             RichText(
  //               text: TextSpan(children: <TextSpan>[
  //                 TextSpan(
  //                     text: "Shot",
  //                     style: TextStyle(
  //                         color: Color(0xffFFFFFF),
  //                         fontSize: sz1,
  //                         fontWeight: FontWeight.bold)),
  //                 TextSpan(
  //                     text: "Caller",
  //                     style: TextStyle(
  //                         color: Color(0xffB8B8B8),
  //                         fontSize: sz1,
  //                         fontWeight: FontWeight.bold)),
  //               ]),
  //             )
  //           ],
  //         ),
  //          if(from =="home") InkWell(
  //           onTap: (){
  //             Get.defaultDialog(
  //                 middleText: "Are you sure you want to logout?",
  //                 backgroundColor: Colors.green,
  //                 titleStyle: TextStyle(color: Colors.white),
  //                 middleTextStyle: TextStyle(color: Colors.white),
  //                 onConfirm: (){
  //                   FirebaseAuth.instance.signOut();
  //                   Get.to(() => PhoneNumber());
  //                 },
  //                 onCancel: (){
  //                   Get.back();
  //                 },
  //               textConfirm: "Yes",
  //               textCancel: "No",
  //               confirmTextColor: Colors.white,
  //               buttonColor: Colors.red
  //
  //             );
  //
  //           },
  //             child: Icon(Icons.logout, color: Colors.white,))
  //       ],
  //     ),
  //   ),
  // );
}