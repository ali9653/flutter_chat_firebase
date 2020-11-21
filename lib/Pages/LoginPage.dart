import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:telegramchatapp/Pages/HomePage.dart';
import 'package:telegramchatapp/Widgets/ProgressWidget.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'HomePage.dart';
import 'HomePage.dart';
import 'HomePage.dart';

class LoginScreen extends StatefulWidget {
  LoginScreen({Key key}) : super(key: key);

  @override
  LoginScreenState createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen> {
  Future google() async {
    sharedPreferences = await SharedPreferences.getInstance();
    GoogleSignInAccount googleUser = await googleSignIn.signIn();
    GoogleSignInAuthentication googleAuthentication =
        await googleUser.authentication;
    final AuthCredential credential = GoogleAuthProvider.getCredential(
        idToken: googleAuthentication.idToken,
        accessToken: googleAuthentication.accessToken);
    FirebaseUser firebaseUser =
        (await firebaseAuth.signInWithCredential(credential)).user;
    if (firebaseUser != null) {
      final QuerySnapshot res = await Firestore.instance
          .collection('Users')
          .where('id', isEqualTo: firebaseUser.uid)
          .getDocuments();
      final List<DocumentSnapshot> documentSnapshots = res.documents;
      if (documentSnapshots.length == 0) {
        Firestore.instance
            .collection('Users')
            .document(firebaseUser.uid)
            .setData({
          "nickname": firebaseUser.displayName,
          "photoUrl": firebaseUser.photoUrl,
          "id": firebaseUser.uid,
          "aboutMe": "I love travelling and reading books",
          "createdAt": DateTime.now().millisecondsSinceEpoch.toString(),
          "chatWith": null,
          "status": "online",
          "lastSeen": "",


        });

        currentUser = firebaseUser;
          await sharedPreferences.setString("id", currentUser.uid);
          await sharedPreferences.setString("nickname", currentUser.displayName);
          await sharedPreferences.setString("photoUrl", currentUser.photoUrl);



      } else {
        currentUser = firebaseUser;
        await sharedPreferences.setString("id", documentSnapshots[0]["id"]);
        await sharedPreferences.setString("nickname", documentSnapshots[0]["nickname"]);
        await sharedPreferences.setString("photoUrl", documentSnapshots[0]["photoUrl"]);
        await sharedPreferences.setString("aboutMe", documentSnapshots[0]["aboutMe"]);
        await sharedPreferences.setString("status", documentSnapshots[0]["status"]);


      }


      final userRef =
      Firestore.instance.collection('Users').document(sharedPreferences.get('id'));

      await userRef.updateData({"status": "online"});

      Fluttertoast.showToast(msg: "Sign in Successful!");
      setState(() {
        isLoading = false;
      });
      Navigator.push(context, MaterialPageRoute(builder: (context) => HomeScreen(currentUserID: firebaseUser.uid,)));

      print('Successful');
    } else {
      print('Failed');
      Fluttertoast.showToast(msg: "Sign in failed, please try again");
      setState(() {
        isLoading = false;
      });
    }

    setState(() {
      isLoading = true;
    });
  }

  final GoogleSignIn googleSignIn = GoogleSignIn();
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
  SharedPreferences sharedPreferences;
  bool isLoggedIn = false;
  bool isLoading = false;
  FirebaseUser currentUser;


isSignedIn () async{
  setState(() {
    isLoggedIn = true;
  });

  sharedPreferences = await SharedPreferences.getInstance();
  isLoggedIn =  await googleSignIn.isSignedIn();
  if (isLoggedIn == true) {


    Navigator.push(context,
        MaterialPageRoute(builder: (context) {
          return HomeScreen(currentUserID: sharedPreferences.get('id'),

          );
        }));


  }
  setState(() {
    isLoading = false;
  });

}

  void initState () {
    isSignedIn ();

    super.initState();
  }


  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
        SystemUiOverlayStyle(statusBarColor: Colors.grey[900]));

    ScreenUtil.init(context,
        designSize: Size(MediaQuery.of(context).size.width,
            MediaQuery.of(context).size.height),
        allowFontScaling: false);
    return Scaffold(
      backgroundColor: Colors.grey[900],
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Container(
          child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Container(
                  child: Align(
                    alignment: Alignment.center,
                    child: Row(mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Flutter',
                          style: GoogleFonts.righteous(
                            color: Colors.white,
                            fontSize: ScreenUtil().setSp(60),
                          ),
                        ), Text(
                          'Chat',
                          style: GoogleFonts.righteous(
                            color: Colors.blue[600],
                            fontSize: ScreenUtil().setSp(60),
                          ),
                        ),

                      ],
                    ),
                  ),
                ),
                SizedBox(
                  height: ScreenUtil().setSp(5),
                ),
                GestureDetector(
                  onTap: () async {

                    google();

                   /* final userRef =
                    Firestore.instance.collection('Users').document(sharedPreferences.get('id'));

                    await userRef.updateData({"status": "online"});*/

                  },
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.55,
                    height: MediaQuery.of(context).size.height * 0.06,
                    decoration: BoxDecoration(
                        color: Colors.grey[900],
                        image: DecorationImage(
                            image: AssetImage(
                                "assets/images/google_signin_button.png"),
                            fit: BoxFit.cover)),
                  ),
                ),
                Padding(
                  child: isLoading ? circularProgress() : Container(),
                  padding: EdgeInsets.all(ScreenUtil().setSp(2)),
                )
              ]),
        ),
      ),
    );
  }
}
