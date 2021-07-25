import 'package:flutter/material.dart';
import 'package:shotcaller/shared/colors.dart';

class Admin extends StatefulWidget {
  @override
  _AdminState createState() => _AdminState();
}

class _AdminState extends State<Admin> {
  List<String> _list = ["limo", "limz", "wallace", "Jaylen", "I0ssaboy"];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: ThemeColor1,
        appBar: AppBar(
          title: ListTile(
            title: Text('powerer by',
                style: TextStyle(color: Colors.white, fontSize: 12)),
            subtitle: RichText(
              text: TextSpan(children: <TextSpan>[
                TextSpan(
                    text: "Shot",
                    style: TextStyle(
                        color: Color(0xffFFFFFF),
                        fontSize: 25,
                        fontWeight: FontWeight.bold)),
                TextSpan(
                    text: "Caller",
                    style: TextStyle(
                        color: Color(0xffB8B8B8),
                        fontSize: 25,
                        fontWeight: FontWeight.bold)),
              ]),
            ),
          ),
          leading: new IconButton(
            icon: new Icon(Icons.arrow_back_ios, color: Colors.grey),
            onPressed: () => Navigator.of(context).pop(),
          ),
          centerTitle: true,
          backgroundColor: ThemeColor1,
          elevation: 0,
        ),
        body: Container(
          margin: EdgeInsets.only(bottom: 20),
          child: Column(children: <Widget>[
            Expanded(
              child: SingleChildScrollView(
                child: Container(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              height: 30,
                            ),
                            Row(
                              children: <Widget>[
                                Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Container(
                                          width: 70,
                                          height: 30,
                                          decoration: BoxDecoration(
                                              border: Border.all(
                                                color: Colors
                                                    .white38, // red as border color
                                              ),
                                              gradient: LinearGradient(
                                                colors: [
                                                  Colors.green,
                                                  Colors.green,
                                                ],
                                              ),
                                              borderRadius: BorderRadius.all(
                                                Radius.circular(50),
                                              )),
                                          child: Row(
                                            children: [
                                              Column(
                                                children: [
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            left: 21.0),
                                                    child: Icon(
                                                      Icons.star,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        SizedBox(
                                          width: 10,
                                        ),
                                        Text(
                                          '4:00 Minutes',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                Spacer(),
                                Container(
                                  width: 70,
                                  height: 30,
                                  decoration: BoxDecoration(
                                      border: Border.all(
                                        color:
                                            Colors.white38, // red as border color
                                      ),
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.green,
                                          Colors.green,
                                        ],
                                      ),
                                      borderRadius: BorderRadius.all(
                                        Radius.circular(50),
                                      )),
                                  child: Center(
                                    child: Text(
                                      'Edit',
                                      style: TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(
                              height: 10,
                            ),
                            Container(
                              padding: EdgeInsets.only(bottom: 10),
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(30),
                                  color: Colors.black12),
                              child: Stack(
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceAround,
                                    children: [
                                      Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceAround,
                                        children: [
                                          SizedBox(
                                            height: 40,
                                          ),
                                          Container(
                                            decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(60),
                                                color: Colors.grey),
                                            child: Container(
                                                height: 20,
                                                width: 20,
                                                decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(30),
                                                    color: Colors.orange),
                                                child: Icon(
                                                  Icons.pause,
                                                  color: Colors.white,
                                                )),
                                            width: 40,
                                            height: 70,
                                          ),
                                          SizedBox(
                                            height: 10,
                                          ),
                                          Container(
                                            decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(60),
                                                color: Colors.grey),
                                            child: Container(
                                                height: 20,
                                                width: 20,
                                                decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(30),
                                                    color: Colors.red),
                                                child: Icon(
                                                  Icons.call_end,
                                                  color: Colors.white,
                                                )),
                                            width: 40,
                                            height: 70,
                                          )
                                        ],
                                      ),
                                      Column(
                                        children: [
                                          Stack(
                                            clipBehavior: Clip.none,
                                            children: [
                                              Container(
                                                margin: EdgeInsets.only(top: 15),
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(60),
                                                  color: Colors.black12,
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.grey
                                                          .withOpacity(0.5),
                                                      spreadRadius: 5,
                                                      blurRadius: 7,
                                                      offset: Offset(0,
                                                          3), // changes position of shadow
                                                    ),
                                                  ],
                                                ),
                                                child: Icon(
                                                  Icons.person,
                                                  size: 80,
                                                ),
                                              ),
                                              Positioned(
                                                  right: -15,
                                                  bottom: 0,
                                                  child: Icon(
                                                    Icons.star,
                                                    size: 35,
                                                  )),
                                            ],
                                          ),
                                          SizedBox(
                                            height: 15,
                                          ),
                                          Text(
                                            "Andrew",
                                            style: TextStyle(
                                                fontSize: 23,
                                                color: Colors.white),
                                          ),
                                          SizedBox(
                                            height: 15,
                                          ),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Column(
                                                children: [
                                                  Text(
                                                    '0.56',
                                                    style: TextStyle(
                                                      color: Colors.red,
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 35,
                                                    ),
                                                  ),
                                                  Text(
                                                    'Time used',
                                                    style: TextStyle(
                                                        color: Colors.red,
                                                        fontWeight:
                                                            FontWeight.bold),
                                                  ),
                                                ],
                                              ),
                                              SizedBox(
                                                width: 10,
                                              ),
                                              RotationTransition(
                                                  turns:
                                                      new AlwaysStoppedAnimation(
                                                          15 / 360),
                                                  child: Container(
                                                      height: 40,
                                                      margin:
                                                          const EdgeInsets.only(
                                                              bottom: 20.0),
                                                      child: VerticalDivider(
                                                          thickness: 4,
                                                          color: Colors.white))),
                                              SizedBox(
                                                width: 10,
                                              ),
                                              Column(
                                                children: [
                                                  Text(
                                                    '4:00',
                                                    style: TextStyle(
                                                        color: Colors.white,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 35),
                                                  ),
                                                  Text(
                                                    'Total time',
                                                    style: TextStyle(
                                                        color: Colors.white,
                                                        fontWeight:
                                                            FontWeight.bold),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceAround,
                                        children: [
                                          Container(
                                            decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(60),
                                                color: Colors.grey),
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.add_box,
                                                  color: Colors.white,
                                                ),
                                                Text(
                                                  "30 sec",
                                                  style: TextStyle(
                                                      fontSize: 8,
                                                      color: Colors.white),
                                                )
                                              ],
                                            ),
                                            width: 40,
                                            height: 70,
                                          ),
                                          SizedBox(
                                            height: 10,
                                          ),
                                          Container(
                                            decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(60),
                                                color: Colors.grey),
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.add_box,
                                                  color: Colors.white,
                                                ),
                                                Text(
                                                  "60 sec",
                                                  style: TextStyle(
                                                      fontSize: 8,
                                                      color: Colors.white),
                                                )
                                              ],
                                            ),
                                            width: 40,
                                            height: 70,
                                          )
                                        ],
                                      )
                                    ],
                                  ),
                                  // SizedBox(
                                  //   height: 20,
                                  // ),
                                  Positioned(
                                    child: Container(
                                      padding: EdgeInsets.only(
                                          left: 20,
                                          right: 15,
                                          bottom: 8,
                                          top: 10),
                                      decoration: BoxDecoration(
                                          borderRadius: BorderRadius.only(
                                            topLeft: Radius.circular(80),
                                            topRight: Radius.circular(30),
                                            bottomRight: Radius.circular(30),
                                          ),
                                          color: Colors.red),
                                      child: Text(
                                        "On Air",
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(
                              height: 20,
                            ),
                            Text(
                              'Callers in Queue',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20),
                            ),
                            SizedBox(
                              height: 20,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        height: 300,
                        child: ReorderableListView(
                          children: _list
                              .map((item) => ListTile(
                                    focusColor: Colors.transparent,
                                    selectedTileColor: Colors.transparent,
                                    hoverColor: Colors.transparent,
                                    tileColor: Colors.transparent,
                                    key: Key("${item}"),
                                    title: Container(
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: Colors
                                                .white38, // red as border color
                                          ),
                                          borderRadius: new BorderRadius.only(
                                            bottomRight:
                                                const Radius.circular(50.0),
                                            topRight: const Radius.circular(50.0),
                                            bottomLeft:
                                                const Radius.circular(5.0),
                                          ),
                                          color: Color(0xff5C5D62),
                                        ),
                                        padding: EdgeInsets.symmetric(
                                            vertical: 10, horizontal: 10),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.spaceBetween,
                                              children: [
                                                Container(
                                                    decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              20),
                                                    ),
                                                    child: Icon(
                                                      Icons.person,
                                                      size: 50,
                                                    )),
                                                SizedBox(
                                                  width: 30,
                                                ),
                                                Text("${item}"),
                                              ],
                                            ),
                                            Icon(
                                              Icons.star,
                                              size: 35,
                                            )
                                          ],
                                        )),
                                    // trailing: Icon(Icons.menu),
                                  ))
                              .toList(),
                          onReorder: (int start, int current) {
                            // dragging from top to bottom
                            if (start < current) {
                              int end = current - 1;
                              String startItem = _list[start];
                              int i = 0;
                              int local = start;
                              do {
                                _list[local] = _list[++local];
                                i++;
                              } while (i < end - start);
                              _list[end] = startItem;
                            }
                            // dragging from bottom to top
                            else if (start > current) {
                              String startItem = _list[start];
                              for (int i = start; i > current; i--) {
                                _list[i] = _list[i - 1];
                              }
                              _list[current] = startItem;
                            }
                            setState(() {});
                          },
                        ),
                      ),
                    ],
                  ),
                  color: Color(0xff4B494C), // Your screen background color
                ),
              ),
            ),
          ]),
        ),
        bottomNavigationBar: Container(
          margin: EdgeInsets.only(bottom: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 55,
                padding:
                EdgeInsets.only(top: 4, left: 16, right: 16, bottom: 4),
                decoration: BoxDecoration(
                  borderRadius: new BorderRadius.only(
                    bottomLeft: const Radius.circular(50.0),
                    topLeft: const Radius.circular(50.0),
                    bottomRight: const Radius.circular(5.0),
                  ),
                  color: Color(0xff5C5D62),
                ),
                child: Center(
                  child: Row(
                    children: [
                      Text(
                        'Hotline: ',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold),
                      ),
                      InkWell(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) {
                              return Dialog(
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                    BorderRadius.circular(20)),
                                elevation: 16,
                                child: Container(
                                  width: 150,
                                  child: ListView(
                                    shrinkWrap: true,
                                    children: <Widget>[
                                      SizedBox(height: 20),
                                      Center(child: Text('Open hotline', style: TextStyle(fontSize: 21),)),
                                      SizedBox(height: 20),
                                      Container(
                                        padding: EdgeInsets.symmetric(horizontal: 20,vertical: 10),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                          children: [
                                            Icon(Icons.check_circle, color: Colors.green, size: 30,),
                                            Icon(Icons.cancel, color: Colors.red, size: 30,),
                                          ],
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                        child: Text(
                          'Open',
                          style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(
                height: 10,
              ),
              Row(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(left: 30.0),
                    child: Column(
                      children: [
                        InkWell(
                          onTap: () {

                          },
                          child: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.white,
                                    Colors.white,
                                  ],
                                ),
                                borderRadius: BorderRadius.all(
                                  Radius.circular(50),
                                )),
                            child: Center(
                                child: Icon(
                                  Icons.play_arrow,
                                  color: Colors.green,
                                )),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Spacer(),
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white,
                            Colors.white,
                          ],
                        ),
                        borderRadius: BorderRadius.all(
                          Radius.circular(50),
                        )),
                    child: Center(child: Icon(Icons.pause)),
                  ),
                  Spacer(),
                  Container(
                    margin: const EdgeInsets.only(right: 20.0),
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white,
                            Colors.white,
                          ],
                        ),
                        borderRadius: BorderRadius.all(
                          Radius.circular(50),
                        )),
                    child: Center(child: Icon(Icons.pause)),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
