

import 'package:flutter/material.dart';
import 'package:shotcaller/models/room.dart';

checkLimitsColors(Room activeroom, int currentSeconds) {
  if(activeroom !=null){
    if(double.parse(((currentSeconds / activeroom.time) * 100).toStringAsFixed(2)) <=  33.33){
      return Colors.green;
    }

    if(double.parse(((currentSeconds / activeroom.time) * 100).toStringAsFixed(2)) <= 66.66){
      return Colors.amber;
    }

    if(double.parse(((currentSeconds / activeroom.time) * 100).toStringAsFixed(2)) <= 99.99){
      return Colors.red;
    }
  }
  return Colors.white;
}