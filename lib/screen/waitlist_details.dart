import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shotcaller/screen/startcall_screen.dart';
import 'package:shotcaller/shared/colors.dart';
import 'package:shotcaller/widgets/common_widgets.dart';

class WaitlistDetails extends StatefulWidget {
  @override
  _WaitlistDetailsState createState() => _WaitlistDetailsState();
}

class _WaitlistDetailsState extends State<WaitlistDetails> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeColor1,
      body: Container(
        padding: EdgeInsets.symmetric(horizontal: 20,vertical: 30),
        child: Column(
          children: <Widget>[
            logoWidget(),
            SizedBox(
              height: 50,
            ),
            Container(
              width: MediaQuery.of(context).size.width / 1.2,
              height: 55,
              padding:
                  EdgeInsets.only(top: 4, left: 16, right: 16, bottom: 4),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(50)),
                  color: Color(0xff3D3D3D),
              ),
              child: TextField(
                decoration: InputDecoration(
                  icon: Icon(Icons.person, color: Colors.white),
                  fillColor: Color(0xff3D3D3D),
                  border: InputBorder.none,
                  hintText: 'Name',
                  hintStyle: TextStyle(fontSize: 13.0, color: Colors.white),
                ),
              ),
            ),
            SizedBox(
              height: 20,
            ),
            Container(
              width: MediaQuery.of(context).size.width / 1.2,
              height: 55,
              padding:
                  EdgeInsets.only(top: 4, left: 16, right: 16, bottom: 4),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(50)),
                  color:Color(0xff3D3D3D),
                ),
              child: TextField(
                decoration: InputDecoration(
                  icon: Icon(
                    Icons.call,
                    color: Colors.white,
                  ),
                  fillColor: Colors.grey[900],
                  border: InputBorder.none,
                  hintText: 'Phone Number',
                  hintStyle:TextStyle(fontSize: 13.0, color: Colors.white),
                ),
              ),
            ),
            SizedBox(
              height: 20,
            ),
            Container(
              width: MediaQuery.of(context).size.width / 1.2,
              height: 55,
              padding:
                  EdgeInsets.only(top: 4, left: 16, right: 16, bottom: 4),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(50)),
                  color: Color(0xff3D3D3D),
              ),
              child: TextField(
                decoration: InputDecoration(
                  icon: Icon(Icons.email, color: Colors.white),
                  fillColor: Color(0xff3D3D3D),
                  border: InputBorder.none,
                  hintText: 'Email',
                  hintStyle:TextStyle(fontSize: 13.0, color: Colors.white),
                ),
              ),
            ),

          ],
        ),
      ),
      bottomNavigationBar:  Container(
        margin: EdgeInsets.only(bottom: 40,left: 20,right: 20),
        child: InkWell(
          onTap: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => StartCall()));
          },
          child: Container(
            width: MediaQuery.of(context).size.width / 1.2,
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
                'Submit',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
