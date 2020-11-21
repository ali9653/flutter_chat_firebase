import 'dart:async';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:telegramchatapp/Widgets/ProgressWidget.dart';
import 'package:telegramchatapp/main.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class Settings extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: PreferredSize(
        preferredSize:
            Size.fromHeight(MediaQuery.of(context).size.height * 0.07),
        child: AppBar(
          brightness: Brightness.dark,
          backgroundColor: Colors.grey[900],
          elevation: 5,
          title: Text(
            "Account Settings",
            style: GoogleFonts.ptSansNarrow(
                fontSize: ScreenUtil().setSp(20),
                color: Colors.white,
                fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          automaticallyImplyLeading: false,
          actions: <Widget>[
            IconButton(
              onPressed: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => Settings()));
              },
              icon: Padding(
                padding: EdgeInsets.all(ScreenUtil().setSp(5)),
                child: Icon(
                  Icons.settings,
                  size: ScreenUtil().setSp(30),
                  color: Colors.white,
                ),
              ),
            )
          ],
        ),
      ),
      body: SettingsScreen(),
    );
  }
}

class SettingsScreen extends StatefulWidget {
  @override
  State createState() => SettingsScreenState();
}

class SettingsScreenState extends State<SettingsScreen> {
  TextEditingController _bio = TextEditingController();
  TextEditingController _nickname = TextEditingController();
  SharedPreferences preferences;
  String id = '';
  String nickname = '';
  String aboutMe = '';
  String photoUrl = '';
  File avatar;
  bool isLoading = false;
  final FocusNode nick = FocusNode();
  final FocusNode bioNode = FocusNode();

  void readLocal() async {
    preferences = await SharedPreferences.getInstance();

    setState(() {
      id = preferences.getString('id');
      nickname = preferences.getString('nickname');
      aboutMe = preferences.getString('aboutMe');
      photoUrl = preferences.getString('photoUrl');

      _bio = TextEditingController(text: aboutMe);
      _nickname = TextEditingController(text: nickname);
    });
  }

  Future getImage() async {
    File file = await ImagePicker.pickImage(source: ImageSource.gallery);
    if (file != null) {
      setState(() {
        this.avatar = file;
        isLoading = true;
      });
    }
    uploadImage();
  }

  Future uploadImage() async {
    String fileName = id;
    StorageReference storageReference =
        FirebaseStorage.instance.ref().child(fileName);
    StorageUploadTask storageUploadTask = storageReference.putFile(avatar);
    StorageTaskSnapshot storageTaskSnapshot;
    storageUploadTask.onComplete.then(
        (value) => {
              if (value.error == null)
                {
                  storageTaskSnapshot = value,
                  storageTaskSnapshot.ref.getDownloadURL().then(
                      (value) => {
                            photoUrl = value,
                            Firestore.instance
                                .collection('Users')
                                .document(id)
                                .updateData({
                              "photoUrl": photoUrl,
                              "aboutMe": aboutMe,
                              "nickname": nickname
                            }).then((value) async {
                              await preferences.setString('photoUrl', photoUrl);

                              setState(() {
                                isLoading = false;
                              });

                              Fluttertoast.showToast(msg: 'Image Updated');
                            }),
                          }, onError: (error) {
                    setState(() {
                      isLoading = false;
                    });
                    Fluttertoast.showToast(msg: 'Error during uploading');
                  }),
                }
            }, onError: (error) {
      setState(() {
        isLoading = false;
      });

      Fluttertoast.showToast(msg: error.toString());
    });
  }

  void updateData() {
    nick.unfocus();
    bioNode.unfocus();
    setState(() {
      isLoading = false;
    });

    Firestore.instance.collection('Users').document(id).updateData({
      "photoUrl": photoUrl,
      "aboutMe": aboutMe,
      "nickname": nickname
    }).then((value) async {
      await preferences.setString('photoUrl', photoUrl);
      await preferences.setString('aboutMe', aboutMe);
      await preferences.setString('nickname', nickname);

      setState(() {
        isLoading = false;
      });

      Fluttertoast.showToast(msg: 'Information Updated');
    });
  }

