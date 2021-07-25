
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shotcaller/bindings.dart';
import 'package:shotcaller/services/authenticate.dart';



void main() async {

  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ShortCaller',
      theme: ThemeData(
        fontFamily: "InterMedium",
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),

      initialBinding: AuthBinding(),
      home: AuthService().handleAuth()
    );
  }
}
