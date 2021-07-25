import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shotcaller/controllers/controllers.dart';
import 'package:shotcaller/services/database.dart';
import 'package:shotcaller/shared/colors.dart';
import 'package:shotcaller/widgets/loading.dart';
import 'package:shotcaller/widgets/round_button.dart';

class PickPhotoPage extends StatefulWidget {


  @override
  _PickPhotoPageState createState() => _PickPhotoPageState();
}

class _PickPhotoPageState extends State<PickPhotoPage> {
  final picker = ImagePicker();
  bool loading = false;
  File _imageFile;

  String error = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeColor1,
      body: SafeArea(
        child: loading == true ? Loading() :Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.only(
            top: 30,
            bottom: 60,
          ),
          child: Column(
            children: [
              buildTitle(),
              Spacer(
                flex: 1,
              ),
              buildContents(),
              SizedBox(height: 30,),
              if(error.isNotEmpty) Text(error, style: TextStyle(color: Colors.red),),
              Spacer(
                flex: 3,
              ),
              buildBottom(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildActionButton(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
      ),
      child: GestureDetector(
        onTap: () {

        },
        child: Text(
          'Skip',
          style: TextStyle(
            color: Colors.grey,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget buildTitle() {
    return Text(
      'Add your photo?',
      style: TextStyle(
        fontSize: 25,
        color: Colors.white
      ),
    );
  }

  Widget buildContents() {
    return InkWell(
      onTap: () {
        _getFromGallery();
      },
      child: Container(
        width: 200,
        height: 200,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(80),
        ),
        child: _imageFile !=null ? Container(
              child: ClipOval(
                child: Image.file(
                  _imageFile,
                  height: 200,
                  width: 200,
                  fit: BoxFit.cover,
                ),
              ),
            ) : Icon(
          Icons.add_photo_alternate_outlined,
          size: 100,
          color: Colors.blue,
        ),
      ),
    );
  }

  Widget buildBottom(BuildContext context) {
    return CustomButton(
      color: Colors.red,
      minimumWidth: 230,
      disabledColor: Colors.blue.withOpacity(0.3),
      onPressed: loading == true ? null : () async{
        setState(() {
          error = "";
          loading = true;
        });
        if(_imageFile  ==null){
          setState(() {
            error = "upload image first";
          });
        }else{
          await Database().createUserInfo(FirebaseAuth.instance.currentUser.uid);
        }


        setState(() {
          loading = false;
        });
      },
      child: Container(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              loading == true ? "Please wait " : 'Next',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
              ),
            ),
            Icon(
              Icons.arrow_right_alt,
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }

  _getFromGallery() async {
    PickedFile pickedFile = await picker.getImage(
      source: ImageSource.gallery,
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
      setState(() {});
    }
  }
}
