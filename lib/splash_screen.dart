import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shotcaller/screen/phone_number.dart';
import 'package:video_player/video_player.dart';

import 'controllers/controllers.dart';
import 'screen/admin_screen.dart';
import 'screen/startcall_screen.dart';
import 'screen/username_page.dart';
import 'services/authenticate.dart';
import 'services/database.dart';

class SplashScreen extends StatefulWidget {

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
   VideoPlayerController _controller;
   Future<void> _initializeVideoPlayerFuture;

   @override
   void initState() {
     _controller = VideoPlayerController.asset(
       'assets/videos/vv.mp4',
     );

     _initializeVideoPlayerFuture = _controller.initialize();
     _controller.addListener(checkVideo);

     super.initState();
   }

   @override
   void dispose() {
     // Ensure disposing of the VideoPlayerController to free up resources.
     _controller.dispose();

     super.dispose();
   }
   void checkVideo(){
     // Implement your calls inside these conditions' bodies :
     if(_controller.value.position == Duration(seconds: 0, minutes: 0, hours: 0)) {
       print('video Started');
     }

     if(_controller.value.position == _controller.value.duration) {
       print('video Ended');
       if(FirebaseAuth.instance.currentUser == null){
         Get.to(() => PhoneNumber());
       }else {
         Database().getUserProfile(FirebaseAuth.instance.currentUser.uid).then((
             value) {
           if (value != null) {
             Get
                 .put(UserController())
                 .user = value;
             print(Get
                 .put(UserController())
                 .user
                 .usertype);
             if (Get
                 .put(UserController())
                 .user
                 .usertype == "admin") {
               Get.to(() => Admin());
             } else {
               Get.to(() => StartCall());
             }
           } else {
             Get.to(() => UsernamePage());
           }
         });
       }
     }

   }
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initializeVideoPlayerFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          _controller.play();

          // If the VideoPlayerController has finished initialization, use
          // the data it provides to limit the aspect ratio of the video.
          return Container(
            color: Colors.black,
            child: AspectRatio(
              aspectRatio: _controller.value.size.width,
              // Use the VideoPlayer widget to display the video.
              child: VideoPlayer(_controller),
            ),
          );
        } else {
          // If the VideoPlayerController is still initializing, show a
          // loading spinner.
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
      },
    );
  }
}
