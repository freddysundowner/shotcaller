import 'package:flutter/material.dart';

Widget Loading(){
  return Center(
    child: Container(
      // width: 20,
      color: Colors.white,
      child: Center(
        child: CircularProgressIndicator(),
      ),
    ),
  );
}