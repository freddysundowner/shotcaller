import 'dart:async';
import 'dart:io';

import 'package:agora_rtc_engine/rtc_engine.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
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
import 'package:shotcaller/slider/src/slider.dart';
import 'package:shotcaller/utils/firebase_refs.dart';
import 'package:shotcaller/utils/utils.dart';
import 'package:shotcaller/widgets/common_widgets.dart';
import 'package:shotcaller/percent/percent_indicator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'admin_screen.dart';

class StartCall extends StatefulWidget {
  @override
  _StartCallState createState() => _StartCallState();
}

enum TtsState { playing, stopped }

class _StartCallState extends State<StartCall> with WidgetsBindingObserver {
  UserModel user = Get.find<UserController>().user;
  bool callwaiting = false;
  bool loading = false;
  String statustxt = "";
  Room room;
  StreamSubscription<DocumentSnapshot> calllistener;
  StreamSubscription<QuerySnapshot> listen;
  RtcEngine engine;
  int tt = 0;
  bool recording = false;

  bool timeextended = false;
  int currentSeconds = 0, callslimit = 0;
  bool hotlineoffline = false;
  String showlink = "";
  String showlinkname = "";

  var linknamecontroller = TextEditingController();
  var usernamecontroller = TextEditingController();
  var linkcontroller = TextEditingController();
  String settingsid = "";
  String txt = "";

  final picker = ImagePicker();
  File _imageFile;

  @override
  void initState() {
    super.initState();
    initialize();
    listen = settingsRef.snapshots().listen((event) {
      callslimit = event.docs[0].data()["callslimit"];
      settingsid = event.docs[0].id;
      hotlineoffline = event.docs[0].data()["hotlineoffline"];
      showlink = event.docs[0].data()["showlink"];
      showlinkname = event.docs[0].data()["showlinkname"];
      linknamecontroller.text = showlinkname;
      linkcontroller.text = showlink;
      setState(() {});
    });
  }

  /// Create Agora SDK instance and initialize
  Future<void> initialize() async {
    await _initAgoraRtcEngine();
    _addAgoraEventHandlers();
    callInit();
  }

  static AudioCache player = new AudioCache();

  callInit() {
    print("callInit");
    calllistener = roomsRef.doc(user.uid).snapshots().listen((event) async {
      print("callInit ${event}");
      if (event.exists) {
        if (room != null) {
          if (room.extendedtime < event.data()["extendedtime"]) {
            addedTimeNofier();
          }
        }

        room = Room.fromJson(event);
        print("room data ${room.roomid}");
        if (room.status == "active") {
          await engine
              .setDefaultAudioRoutetoSpeakerphone(room.userenabledspeaker);
          await engine.joinChannel(room.token, room.owner, null, 0);
        }
        if (room.status == "waiting") {
          callwaiting = true;
          statustxt = "Waiting on call";
        }
        setState(() {});
      } else {
        leaveChannel();
      }
    });
  }