  void initState() {
    readLocal();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SingleChildScrollView(
          child: Column(
            children: [
              Container(
                child: Center(
                  child: Stack(
                    children: [
                      avatar == null
                          ? photoUrl != ""
                              ? Material(
                                  child: CachedNetworkImage(
                                    placeholder: (context, url) => Container(
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation(
                                            Colors.white),
                                      ),
                                      height: ScreenUtil().setSp(200),
                                      width: ScreenUtil().setSp(200),
                                      padding: EdgeInsets.all(
                                          ScreenUtil().setSp(20)),
                                    ),
                                    imageUrl: photoUrl,
                                    width: ScreenUtil().setSp(200),
                                    height: ScreenUtil().setSp(200),
                                    fit: BoxFit.cover,
                                  ),
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(120)),
                                  clipBehavior: Clip.hardEdge,
                                )
                              : Icon(
                                  Icons.account_circle,
                                  size: ScreenUtil().setSp(
                                    90,
                                  ),
                                  color: Colors.grey,
                                )
                          : Material(
                              child: Image.file(
                                avatar,
                                width: ScreenUtil().setSp(200),
                                height: ScreenUtil().setSp(200),
                                fit: BoxFit.cover,
                              ),
                              borderRadius:
                                  BorderRadius.all(Radius.circular(120)),
                              clipBehavior: Clip.hardEdge,
                            ),
                      IconButton(
                        onPressed: getImage,
                        iconSize: ScreenUtil().setSp(200),
                        splashColor: Colors.transparent,
                        highlightColor: Colors.grey,
                        icon: Icon(
                          Icons.camera_alt,
                          size: ScreenUtil().setSp(100),
                          color: Colors.white.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                width: double.infinity,
                margin: EdgeInsets.all(ScreenUtil().setSp(20)),
              ),
              Container(
                padding: EdgeInsets.all(ScreenUtil().setSp(12)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      child: Text(
                        'Name',
                        style: GoogleFonts.ptSansNarrow(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: ScreenUtil().setSp(22)),
                      ),
                    ),
                    SizedBox(
                      height: ScreenUtil().setSp(4),
                    ),
                    Container(
                      child: TextFormField(
                        onChanged: (value) {
                          nickname = value;
                        },
                        focusNode: nick,
                        style: GoogleFonts.ptSansNarrow(
                          color: Colors.white,
                          fontSize: ScreenUtil().setSp(17),
                        ),
                        controller: _nickname,
                        decoration: InputDecoration(
                            hintText: "e.g Ali",
                            hintStyle: TextStyle(color: Colors.white),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10.0),
                              borderSide: BorderSide(
                                color: Colors.white,
                                width: 0.8,
                              ),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(25.0),
                              borderSide: BorderSide(
                                color: Colors.white,
                                width: 0.8,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(25.0),
                              borderSide: BorderSide(
                                color: Colors.white,
                                width: 0.8,
                              ),
                            ),
                            suffixIcon: IconButton(
                              onPressed: () {
                                _nickname.clear();
                              },
                              icon: Icon(
                                Icons.clear,
                                color: Colors.white,
                                size: ScreenUtil().setSp(30),
                              ),
                            )),
                      ),
                    ),
                    SizedBox(
                      height: ScreenUtil().setSp(10),
                    ),
                    Container(
                      child: Text(
                        'About Me',
                        style: GoogleFonts.ptSansNarrow(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: ScreenUtil().setSp(22)),
                      ),
                    ),
                    SizedBox(
                      height: ScreenUtil().setSp(4),
                    ),
                    Container(
                      child: TextFormField(
                        onChanged: (value) {
                          aboutMe = value;
                        },
                        focusNode: bioNode,
                        style: GoogleFonts.ptSansNarrow(
                          color: Colors.white,
                          fontSize: ScreenUtil().setSp(17),
                        ),
                        controller: _bio,
                        decoration: InputDecoration(
                            hintText: "Bio goes here",
                            hintStyle: TextStyle(color: Colors.white),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10.0),
                              borderSide: BorderSide(
                                color: Colors.white,
                                width: 0.8,
                              ),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10.0),
                              borderSide: BorderSide(
                                color: Colors.white,
                                width: 0.8,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10.0),
                              borderSide: BorderSide(
                                color: Colors.white,
                                width: 0.8,
                              ),
                            ),
                            suffixIcon: IconButton(
                              onPressed: () {
                                _bio.clear();
                              },
                              icon: Icon(
                                Icons.clear,
                                color: Colors.white,
                                size: ScreenUtil().setSp(30),
                              ),
                            )),
                      ),
                    ),
                    SizedBox(
                      height: ScreenUtil().setSp(30),
                    ),
                    Container(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          RaisedButton.icon(
                            onPressed: () {
                              updateData();
                            },
                            icon: Icon(Icons.update),
                            label: Text(
                              'Update',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            color: Colors.white,
                          ),
                          RaisedButton.icon(
                            onPressed: () async {




                              final userRef =
                              Firestore.instance.collection('Users').document(id);

                              await userRef.updateData({"status": "offline",
                              "lastSeen": DateTime.now().millisecondsSinceEpoch.toString()});

                              final GoogleSignIn googleSignIn = GoogleSignIn();

                              await FirebaseAuth.instance.signOut();
                              await googleSignIn.disconnect();
                              await googleSignIn.signOut();

                              Navigator.of(context).pushAndRemoveUntil(
                                  MaterialPageRoute(
                                      builder: (context) => MyApp()),
                                  (Route<dynamic> route) => false);
                            },
                            icon: Icon(Icons.close),
                            label: Text(
                              'Logout',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            color: Colors.white,
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              )
            ],
          ),
        ),
      ],
    );
  }
}
