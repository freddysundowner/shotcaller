import 'dart:async';
import 'dart:io';

import 'package:agora_rtc_engine/rtc_engine.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:get/get.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shotcaller/controllers/controllers.dart';
import 'package:shotcaller/models/room.dart';
import 'package:shotcaller/models/user_model.dart';
import 'package:shotcaller/services/database.dart';
import 'package:shotcaller/shared/colors.dart';
import 'package:shotcaller/shared/configs.dart';
import 'package:shotcaller/utils/firebase_refs.dart';
import 'package:shotcaller/utils/utils.dart';
import 'package:shotcaller/widgets/common_widgets.dart';
import 'package:shotcaller/Notifications/push_nofitications.dart';

class Admin extends StatefulWidget {
  @override
  _AdminState createState() => _AdminState();
}

class _AdminState extends State<Admin> {
  StreamSubscription<QuerySnapshot> calllistener;
  UserModel user = Get.find<UserController>().user;

  RtcEngine engine;
  List<Room> rooms = [];
  Room activeroom;
  String activecallusername = "No Active Call";
  bool loading = true;
  bool mute = false;
  UserModel cuser;
  var calllimitcontroller = TextEditingController();

  var linknamecontroller = TextEditingController();
  var linkcontroller = TextEditingController();
  bool timeextended = false;
  bool hotline = true;
  int currentSeconds = 0;
  Timer timer;
  String settingsid = "", callslimit= "";

  int extendedtime = 0;

  String showlink = "";
  String showlinkname = "";
  String txt = "";

  StreamSubscription<DocumentSnapshot> listen;

  String get timerText => '${((currentSeconds) ~/ 60).toString().padLeft(2, '0')}: ${((currentSeconds) % 60).toString().padLeft(2, '0')}';

  @override
  void initState() {
    super.initState();
    initialize();
    settingsRef.snapshots().listen((event) {
      settingsid = event.docs[0].id;
      hotline = event.docs[0].data()["hotlineoffline"];
      var tim = event.docs[0].data()["callslimit"];
      callslimit = '${((tim) ~/ 60).toString().padLeft(2, '0')}: ${((tim) % 60).toString().padLeft(2, '0')}';
      showlink = event.docs[0].data()["showlink"];
      showlinkname = event.docs[0].data()["showlinkname"];
      linknamecontroller.text = showlinkname;
      linkcontroller.text = showlink;
      setState(() {});
    });
  }

  @override
  void dispose() {
    listen.cancel();
    super.dispose();
  }

  toggleAudio() {
    mute = !mute;
    engine.muteLocalAudioStream(mute);
    roomsRef.doc(activeroom.roomid).update({"muted": mute});
    setState(() {});
  }

  static AudioCache player = new AudioCache();

