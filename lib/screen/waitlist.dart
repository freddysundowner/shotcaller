import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shotcaller/screen/startcall_screen.dart';
import 'package:shotcaller/screen/waitlist_details.dart';
import 'package:shotcaller/shared/colors.dart';
import 'package:shotcaller/widgets/common_widgets.dart';

class Waitlist extends StatefulWidget {
  @override
  _WaitlistState createState() => _WaitlistState();
}

class _WaitlistState extends State<Waitlist> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeColor1,
      body: Container(
        child: SingleChildScrollView(
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: <Widget>[
                SizedBox(height: 30),
                Image.asset(
                  'assets/vv.png',
                  height: MediaQuery.of(context).size.height / 3,
                  fit: BoxFit.cover,
                ),
                SizedBox(
                  height: 40,
                ),
                logoWidget(),
                SizedBox(
                  height: 40,
                ),
                Center(
                  child: Text(
                    'Are you a broadcaster or podcaster? \nJoin our wait list to be notified when shortcaller is offered to creators',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(
                  height: 40,
                ),
                InkWell(
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => WaitlistDetails()));
                  },
                  child: Container(
                    width: MediaQuery.of(context).size.width / 1.2,
                    height: 55,
                    decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0xff5E67E0),
                            Color(0xff5E67E0),
                          ],
                        ),
                        borderRadius: BorderRadius.all(Radius.circular(50))),
                    child: Center(
                      child: Text(
                        'waitlist'.toUpperCase(),
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: 20,
                ),
                InkWell(
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => StartCall()));
                  },
                  child: Container(
                    width: 200,
                    height: 60,
                    decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0xff868181),
                            Color(0xff868181),
                          ],
                        ),
                        borderRadius: BorderRadius.all(
                          Radius.circular(50),
                        )),
                    child: Center(
                      child: Text(
                        'no thanks'.toUpperCase(),
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
