import 'dart:async';
import 'dart:io';

import 'package:agora_rtc_engine/rtc_engine.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shotcaller/controllers/controllers.dart';
import 'package:shotcaller/models/room.dart';
import 'package:shotcaller/models/user_model.dart';
import 'package:shotcaller/services/database.dart';
import 'package:shotcaller/shared/colors.dart';
import 'package:shotcaller/shared/configs.dart';
import 'package:shotcaller/slider/src/slider.dart';
import 'package:shotcaller/utils/firebase_refs.dart';
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
  RtcEngine engine;
  int tt = 0;
  bool mute = false;
  bool recording = false;
  bool speaker = false;

  bool timeextended = false;
  int currentSeconds = 0, callslimit = 0;

  @override
  void initState() {
    super.initState();
    initialize();
    settingsRef.snapshots().listen((event) {
      callslimit = event.docs[0].data()["callslimit"];
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
    calllistener = roomsRef
        .doc(user.uid)
        .snapshots()
        .listen((event) async {
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
      secondsNotifier.value = 0;
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
      await engine.setDefaultAudioRoutetoSpeakerphone(true);
      await engine.setClientRole(ClientRole.Broadcaster);
    } catch (e) {
      print("error general " + e.toString());
    }
  }

  ValueNotifier<int> secondsNotifier = ValueNotifier(null);
  ValueNotifier<Color> colorRing = ValueNotifier(null);

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
          print(rtcStats.totalDuration);
          secondsNotifier.value = rtcStats.totalDuration;
          if((room.time/2) < rtcStats.totalDuration){
            colorRing.value = Colors.green;
          }
          if((room.time/2) > rtcStats.totalDuration){
            colorRing.value = Colors.red;
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: ThemeColor1,
        body: SafeArea(
            child: loading == true
                ? Center(
                    child: Container(
                      child: CircularProgressIndicator(),
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                        SizedBox(
                          height: 20,
                        ),
                        logoWidget(sz1: 250, sz2: 16, from: "home"),
                        SizedBox(
                          height: 30,
                        ),
                        Text(
                          (statustxt.isNotEmpty
                              ? statustxt + "..."
                              : user.username),
                          style: TextStyle(
                              color: Color(0xffB8B8B8),
                              fontSize: 24,
                              fontFamily: "InterExtraBold"),
                        ),
                        SizedBox(
                          height: 30,
                        ),
                        Stack(
                          children: [
                            Center(
                              child: ValueListenableBuilder<int>(
                                  valueListenable: secondsNotifier,
                                  builder: (ctx, second, _) {
                                    if (second == null) {
                                      return CircularPercentIndicator(
                                        radius: 200,
                                        startAngle: 360,
                                        animateFromLastPercent: true,
                                        animation: true,
                                        animationDuration: 1200,
                                        addAutomaticKeepAlive: true,
                                        lineWidth: 20.0,
                                        percent: 0,
                                        center: Image.asset(
                                          'assets/images/soul_logo.png',
                                          width: 150,
                                          fit: BoxFit.cover,
                                        ),
                                        circularStrokeCap: CircularStrokeCap.round,
                                        backgroundColor: Colors.grey,
                                        progressColor: checkLimitsColors(),
                                      );
                                    }
                                    return CircularPercentIndicator(
                                      radius: 200,
                                      startAngle: 360,
                                      animateFromLastPercent: true,
                                      animation: true,
                                      totaltime:
                                          room == null ? 240.0 : room.time.toDouble(),
                                      animationDuration: 1200,
                                      addAutomaticKeepAlive: true,
                                      lineWidth: 20.0,
                                      percent: room != null
                                          ? (second.toDouble() - room.extendedtime) <
                                                  0
                                              ? 0
                                              : (second.toDouble() -
                                                  room.extendedtime)
                                          : 0,
                                      center: Image.asset(
                                        'assets/images/soul_logo.png',
                                        width: 150,
                                        fit: BoxFit.cover,
                                      ),
                                      circularStrokeCap: CircularStrokeCap.round,
                                      backgroundColor: Colors.grey,
                                      progressColor: colorRing.value,
                                    );
                                  }),
                            ),
                            Positioned(
                                child: InkWell(
                                    onTap: () async{
                                      const url = "https://flutter.io";
                                      if (await canLaunch(url))
                                        await launch(url);
                                      else
                                        // can't launch url, there is some error
                                        throw "Could not launch $url";
                                    },
                                    child: Icon(Icons.info)
                                ),
                                top: 0,
                                right: 110,
                            )
                          ],
                        ),
                        SizedBox(
                          height: 30,
                        ),
                        if (callwaiting == true || room == null)
                          onWaitingCallWidget(),
                        if (callwaiting == false && room != null) onCallWidget()
                      ])));
  }

  checkLimitsColors() {
    return Colors.green;
    if (room != null && room.status == "waiting") {
      secondsNotifier == null;
    }
    if (secondsNotifier == null || secondsNotifier.value == 0 || room == null) {
      return Colors.grey;
    }
    else if (secondsNotifier.value > 0 &&
        secondsNotifier.value < room.time / 2) {
      return Colors.green;
    }
    else if (secondsNotifier.value > 0 &&
        secondsNotifier.value > room.time / 2) {
      int time1 = (room.time - secondsNotifier.value);
      if (time1 != 0 && time1 <= room.time / 3) {
        print("time1 ${time1}");
        return Colors.red;
      } else {
        print("bbb ${time1}");
        return Colors.amber;
      }
    }
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
        ValueListenableBuilder<int>(
            valueListenable: secondsNotifier,
            builder: (ctx, second, _) {
              if (second == null) return timeUsedView(second);
              return timeUsedView(second);
            }),
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
              color: checkLimitsColors(),
              fontWeight: FontWeight.bold,
              fontSize: 40),
        ),
        Text(
          'Time used',
          style: TextStyle(
              color: checkLimitsColors(), fontWeight: FontWeight.bold),
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
            topLeft: const Radius.circular(60.0),
            topRight: const Radius.circular(60.0),
          ),
          color: Color(0xff353336),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            timeCalculator(),
            SizedBox(
              height: 30,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Column(
                  children: [
                    InkWell(
                      onTap: () {
                        print("mute");
                        engine.muteLocalAudioStream(!mute);
                        setState(() {
                          mute = !mute;
                        });
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
                            child: mute == true
                                ? Icon(
                                    CupertinoIcons.speaker_slash_fill,
                                    color: Colors.white,
                                  )
                                : Icon(
                                    CupertinoIcons.speaker_1_fill,
                                    color: mute == true
                                        ? Colors.green
                                        : Colors.white,
                                  ),
                          ),
                          SizedBox(
                            height: 10,
                          ),
                          Text('mute',
                              style: TextStyle(
                                  color: mute == true
                                      ? Colors.green
                                      : Colors.white,
                                  fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  width: 40,
                ),
                InkWell(
                  onTap: () {
                    engine.setEnableSpeakerphone(!speaker);
                    setState(() {
                      speaker = !speaker;
                    });
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
                          color: speaker == true ? Colors.green : Colors.white,
                        ),
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      Text('Speaker',
                          style: TextStyle(
                              color:
                                  speaker == true ? Colors.green : Colors.white,
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
    print("CallButton ${room}");
    return SliderButton(
      action: () async {

        try {
          setState(() {
            callwaiting = false;
            statustxt = "";
          });

          print("room ${room}");
          // Get.to(() => Adminmoredetails());
          if (room != null) {
            leaveChannel();
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
      alignKnob:
          callwaiting == true || (room != null && room.status == "active")
              ? Alignment.centerRight
              : Alignment.centerLeft,

      ///Put label over here
      label: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Text(
          callwaiting == true || room != null && room.status == "active"
              ? "Slide left end the call"
              : "Slide right start the Call",
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
          child: Icon(Icons.call_end,color: Colors.white,)
      ),

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

      buttonColor: callwaiting == true ? Colors.red : Colors.green  ,
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