  void addedTimeNofier() {
    const alarmAudioPath = "sounds/seconds_addedc.mp3";
    player.play(alarmAudioPath);
    var snackBar = SnackBar(
      content: Text("New Caller in Queue"),
      backgroundColor: Colors.green,
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  final picker = ImagePicker();
  File _imageFile;
  Future<void> _showMyDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: true, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          scrollable: false,
          title: const Text('Add a profile photo'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 10,),
              InkWell(
                onTap: (){
                  Navigator.pop(context);
                  _getFromGallery();
                },
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Text("Choose from galley"),
                ),
              ),
              SizedBox(height: 20,),
              InkWell(
                onTap: (){
                  Navigator.pop(context);
                  _getFromCamera();
                },
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Text("Take photo"),
                ),
              )
            ],
          ),
        );
      },
    );
  }
  _getFromGallery() async {
    PickedFile pickedFile = await picker.getImage(
        source: ImageSource.gallery,
        maxWidth: 80
    );
    _cropImage(pickedFile.path);
  }
  _getFromCamera() async {
    PickedFile pickedFile = await picker.getImage(
        source: ImageSource.camera,
        maxWidth: 80
    );
    _cropImage(pickedFile.path);
  }

  _cropImage(filePath) async {
    File croppedImage = await ImageCropper.cropImage(
        sourcePath: filePath,
        aspectRatio: CropAspectRatio(ratioX: 1, ratioY: 1),
        aspectRatioPresets: [CropAspectRatioPreset.square],
        compressQuality: 70,
        compressFormat: ImageCompressFormat.jpg,
        iosUiSettings: IOSUiSettings(
          minimumAspectRatio: 1.0,
          rotateClockwiseButtonHidden: false,
          rotateButtonsHidden: false,
        )
    );
    if (croppedImage != null) {
      _imageFile = croppedImage;
      Get.find<OnboardingController>().imageFile = _imageFile;
      Database().uploadImage(user.uid, update: true);
      setState(() {});
    }
  }
  callInit() async {
    calllistener = await roomsRef.snapshots().listen((event) {
      if (event.docs.length > rooms.length && activeroom ==null) {
        addedTimeNofier();
      }
      rooms.clear();
      if (event.docs.length > 0) {
        event.docs.forEach((element) async {
          Room room = Room.fromJson(element);
          if (room.status == "waiting") {
            rooms.add(room);
          }
          if (room.status == "active") {
            activeroom = room;
            await engine.setDefaultAudioRoutetoSpeakerphone(activeroom.adminenabledspeaker);
            cuser = activeroom.users[activeroom.users
                .indexWhere((element) => element.uid != user.uid)];
          }
        });

        setState(() {
          loading = false;
        });
        // initiatecall();
      } else {
        activeroom = null;
        setState(() {
          loading = false;
        });
      }
    });
  }

  receiveCall() async {
    if (activeroom == null) {
      if (rooms.length > 0) {
        activeroom = rooms.first;
        // timerMaxSeconds = activeroom.time;
        cuser = activeroom.users[
            activeroom.users.indexWhere((element) => element.uid != user.uid)];
        await engine.joinChannel(rooms.first.token, rooms.first.owner, null, 0);
        roomsRef
            .doc(activeroom.roomid)
            .update({"currentstatus": "ongoing", "status": "active"});
        print("b");
      } else {
        activecallusername = "No Active Call";
      }

      setState(() {
        loading = false;
      });
    }
  }

  rejectCall(Room room) {
    roomsRef.doc(room.roomid).delete();
  }

  Future<void> leaveChannel() async {
    await engine.leaveChannel();
    roomsRef.doc(activeroom.roomid).delete();
    cuser = null;
    setState(() {
      activeroom = null;
      // timerMaxSeconds = 0;
    });
  }

  /// Create Agora SDK instance and initialize
  Future<void> initialize() async {
    await _initAgoraRtcEngine();
    _addAgoraEventHandlers();
    callInit();


  }

  //init agora sdk
  Future<void> _initAgoraRtcEngine() async {
    try {
      engine = await RtcEngine.create(APP_ID);
      await Permission.microphone.request();
      await engine.enableAudio();
      await engine.setChannelProfile(ChannelProfile.LiveBroadcasting);
      await engine.enableAudioVolumeIndication(500, 3, true);
      engine.renewToken("token");
      await engine.setClientRole(ClientRole.Broadcaster);
    } catch (e) {
      print("error general " + e.toString());
    }
  }

  /// Add Agora event handlers
  void _addAgoraEventHandlers() {
    engine.setEventHandler(RtcEngineEventHandler(
        error: (code) async {
          setState(() {
            print('onError: $code');
          });
        },
        joinChannelSuccess: (channel, uid, elapsed) async {
          print('onJoinChannel: $channel, uid: $uid');
          await roomsRef.doc(activeroom.roomid).update({"status": "active"});
          rooms.remove(rooms.first);
          setState(() {});
        },
        leaveChannel: (stats) {
          print("leaving one");
          setState(() {

          });
        },
        userOffline: (uid, elapsed) {
          final info = 'userOffline: $uid';
          print(info);
        },
        audioRouteChanged: (AudioOutputRouting audioOutputRouting) {
          print("audioOutputRouting " + audioOutputRouting.index.toString());
        },
        userJoined: (uid, elapsed) {
          print('userJoined: $uid');
        },
        audioVolumeIndication:
            (List<AudioVolumeInfo> speakers, int totalVolume) {},
        remoteAudioStats: (RemoteAudioStats remoteAudioStats) {},
        rtcStats: (RtcStats rtcStats) {
          setState(() {
            currentSeconds = rtcStats.totalDuration;
          });

          if(activeroom != null && (activeroom.time - rtcStats.totalDuration) <=10){
            const alarmAudioPath = "sounds/economics.mp3";
            player.play(alarmAudioPath);
          }


          if (activeroom != null && currentSeconds >= activeroom.time) {
            print("leaving four");
            leaveChannel();
          }
        }));
  }
  _showDialog() async {
    await showDialog<String>(
      context: context,
      builder: (ct){
        return StatefulBuilder(
          builder: (context, setState) {
            return new AlertDialog(
              contentPadding: const EdgeInsets.all(16.0),
              content: new Row(
                children: <Widget>[
                  new Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        new TextField(
                          autofocus: true,
                          controller: calllimitcontroller,
                          keyboardType: TextInputType.number,
                          decoration: new InputDecoration(
                              labelText: 'Call Time Limit (seconds)', hintText: 'eg. 240'),
                        ),
                        if(txt.isNotEmpty) Text(txt, style: TextStyle(color: Colors.red),)
                      ],
                    ),
                  )
                ],
              ),
              actions: <Widget>[
                new FlatButton(
                    child: const Text('CANCEL'),
                    onPressed: () {
                      Navigator.pop(context);
                    }),
                new FlatButton(
                    child: const Text('SAVE'),
                    onPressed: () {
                      txt = "";
                      if(calllimitcontroller.text.isEmpty){
                        txt = "enter amount of seconds first";
                        setState(() {

                        });
                      }else{
                        Navigator.pop(context);
                        settingsRef.doc(settingsid).update({
                          "callslimit" : int.parse(calllimitcontroller.text)
                        });
                        calllimitcontroller.text = "";
                      }

                    })
              ],
            );
          }
        );
      },
    );
  }
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: ThemeColor1,
        body: loading == true
            ? Center(
                child: Container(
                  child: CircularProgressIndicator(),
                ),
              )
            : Column(
                children: [
                  SizedBox(
                    height: 10,
                  ),
                  Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: Center(
                          child: logoWidget(sz1: 200, sz2: 12, from: "home"),
                        ),
                      ),
                    ],
                  ),
                  Expanded(
                    flex: 1,
                    child: Container(
                      margin: EdgeInsets.only(bottom: 20),
                      child: Column(children: <Widget>[
                        Expanded(
                          child: SingleChildScrollView(
                            child: Container(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 20),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        SizedBox(
                                          height: 30,
                                        ),
                                        Row(
                                          children: <Widget>[
                                            Expanded(
                                              child: Center(
                                                child: Text(
                                                  '$callslimit Minutes',
                                                  style: TextStyle(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.bold),
                                                ),
                                              ),
                                            ),
                                            InkWell(
                                              onTap: (){
                                                _showDialog();
                                              },
                                              child: Container(
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
                                                    borderRadius:
                                                        BorderRadius.all(
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
                                            ),
                                          ],
                                        ),
                                        SizedBox(
                                          height: 10,
                                        ),
                                        Container(
                                          padding: EdgeInsets.only(bottom: 10),
                                          decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(30),
                                              color: Colors.black12),
                                          child: Stack(
                                            children: [
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceAround,
                                                children: [
                                                  Column(
                                                    children: [
                                                      Container(
                                                        margin: EdgeInsets.only(
                                                            top: 15),
                                                        decoration:
                                                            BoxDecoration(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(60),
                                                          color: Colors.black12,
                                                          boxShadow: [
                                                            BoxShadow(
                                                              color: Colors.grey
                                                                  .withOpacity(
                                                                      0.5),
                                                              spreadRadius: 5,
                                                              blurRadius: 7,
                                                              offset: Offset(0,
                                                                  3), // changes position of shadow
                                                            ),
                                                          ],
                                                        ),
                                                        child:
                                                            activeroom != null && cuser !=null
                                                                ? ClipRRect(
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                            60.0),
                                                                    child:
                                                                        CachedNetworkImage(
                                                                      width: 75,
                                                                      imageUrl:
                                                                          cuser
                                                                              .imageurl,
                                                                    ),
                                                                  )
                                                                : Icon(
                                                                    Icons
                                                                        .person,
                                                                    size: 70,
                                                                  ),
                                                      ),
                                                      SizedBox(
                                                        height: 15,
                                                      ),
                                                      Text(
                                                        activeroom == null
                                                            ? activecallusername
                                                            : activeroom.title,
                                                        style: TextStyle(
                                                            fontSize: 23,
                                                            color:
                                                                Colors.white),
                                                      ),
                                                      SizedBox(
                                                        height: 15,
                                                      ),
                                                      callTimerView(),
                                                      SizedBox(
                                                        height: 20,
                                                      ),
                                                      iconActions(),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                              Positioned(
                                                child: Container(
                                                  padding: EdgeInsets.only(
                                                      left: 20,
                                                      right: 15,
                                                      bottom: 8,
                                                      top: 10),
                                                  decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.only(
                                                        topLeft:
                                                            Radius.circular(80),
                                                        topRight:
                                                            Radius.circular(30),
                                                        bottomRight:
                                                            Radius.circular(30),
                                                      ),
                                                      color: hotline == true ? Colors.grey : Colors.red),
                                                  child: Text(
                                                    hotline == true
                                                        ? "Off Air"
                                                        : "On Air",
                                                    style: TextStyle(
                                                        color: Colors.white),
                                                  ),
                                                ),
                                              ),
                                              Positioned(
                                                right: 10,
                                                child: Row(
                                                  children: [
                                                    Container(
                                                      child: IconButton(
                                                        icon: Icon(Icons.info),
                                                        onPressed: (){

                                                          showDialog(
                                                            context: context,
                                                            barrierDismissible: true, // user must tap button!
                                                            builder: (BuildContext context) {
                                                              return AlertDialog(
                                                                content: Column(
                                                                  mainAxisSize: MainAxisSize.min,
                                                                  children: [
                                                                    Container(
                                                                      decoration: BoxDecoration(
                                                                        color: Colors.white,
                                                                        border: Border.all(
                                                                            color: Colors.red,// set border color
                                                                            width: 1.0),   // set border width
                                                                        borderRadius: BorderRadius.all(
                                                                            Radius.circular(6.0)), // set rounded corner radius
                                                                      ),
                                                                      padding: EdgeInsets.only(left: 10),
                                                                      child: TextFormField(
                                                                        textAlign: TextAlign.start,
                                                                        controller: linknamecontroller,
                                                                        autocorrect: false,
                                                                        autofocus: false,
                                                                        decoration: InputDecoration(
                                                                          hintText: 'Name of the show',
                                                                          hintStyle: TextStyle(
                                                                            fontSize: 14,
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
                                                                    SizedBox(height: 10,),
                                                                    Container(
                                                                      decoration: BoxDecoration(
                                                                        color: Colors.white,
                                                                        border: Border.all(
                                                                            color: Colors.red,// set border color
                                                                            width: 1.0),   // set border width
                                                                        borderRadius: BorderRadius.all(
                                                                            Radius.circular(6.0)), // set rounded corner radius
                                                                      ),
                                                                      padding: EdgeInsets.only(left: 10),
                                                                      child: TextFormField(
                                                                        textAlign: TextAlign.start,
                                                                        controller: linkcontroller,
                                                                        autocorrect: false,
                                                                        autofocus: false,
                                                                        decoration: InputDecoration(
                                                                          hintText: 'Link to the show',
                                                                          hintStyle: TextStyle(
                                                                            fontSize: 14,
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
                                                                    SizedBox(height: 30,),
                                                                    Row(
                                                                      crossAxisAlignment: CrossAxisAlignment.end,
                                                                      mainAxisAlignment: MainAxisAlignment.end,
                                                                      children: [
                                                                        InkWell(
                                                                          child: Container(
                                                                            padding: EdgeInsets.symmetric(vertical: 5, horizontal: 20),
                                                                            child: Text('Update', style: TextStyle(color: Colors.white),),
                                                                            decoration: BoxDecoration(
                                                                                color: Color(0XFF5761E3),
                                                                                borderRadius: BorderRadius.circular(10)
                                                                            ),
                                                                          ),
                                                                          onTap: () async {
                                                                            Navigator.pop(context);
                                                                            settingsRef.doc(settingsid).update({
                                                                              "showlink": linkcontroller.text,
                                                                              "showlinkname": linknamecontroller.text
                                                                            });
                                                                          },
                                                                        ),
                                                                        SizedBox(width: 10,),
                                                                        InkWell(
                                                                          child: Container(
                                                                            padding: EdgeInsets.symmetric(vertical: 5, horizontal: 20),
                                                                            child: Text('Cancel', style: TextStyle(color: Colors.white),),
                                                                            decoration: BoxDecoration(
                                                                                color: Color(0XFF595959),
                                                                                borderRadius: BorderRadius.circular(10)
                                                                            ),
                                                                          ),
                                                                          onTap: () async {
                                                                            Navigator.pop(context);
                                                                          },
                                                                        ),
                                                                      ],
                                                                    )
                                                                  ],
                                                                ),
                                                              );
                                                            },
                                                          );
                                                        },
                                                      ),
                                                    ),
                                                    Container(
                                                      height: 40,
                                                      width: 40,
                                                      child: IconButton(
                                                        onPressed: () async {
                                                          if(activeroom !=null){
                                                            engine.setEnableSpeakerphone(!activeroom.adminenabledspeaker);
                                                            roomsRef.doc(activeroom.roomid).update({
                                                              "adminenabledspeaker" : !activeroom.adminenabledspeaker
                                                            });
                                                          }

                                                        },
                                                        icon: activeroom == null || activeroom.adminenabledspeaker == false
                                                            ? Icon(
                                                          CupertinoIcons.speaker_slash_fill,
                                                          size: 30,
                                                          color: Colors.white,
                                                        )
                                                            : Icon(
                                                          CupertinoIcons.speaker_1_fill,
                                                          size: 30,
                                                          color:
                                                          activeroom.adminenabledspeaker == true ? Colors.green : Colors.white,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        SizedBox(
                                          height: 20,
                                        ),
                                        Text(
                                          'Callers in Queue ~ ${rooms.length.toString()}',
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
                                      children: rooms
                                          .map((item) => QueItem(item))
                                          .toList(),
                                      onReorder: (int start, int current) {
                                        // dragging from top to bottom
                                        reorderAction(start, current);
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              color: Color(
                                  0xff4B494C), // Your screen background color
                            ),
                          ),
                        ),
                      ]),
                    ),
                  ),
                ],
              ),
        bottomNavigationBar: Container(
          margin: EdgeInsets.only(bottom: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
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
                  child: enableHotline(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget QueItem(Room item) {
    UserModel cuser =
        item.users[item.users.indexWhere((element) => element.uid != user.uid)];

    return ListTile(
      focusColor: Colors.transparent,
      selectedTileColor: Colors.transparent,
      hoverColor: Colors.transparent,
      tileColor: Colors.transparent,
      key: Key("${item}"),
      title: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.white38, // red as border color
            ),
            borderRadius: new BorderRadius.only(
              bottomRight: const Radius.circular(50.0),
              topRight: const Radius.circular(50.0),
              bottomLeft: const Radius.circular(5.0),
            ),
            color: Color(0xff5C5D62),
          ),
          padding: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: item != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(60.0),
                              child: CachedNetworkImage(
                                width: 30,
                                imageUrl: cuser.imageurl,
                              ),
                            )
                          : Icon(
                              Icons.person,
                              size: 30,
                            )),
                  SizedBox(
                    width: 30,
                  ),
                  Text("${item.title}"),
                ],
              ),
              Icon(
                Icons.star,
                size: 30,
                color: cuser.stared == true ? Colors.amber : Colors.black,
              )
            ],
          )),
      onTap: () {
        showDialog(
          context: context,
          builder: (context) {
            return Dialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              elevation: 16,
              child: Container(
                width: 150,
                child: ListView(
                  shrinkWrap: true,
                  children: <Widget>[
                    SizedBox(height: 20),
                    Center(
                        child: Text(
                      'Call from ${item.title}',
                      style: TextStyle(fontSize: 21),
                    )),
                    SizedBox(height: 20),
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          InkWell(
                            onTap: () {
                              Navigator.pop(context);
                              receiveCall();
                            },
                            child: Text(
                              'Receive',
                              style:
                                  TextStyle(fontSize: 16, color: Colors.green),
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              Navigator.pop(context);
                              rejectCall(item);
                            },
                            child: Text(
                              'Reject',
                              style: TextStyle(fontSize: 16, color: Colors.red),
                            ),
                          )
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
      // trailing: Icon(Icons.menu),
    );
  }

  BottomWidget() {
    return Row(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(left: 30.0),
          child: Column(
            children: [
              InkWell(
                onTap: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => Admin()));
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
        InkWell(
          onTap: () {
            toggleAudio();
          },
          child: Container(
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
            child: Center(child: Icon(Icons.stop_circle_sharp)),
          ),
        ),
      ],
    );
  }

  enableHotline() {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: () {
              showDialog(
                context: context,
                builder: (context) {
                  return Dialog(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    elevation: 16,
                    child: Container(
                      width: 150,
                      child: ListView(
                        shrinkWrap: true,
                        children: <Widget>[
                          SizedBox(height: 20),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Center(
                              child: Text(
                                "Are you sure you want to ${hotline == false ? 'Close hotline' : 'Open hotline'}",
                                style: TextStyle(
                                    fontSize: 21,
                                    color: hotline == false
                                        ? Colors.red
                                        : Colors.black),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                          SizedBox(height: 20),
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 20, vertical: 10),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                InkWell(
                                  onTap: () {
                                    Navigator.pop(context);
                                    settingsRef
                                        .doc(settingsid)
                                        .update({"hotlineoffline": !hotline});
                                  },
                                  child: Text(
                                    'Yes',
                                    style: TextStyle(
                                        fontSize: 16, color: Colors.green),
                                  ),
                                ),
                                InkWell(
                                  onTap: () {
                                    Navigator.pop(context);
                                  },
                                  child: Text(
                                    'No',
                                    style: TextStyle(
                                        fontSize: 16, color: Colors.red),
                                  ),
                                )
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
            child: Row(
              children: [
                Text(
                  'Hotline: ',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
                Text(
                  hotline == false ? 'Close' : "Open",
                  style: TextStyle(
                      color: hotline == false ? Colors.red : Colors.green,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void reorderAction(int start, int current) {
    if (start < current) {
      int end = current - 1;
      Room startItem = rooms[start];
      int i = 0;
      int local = start;
      do {
        rooms[local] = rooms[++local];
        i++;
      } while (i < end - start);
      rooms[end] = startItem;
    }
    // dragging from bottom to top
    else if (start > current) {
      Room startItem = rooms[start];
      for (int i = start; i > current; i--) {
        rooms[i] = rooms[i - 1];
      }
      rooms[current] = startItem;
    }
    setState(() {});
  }

  iconActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Container(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(60)),
          child: IconButton(
            onPressed: () {
              if (activeroom != null) {
                if(cuser !=null){
                  usersRef.doc(cuser.uid).snapshots().listen((event) {
                    cuser = UserModel.fromJson(event.data());
                  });
                }

                usersRef.doc(cuser.uid).update({"stared": !cuser.stared});
                print(cuser.uid);
                //update user in the room with a star rating
                roomsRef.doc(activeroom.roomid).update({
                  "users": activeroom.users
                      .map((i) =>
                          i.toMap(stared: i.uid == cuser.uid ? !cuser.stared : i.stared))
                      .toList(),
                });

                listen = usersRef.doc(cuser.uid).snapshots().listen((event) {
                  cuser = UserModel.fromJson(event.data());
                  setState(() {

                  });
                });

                //update user profile with s start rating


                //send notification to theuser who has been started
                PushNotificationsManager.callOnFcmApiSendPushNotifications(
                  userToken: [cuser.firebasetoken],
                  title: "Stared",
                  msg: "You have been starred",
                );
              }
            },
            icon: Icon(
              Icons.star,
              color: cuser != null && cuser.stared == true
                  ? Colors.amber
                  : Colors.black,
              size: 40,
            ),
          ),
        ),
        SizedBox(
          width: 10,
        ),
        Container(
          height: 40,
          width: 40,
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(60),
              border: Border.all(
                  width: 1.0,
                  color: activeroom == null || activeroom.adminmuted == false
                      ? Colors.white
                      : Colors.green)),
          child: IconButton(
            onPressed: () async {
              if(activeroom !=null){
                engine.muteLocalAudioStream(!activeroom.adminmuted);
                roomsRef.doc(activeroom.roomid).update({
                  "adminmuted" : !activeroom.adminmuted
                });
              }

            },
            icon: activeroom == null || activeroom.adminmuted == false
                ? Icon(
                    CupertinoIcons.mic,
                    size: 20,
                    color: Colors.white,
                  )
                : Icon(
                    CupertinoIcons.mic_off,
                    size: 20,
                    color:
                    activeroom.adminmuted == true ? Colors.green : Colors.white,
                  ),
          ),
        ),
        SizedBox(
          width: 10,
        ),
        Container(
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(60), color: Colors.grey),
          child: InkWell(
            onTap: () {
              if (activeroom != null) {
                extendedtime += 30;
                roomsRef.doc(activeroom.roomid).update({
                  "time": activeroom.time + 30,
                  "extendedtime": extendedtime
                });
              }
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add_box,
                  color: Colors.white,
                  size: 15,
                ),
                SizedBox(
                  height: 5,
                ),
                Text(
                  "30 sec",
                  style: TextStyle(fontSize: 6, color: Colors.white),
                )
              ],
            ),
          ),
          width: 40,
          height: 40,
        ),
        SizedBox(
          width: 10,
        ),
        Container(
          margin: EdgeInsets.symmetric(horizontal: 5),
          width: 40,
          height: 40,
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(60), color: Colors.red),
          child: IconButton(
            onPressed: () {
              if (activeroom != null) {
                showDialog(
                  context: context,
                  builder: (context) {
                    return Dialog(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      elevation: 16,
                      child: Container(
                        width: 150,
                        child: ListView(
                          shrinkWrap: true,
                          children: <Widget>[
                            SizedBox(height: 20),
                            Center(
                                child: Text(
                                    'Are you sure you want to end the call?',
                                    style: TextStyle(fontSize: 21),
                                    textAlign: TextAlign.center)),
                            SizedBox(height: 20),
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 10),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  InkWell(
                                    onTap: () {
                                      Navigator.pop(context);
                                      receiveCall();
                                    },
                                    child: Text(
                                      'No',
                                      style: TextStyle(
                                          fontSize: 16, color: Colors.green),
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () {
                                      Navigator.pop(context);
                                      leaveChannel();
                                    },
                                    child: Text(
                                      'Yes',
                                      style: TextStyle(
                                          fontSize: 16, color: Colors.red),
                                    ),
                                  )
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                    );
                  },
                );
              }
            },
            icon: Icon(
              Icons.call_end,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(60)),
          child: IconButton(
            onPressed: () {
              if (activeroom != null) {
                showDialog(
                  context: context,
                  builder: (context) {
                    return Dialog(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      elevation: 16,
                      child: Container(
                        width: 150,
                        child: ListView(
                          shrinkWrap: true,
                          children: <Widget>[
                            SizedBox(height: 20),
                            Center(
                                child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                'Are you sure you want to block ${cuser.username}?',
                                style: TextStyle(fontSize: 21),
                              ),
                            )),
                            SizedBox(height: 20),
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 10),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  InkWell(
                                    onTap: () {
                                      Navigator.pop(context);
                                    },
                                    child: Text(
                                      'No',
                                      style: TextStyle(
                                          fontSize: 16, color: Colors.green),
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () {
                                      Navigator.pop(context);
                                      usersRef
                                          .doc(cuser.uid)
                                          .update({"blocked": true});
                                      leaveChannel();
                                    },
                                    child: Text(
                                      'Yes',
                                      style: TextStyle(
                                          fontSize: 16, color: Colors.red),
                                    ),
                                  )
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                    );
                  },
                );
              }
            },
            icon: Icon(
              Icons.block,
              color: Colors.white,
              size: 35,
            ),
          ),
        )
      ],
    );
  }

  callTimerView() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Text(
              activeroom == null ? "0:00" : timerText,
              style: TextStyle(
                color: checkLimitsColors(activeroom,currentSeconds),
                fontWeight: FontWeight.bold,
                fontSize: 35,
              ),
            ),
            Text(
              'Time used',
              style: TextStyle(color: checkLimitsColors(activeroom,currentSeconds), fontWeight: FontWeight.bold),
            ),
          ],
        ),
        SizedBox(
          width: 10,
        ),
        RotationTransition(
            turns: new AlwaysStoppedAnimation(15 / 360),
            child: Container(
                height: 40,
                margin: const EdgeInsets.only(bottom: 20.0),
                child: VerticalDivider(thickness: 4, color: Colors.white))),
        SizedBox(
          width: 10,
        ),
        Column(
          children: [
            Text(
              activeroom == null
                  ? "${callslimit}"
                  : '${((activeroom.time) ~/ 60).toString().padLeft(2, '0')}: ${((activeroom.time) % 60).toString().padLeft(2, '0')}',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 35),
            ),
            Text(
              'Total time',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }
}
