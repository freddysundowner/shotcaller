import 'package:shotcaller/models/user_model.dart';

class Room {
  final List<UserModel> users;
  final String roomid;
  final String owner;
  final bool usermuted;
  final bool adminmuted;
  final bool adminenabledspeaker;
  final bool userenabledspeaker;
  final String currentstatus;
  final int time;
  final int extendedtime;
  final String title;
  final String token;
  final String status;

  Room({
    this.token,
    this.usermuted,
    this.adminmuted,
    this.userenabledspeaker,
    this.adminenabledspeaker,
    this.currentstatus,
    this.extendedtime,
    this.owner,
    this.time,
    this.title,
    this.roomid,
    this.status,
    this.users,
  });


  factory Room.fromJson(doc) {
    var json  = doc.data();
    return Room(
      title: json['title'],
      usermuted: json['usermuted'] ?? false,
      adminmuted: json['adminmuted'] ?? false,
      userenabledspeaker: json['userenabledspeaker'] ?? true,
      adminenabledspeaker: json['adminenabledspeaker'] ?? true,
      currentstatus: json['currentstatus'],
      owner: json['owner'],
      time: json['time'],
      extendedtime: json['extendedtime'],
      token: json['token'],
      roomid: doc.id,
      status: json["status"],
      users: json['users'].map<UserModel>((user) {
        return UserModel.fromJson(user);
      }).toList(),
    );
  }
}