  void addedTimeNofier() {
    const alarmAudioPath = "sounds/seconds_added.mp3";
    player.play(alarmAudioPath);
    var snackBar = SnackBar(
      content: Text("+30 seconds added"),
      backgroundColor: Colors.green,
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  Future<void> leaveChannel() async {
    await engine.leaveChannel();
    if (room != null) {
      roomsRef.doc(room.roomid).delete();
    }
    setState(() {
      room = null;
      statustxt = "";
      callwaiting = false;
      currentSeconds = 0;
    });
    // checkLimitsColors();
    print("room " + room.toString());
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
          setState(() {
            callwaiting = false;
            statustxt = "On call";
          });
        },
        leaveChannel: (stats) {
          print("leaving one");
        },
        userOffline: (uid, elapsed) {
          final info = 'userOffline: $uid';
          print(info);
        },
        audioRouteChanged: (AudioOutputRouting audioOutputRouting) {
          print("audioOutputRouting " + audioOutputRouting.index.toString());
        },
        userJoined: (uid, elapsed) {
          currentSeconds;
          print('userJoined: $uid');
        },
        audioVolumeIndication:
            (List<AudioVolumeInfo> speakers, int totalVolume) {},
        remoteAudioStats: (RemoteAudioStats remoteAudioStats) {},
        rtcStats: (RtcStats rtcStats) {
          setState(() {
            currentSeconds = rtcStats.totalDuration;
          });
          if(room != null && (room.time - rtcStats.totalDuration) <=10){
            const alarmAudioPath = "sounds/economics.mp3";
            player.play(alarmAudioPath);
          }
          if (room != null && rtcStats.totalDuration >= room.time) {
            print("leaving four");
            leaveChannel();
          }
        }));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    listen.cancel();
    super.dispose();
  }

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
              SizedBox(
                height: 10,
              ),
              InkWell(
                onTap: () {
                  Navigator.pop(context);
                  _getFromGallery();
                },
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Text("Choose from galley"),
                ),
              ),
              SizedBox(
                height: 20,
              ),
              InkWell(
                onTap: () {
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
    PickedFile pickedFile =
        await picker.getImage(source: ImageSource.gallery);
    _cropImage(pickedFile.path);
  }

  _getFromCamera() async {
    PickedFile pickedFile =
        await picker.getImage(source: ImageSource.camera);
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
        ));
    if (croppedImage != null) {
      _imageFile = croppedImage;
      Get.find<OnboardingController>().imageFile = _imageFile;
      Database().uploadImage(user.uid, update: true);
      setState(() {});
    }
  }

  _showUsernameDialog() async {
    await showDialog<String>(
      context: context,
      builder: (ct) {
        return StatefulBuilder(builder: (context, setState) {
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
                        controller: usernamecontroller,
                        keyboardType: TextInputType.number,
                        decoration: new InputDecoration(
                          labelText: 'Username',
                        ),
                      ),
                      if (txt.isNotEmpty)
                        Text(
                          txt,
                          style: TextStyle(color: Colors.red),
                        )
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
                    if (usernamecontroller.text.isEmpty) {
                      txt = "enter username first";
                      setState(() {});
                    } else {
                      Navigator.pop(context);
                      usersRef.doc(user.uid).update(
                          {"username": usernamecontroller.text});
                      usernamecontroller.text = "";
                    }
                  })
            ],
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    usernamecontroller.text = user.username;
    return Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: ThemeColor1,
        body: CustomScrollView(
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.max,
                  children: <Widget>[
                    SizedBox(
                      height: 20,
                    ),
                    logoWidget(sz1: 200, sz2: 16, from: "home"),
                    SizedBox(
                      height: 30,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        InkWell(
                          onTap: () {
                            _showMyDialog();
                          },
                          child: _imageFile != null
                              ? Container(
                                  child: ClipOval(
                                    child: Image.file(
                                      _imageFile,
                                      height: 50,
                                      width: 50,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                )
                              : Container(
                                  decoration: BoxDecoration(
                                    borderRadius:
                                        BorderRadius.circular(20),
                                  ),
                                  child: user.imageurl != null
                                      ? ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(60.0),
                                          child: CachedNetworkImage(
                                            width: 50,
                                            imageUrl: user.imageurl,
                                          ),
                                        )
                                      : Icon(
                                          Icons.person,
                                          size: 30,
                                        )),
                        ),
                        SizedBox(
                          width: 20,
                        ),
                        TextButton.icon(
                            onPressed: () {
                              _showUsernameDialog();
                            },
                            icon: Icon(Icons.edit),
                            label: Text(
                              (statustxt == null && statustxt.isNotEmpty
                                  ? statustxt + "..."
                                  : user.username),
                              style: TextStyle(
                                  color: Color(0xffB8B8B8),
                                  fontSize: 24,
                                  fontFamily: "InterExtraBold"),
                            )),
                      ],
                    ),
                    SizedBox(
                      height: 10,
                    ),
                    Stack(
                      children: [
                        Center(
                          child: CircularPercentIndicator(
                            radius: 200,
                            startAngle: 360,
                            animateFromLastPercent: true,
                            animation: true,
                            totaltime: room == null
                                ? 240.0
                                : room.time.toDouble(),
                            animationDuration: 1200,
                            addAutomaticKeepAlive: true,
                            lineWidth: 20.0,
                            percent: room != null && room.time != null
                                ? (currentSeconds / room.time * 360)
                                : 0,
                            center: Image.asset(
                              'assets/images/soul_logo.png',
                              width: 140,
                              fit: BoxFit.cover,
                            ),
                            circularStrokeCap: CircularStrokeCap.round,
                            backgroundColor: Colors.grey,
                            progressColor:
                                checkLimitsColors(room, currentSeconds),
                          ),
                        ),
                        if (showlink.isNotEmpty)
                          Positioned(
                            child: InkWell(
                                onTap: () async {
                                  showDialog(
                                    context: context,
                                    barrierDismissible: false,
                                    // user must tap button!
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        content: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(
                                              child: DefaultTextStyle(
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .title,
                                                child: RichWidget(
                                                  showlinkname:
                                                      showlinkname,
                                                ),
                                              ),
                                            ),
                                            SizedBox(
                                              height: 30,
                                            ),
                                            Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.end,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.end,
                                              children: [
                                                InkWell(
                                                  child: Container(
                                                    padding: EdgeInsets
                                                        .symmetric(
                                                            vertical: 5,
                                                            horizontal:
                                                                10),
                                                    child: Text(
                                                      'Continue',
                                                      style: TextStyle(
                                                          color: Colors
                                                              .white),
                                                    ),
                                                    decoration: BoxDecoration(
                                                        color: Color(
                                                            0XFF5761E3),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(
                                                                    20)),
                                                  ),
                                                  onTap: () async {
                                                    String url = showlink;
                                                    if (await canLaunch(
                                                        url))
                                                      await launch(url);
                                                    else
                                                      // can't launch url, there is some error
                                                      throw "Could not launch $url";
                                                  },
                                                ),
                                                SizedBox(
                                                  width: 30,
                                                ),
                                                InkWell(
                                                  child: Container(
                                                    padding: EdgeInsets
                                                        .symmetric(
                                                            vertical: 5,
                                                            horizontal:
                                                                10),
                                                    child: Text(
                                                      'Cancel',
                                                      style: TextStyle(
                                                          color: Colors
                                                              .white),
                                                    ),
                                                    decoration: BoxDecoration(
                                                        color: Color(
                                                            0XFF595959),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(
                                                                    20)),
                                                  ),
                                                  onTap: () async {
                                                    Navigator.pop(
                                                        context);
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
                                child: Icon(Icons.info)),
                            top: 0,
                            right: 80,
                          )
                      ],
                    ),
                    SizedBox(
                      height: 30,
                    ),
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(20.0),
                            topRight: const Radius.circular(20.0),
                          ),
                          color: Color(0xff353336),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Expanded(
                              child: Column(
                                children: [
                                  SizedBox(
                                    height: 60,
                                  ),
                                  timeCalculator(),
                                  SizedBox(
                                    height: 20,
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: <Widget>[
                                      Column(
                                        children: [
                                          InkWell(
                                            onTap: room ==null ? null : () {
                                              print("mute");
                                              engine.muteLocalAudioStream(!room.usermuted);
                                              roomsRef
                                                  .doc(room.roomid)
                                                  .update({"usermuted": !room.usermuted});
                                            },
                                            child: Column(
                                              children: [
                                                Container(
                                                  padding: EdgeInsets.symmetric(
                                                      horizontal: 10, vertical: 10),
                                                  decoration: BoxDecoration(
                                                      borderRadius: BorderRadius.all(
                                                        Radius.circular(15),
                                                      ),
                                                      border: Border.all(
                                                          width: 1.0, color: Colors.white)),
                                                  child: room !=null && room.usermuted == true
                                                      ? Icon(
                                                    CupertinoIcons.speaker_slash_fill,
                                                    color: Colors.white,
                                                  )
                                                      : Icon(
                                                    CupertinoIcons.speaker_1_fill,
                                                    color: room !=null && room.usermuted == true
                                                        ? Colors.green
                                                        : Colors.white,
                                                  ),
                                                ),
                                                SizedBox(
                                                  height: 10,
                                                ),
                                                Text('mute',
                                                    style: TextStyle(
                                                        color: room !=null && room.usermuted == true
                                                            ? Colors.green
                                                            : Colors.white,
                                                        fontSize: 13)),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(
                                        width: 30,
                                      ),
                                      InkWell(
                                        onTap: room ==null ? null : () {
                                          engine.setEnableSpeakerphone(!room.userenabledspeaker);
                                          roomsRef.doc(room.roomid).update(
                                              {"userenabledspeaker": !room.userenabledspeaker});
                                        },
                                        child: Column(
                                          children: [
                                            Container(
                                              padding:
                                              EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                              decoration: BoxDecoration(
                                                  borderRadius: BorderRadius.all(
                                                    Radius.circular(15),
                                                  ),
                                                  border:
                                                  Border.all(width: 1.0, color: Colors.white)),
                                              child: Icon(
                                                CupertinoIcons.speaker_3,
                                                color: room !=null && room.userenabledspeaker == true
                                                    ? Colors.green
                                                    : Colors.white,
                                              ),
                                            ),
                                            SizedBox(
                                              height: 10,
                                            ),
                                            Text('Speaker',
                                                style: TextStyle(
                                                    color: room !=null && room.userenabledspeaker == true
                                                        ? Colors.green
                                                        : Colors.white,
                                                    fontSize: 13)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(
                                    height: 30,
                                  ),
                                ],
                              ),
                            ),
                            CallButton(),
                            SizedBox(
                              height: 80,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ]),
            ),
          ],
        ));
  }

  onWaitingCallWidget() {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 30),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(60.0),
            topRight: const Radius.circular(60.0),
          ),
          color: Color(0xff353336),
        ),
        child: Column(
          children: [
            Expanded(
              child: timeCalculator(),
            ),
            SizedBox(
              height: 20,
            ),
            CallButton()
          ],
        ),
      ),
    );
  }

  timeCalculator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        timeUsedView(currentSeconds),
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
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              room == null
                  ? "4:00"
                  : '${((room.time) ~/ 60).toString().padLeft(2, '0')}: ${((room.time) % 60).toString().padLeft(2, '0')}',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 40),
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

  Column timeUsedView(int second) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          room == null || second == null
              ? "0:00"
              : '${((second) ~/ 60).toString().padLeft(2, '0')}: ${((second) % 60).toString().padLeft(2, '0')}',
          style: TextStyle(
              color: checkLimitsColors(room, second),
              fontWeight: FontWeight.bold,
              fontSize: 40),
        ),
        Text(
          'Time used',
          style: TextStyle(
              color: checkLimitsColors(room, second),
              fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  onCallWidget() {
    return Expanded(
      flex: 1,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 30),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20.0),
            topRight: const Radius.circular(20.0),
          ),
          color: Color(0xff353336),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            timeCalculator(),
            SizedBox(
              height: 20,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Column(
                  children: [
                    InkWell(
                      onTap: room ==null ? null : () {
                        print("mute");
                        engine.muteLocalAudioStream(!room.usermuted);
                        roomsRef
                            .doc(room.roomid)
                            .update({"usermuted": !room.usermuted});
                      },
                      child: Column(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 10, vertical: 10),
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(15),
                                ),
                                border: Border.all(
                                    width: 1.0, color: Colors.white)),
                            child: room !=null && room.usermuted == true
                                ? Icon(
                                    CupertinoIcons.speaker_slash_fill,
                                    color: Colors.white,
                                  )
                                : Icon(
                                    CupertinoIcons.speaker_1_fill,
                                    color: room !=null && room.usermuted == true
                                        ? Colors.green
                                        : Colors.white,
                                  ),
                          ),
                          SizedBox(
                            height: 10,
                          ),
                          Text('mute',
                              style: TextStyle(
                                  color: room !=null && room.usermuted == true
                                      ? Colors.green
                                      : Colors.white,
                                  fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  width: 30,
                ),
                InkWell(
                  onTap: room ==null ? null : () {
                    engine.setEnableSpeakerphone(!room.userenabledspeaker);
                    roomsRef.doc(room.roomid).update(
                        {"userenabledspeaker": !room.userenabledspeaker});
                  },
                  child: Column(
                    children: [
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.all(
                              Radius.circular(15),
                            ),
                            border:
                                Border.all(width: 1.0, color: Colors.white)),
                        child: Icon(
                          CupertinoIcons.speaker_3,
                          color: room !=null && room.userenabledspeaker == true
                              ? Colors.green
                              : Colors.white,
                        ),
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      Text('Speaker',
                          style: TextStyle(
                              color: room !=null && room.userenabledspeaker == true
                                  ? Colors.green
                                  : Colors.white,
                              fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(
              height: 30,
            ),
            CallButton()
          ],
        ),
      ),
    );
  }

  CallButton() {
    return SliderButton(
      action: () async {
        try {
          setState(() {
            callwaiting = false;
            statustxt = "";
          });
          if (room != null) {
            leaveChannel();

            const alarmAudioPath = "sounds/hangup.mp3";
            player.play(alarmAudioPath);
          } else {
            setState(() {
              callwaiting = true;
              statustxt = "Calling";
            });
            // creating aroom
            await Database().getSettings().then((value) async {
              if (value.data()["hotlineoffline"] == true ||
                  user.blocked == true) {
                Get.snackbar("", "",
                    snackPosition: SnackPosition.TOP,
                    borderRadius: 0,
                    margin: EdgeInsets.all(0),
                    backgroundColor: Colors.red,
                    colorText: Colors.white,
                    messageText: Text.rich(TextSpan(
                      children: [
                        TextSpan(
                          text:
                              "call cannot go through ${user.blocked == true ? "you have been blocked," : ""} try again alter",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16.0,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    )));
                setState(() {
                  callwaiting = false;
                  statustxt = "";
                });
              } else {
                await Database()
                    .getCallToken(user.uid, "0")
                    .then((token) async {
                  if (token != null) {
                    await roomsRef.doc(user.uid).set(
                      {
                        'owner': user.uid,
                        'title': user.username,
                        "token": token,
                        "currentstatus": "off",
                        "time": callslimit,
                        "muted": false,
                        "extendedtime": 0,
                        "users": [user.toMap()],
                        "status": "waiting"
                      },
                    );
                    setState(() {
                      callwaiting = true;
                      statustxt = "Waiting on call";
                    });
                  }
                });
              }
            });
          }
        } catch (e) {
          print("error " + e.toString());
        }
      },
      disable: hotlineoffline,
      alignKnob:
          callwaiting == true || (room != null && room.status == "active")
              ? Alignment.centerRight
              : Alignment.centerLeft,

      ///Put label over here
      label: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Text(
          hotlineoffline ==true ? "Hotline currently closed" : callwaiting == true || room != null && room.status == "active"
              ? "Slide left end the call"
              : "Slide right start the call",
          style: TextStyle(
              color: callwaiting == true ? Colors.red : Colors.white,
              fontWeight: FontWeight.w500,
              fontSize: 17),
        ),
      ),
      alignLabel: callwaiting == true || room != null && room.status == "active"
          ? Alignment.centerLeft
          : Alignment.centerRight,
      icon: Center(
          child: Icon(
        Icons.call_end,
        color: Colors.white,
      )),

      //Put BoxShadow here
      boxShadow: BoxShadow(
        color: Colors.black,
        blurRadius: 4,
      ),

      //Adjust effects such as shimmer and flag vibration here
      // shimmer: true,
      // vibrationFlag: true,

      ///Change All the color and size from here.
      width: MediaQuery.of(context).size.width * 0.9,
      // height: 80,
      radius: 60,

      buttonColor: hotlineoffline == true
          ? Colors.grey
          : callwaiting == true
              ? Colors.red
              : Colors.green,
      backgroundColor: ThemeColor1,
      highlightedColor: Colors.white,
      dismissible: false,
      // shimmer: false,

      baseColor: Colors.white,
      //dismissible: false,
    );
  }

  void pushToCallScreen() {
    Navigator.of(context, rootNavigator: true).push(MaterialPageRoute(
        fullscreenDialog: true, builder: (context) => Admin()));
  }
}

class RichWidget extends StatelessWidget {
  String showlinkname;

  RichWidget({this.showlinkname});

  @override
  Widget build(BuildContext context) {
    return RichText(
      textAlign: TextAlign.start,
      text: TextSpan(
        text: 'You are about to go to ',
        style: DefaultTextStyle.of(context).style,
        children: <TextSpan>[
          TextSpan(
              text: '${showlinkname}',
              style:
                  TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
        ],
      ),
    );
  }
}
