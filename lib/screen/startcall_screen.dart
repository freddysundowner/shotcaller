import 'dart:async';
import 'dart:io';

import 'package:agora_rtc_engine/rtc_engine.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
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
import 'admin.dart';
import 'package:shotcaller/percent/percent_indicator.dart';

class StartCall extends StatefulWidget {
  @override
  _StartCallState createState() => _StartCallState();
}

enum TtsState { playing, stopped }

class _StartCallState extends State<StartCall> with WidgetsBindingObserver {
  UserModel user = Get.find<UserController>().user;
  bool callwaiting = false;
  bool loading = true;
  String statustxt = "";
  Room room;
  StreamSubscription<QuerySnapshot> calllistener;
  RtcEngine engine;
  int tt = 0;
  bool mute = false;
  bool recording = false;
  bool speaker = false;

  // int timerMaxSeconds = 240;
  // int timerMaxSeconds = 20;
  bool timeextended = false;
  int currentSeconds = 0;
  FlutterTts flutterTts = FlutterTts();
  String language;
  double volume = 0.5;
  double pitch = 1.0;
  double rate = 0.5;

  TtsState ttsState = TtsState.stopped;

  get isPlaying => ttsState == TtsState.playing;

  get isStopped => ttsState == TtsState.stopped;

  String get timerText =>
      '${((currentSeconds) ~/ 60).toString().padLeft(2, '0')}: ${((currentSeconds) % 60).toString().padLeft(2, '0')}';

  @override
  void initState() {
    super.initState();
    // initialize();
    initialize();
    callSpeechInit();
  }

  Future _speak() async {
    await flutterTts.setVolume(volume);
    await flutterTts.setSpeechRate(rate);
    await flutterTts.setPitch(pitch);

    if (statustxt != null) {
      if (statustxt.isNotEmpty) {
        var result = await flutterTts.speak(statustxt);
        if (result == 1) setState(() => ttsState = TtsState.playing);
      }
    }
  }

  Future _stop() async {
    var result = await flutterTts.stop();
    if (result == 1) setState(() => ttsState = TtsState.stopped);
  }

  callSpeechInit() {
    flutterTts.setStartHandler(() {
      setState(() {
        print("playing");
        ttsState = TtsState.playing;
      });
    });

    flutterTts.setCompletionHandler(() {
      setState(() {
        print("Complete");
        ttsState = TtsState.stopped;
      });
    });

    flutterTts.setErrorHandler((msg) {
      setState(() {
        print("error: $msg");
        ttsState = TtsState.stopped;
      });
    });
  }

  /// Create Agora SDK instance and initialize
  Future<void> initialize() async {
    await _initAgoraRtcEngine();
    _addAgoraEventHandlers();
    callInit();
  }

  callInit() async {
    calllistener = await roomsRef
        .where("owner", isEqualTo: user.uid)
        .snapshots()
        .listen((event) async {
      print("callInit ${event.docs.length}");
      if (event.docs.length > 0) {
        event.docs.forEach((element) async {
          room = Room.fromJson(element);
          if (room.status == "active") {
            await engine.leaveChannel();
            await engine.joinChannel(room.token, room.owner, null, 0);
            setState(() {
              loading = false;
              callwaiting = false;
              statustxt = "On call";
            });
          } else if (room.status == "waiting") {
            // _speak();
            setState(() {
              loading = false;
              callwaiting = true;
              statustxt = "Waiting on call";
            });
            // _stop();
          }
        });
      } else {
        leaveChannel();
        setState(() {
          loading = false;
        });
      }
    });
  }

  Future<void> leaveChannel() async {
    await engine.leaveChannel();
    if (room != null) {
      roomsRef.doc(room.roomid).delete();
      setState(() {
        room = null;
        statustxt = "";
        callwaiting = false;
        currentSeconds = 0;
      });
    }
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
          setState(() {
            currentSeconds = rtcStats.totalDuration;
          });
          if (room != null) {
            if (currentSeconds >= room.time) {
              print("leaving four");
              leaveChannel();
            }
          }
        }));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    flutterTts.stop();
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
                    children: <Widget>[ SizedBox(
                      height: 20,
                    ),
                        logoWidget(sz1: 30, sz2: 16, from: "home"),
                        SizedBox(
                          height: 10,
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
                        CircularPercentIndicator(
                          radius: 200,
                          startAngle: 360,
                          animateFromLastPercent: true,
                          animation: true,
                          animationDuration: 1200,
                          addAutomaticKeepAlive: true,
                          lineWidth: 20.0,
                          percent: room != null
                              ? (currentSeconds.toDouble() -
                                          room.extendedtime) <
                                      0
                                  ? 0
                                  : (currentSeconds.toDouble() -
                                      room.extendedtime)
                              : 0,
                          center: new Text(
                            "Soul Session",
                            style: new TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16.0,
                                color: Colors.orange),
                          ),
                          circularStrokeCap: CircularStrokeCap.round,
                          backgroundColor: Colors.grey,
                          progressColor: checkLimitsColors(),
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
    if (room == null) return Colors.white;
    if (currentSeconds < room.time / 2) {
      return Colors.green;
    }
    if (currentSeconds > room.time / 2) {
      return Colors.amber;
    }
    if (room.time - currentSeconds < room.time / 3) {
      return Colors.red;
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
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              room == null ? "0:00" : timerText,
              style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                  fontSize: 40),
            ),
            Text(
              'Time used',
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
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

  onCallWidget() {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 30),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
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
              crossAxisAlignment: CrossAxisAlignment.start,
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
                Spacer(),
                InkWell(
                  onTap: () {
                    engine.startAudioRecording(
                        "/sdcard/" + room.roomid + ".mp3",
                        AudioSampleRateType.Type32000,
                        AudioRecordingQuality.Medium);
                    setState(() {
                      recording = !recording;
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
                          CupertinoIcons.mic_fill,
                          color:
                              recording == true ? Colors.green : Colors.white,
                        ),
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      Text('Record',
                          style: TextStyle(
                              color: recording == true
                                  ? Colors.green
                                  : Colors.white,
                              fontSize: 13)),
                    ],
                  ),
                ),
                Spacer(),
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
    return SliderButton(
      action: () async {
        try {
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
                    .createRoom(userData: user, title: user.username);
              }
            });
          }

          // setState(() {
          //   loading = false;
          // });
        } catch (e) {
          print("error " + e.toString());
        }
      },
      alignKnob: callwaiting == true || room != null && room.status == "active"
          ? Alignment.centerRight
          : Alignment.centerLeft,

      ///Put label over here
      label: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Text(
          callwaiting == true || room != null && room.status == "active"
              ? "Slide to end the call"
              : "Slide to start the Call",
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
        size: 30.0,
        semanticLabel: 'Text to announce in accessibility modes',
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

      buttonColor:
          callwaiting == true || room != null && room.status == "active"
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
