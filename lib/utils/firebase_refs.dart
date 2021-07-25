
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

final _firestore =  FirebaseFirestore.instance;
final chatsRef = _firestore.collection('chats');
final usersRef = _firestore.collection('users');
final roomsRef = _firestore.collection('rooms');
final settingsRef = _firestore.collection('settings');
final upcomingroomsRef = _firestore.collection('upcomingrooms');
final interestsRef = _firestore.collection('interests');

FirebaseMessaging firebaseMessaging = FirebaseMessaging.instance;