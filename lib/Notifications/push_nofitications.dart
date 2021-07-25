import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart';
import 'package:http/http.dart' as http;
import 'package:shotcaller/shared/configs.dart';

class PushNotificationsManager {

  PushNotificationsManager._();

  factory PushNotificationsManager() => _instance;

  static final PushNotificationsManager _instance = PushNotificationsManager._();

  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin=new FlutterLocalNotificationsPlugin();

  static Future<bool> sendFcmMessageToTopic({String title, String message, String topic}) async {
    try {
      var url = Uri.parse('https://fcm.googleapis.com/fcm/send');
      var header = {
        "Content-Type": "application/json",
        "Authorization": serverToken
      };
      final request = {
        "collapse_key" : "type_a",
        "notification" : {
          "title": title,
          "body" : message,
          "sound": "default",
        },
        "priority": "high",
        "data": {
          "click_action": "FLUTTER_NOTIFICATION_CLICK",
          "sound": "default",
          "status": "done",
          "screen": "screenA",
        },
        "click_action": "FLUTTER_NOTIFICATION_CLICK",
        "to": "/topics/${topic}",
      };
      var client = new Client();
      var response = await client.post(
          url,
          encoding: Encoding.getByName('utf-8'),
          body: json.encode(request),
          headers: header
      );
      if (response.statusCode == 200) {
        // on success do sth
        print('test ok topic push CFM');
        return true;
      } else {
        print(' CFM error '+response.body.toString());
        // on failure do sth
        return false;
      }
      print("notification success "+request.toString());
      return true;
    } catch (e, s) {
      print("notification error "+e);
      return false;
    }
  }
  static Future<bool> callOnFcmApiSendPushNotifications({List <String> userToken, String title, String msg}) async {

    final postUrl = Uri.parse('https://fcm.googleapis.com/fcm/send');
    final data = {
      "registration_ids" : userToken,
      "collapse_key" : "type_a",
      // "notification" : "",
      "notification" : {
        "title": title,
        "body" : msg,
      },
      "priority": "high",
      "data": {
        "click_action": "FLUTTER_NOTIFICATION_CLICK",
        "sound": "default",
        "status": "done",
        "screen": "screenA",
      },
      "click_action": "FLUTTER_NOTIFICATION_CLICK"
    };

    final headers = {
      "Content-Type": "application/json",
      'Authorization': serverToken,
    };

    final response = await http.post(postUrl,
        body: json.encode(data),
        encoding: Encoding.getByName('utf-8'),
        headers: headers);
    print("rsponse "+response.body.toString());
    if (response.statusCode == 200) {
      // on success do sth
      print('test ok push CFM');
      return true;
    } else {
      print(' CFM error '+response.body.toString());
      // on failure do sth
      return false;
    }
  }
}