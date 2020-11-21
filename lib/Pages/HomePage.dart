import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:telegramchatapp/Pages/ChattingPage.dart';
import 'package:telegramchatapp/models/user.dart';
import 'package:telegramchatapp/Pages/AccountSettingsPage.dart';
import 'package:telegramchatapp/Widgets/ProgressWidget.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../Widgets/ProgressWidget.dart';
import '../main.dart';
import 'ChattingPage.dart';

class HomeScreen extends StatefulWidget {
  final String currentUserID;

  const HomeScreen({Key key, this.currentUserID}) : super(key: key);

  @override
  State createState() => HomeScreenState(currentUserID: currentUserID);
}

class HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {








  SharedPreferences preferences;
  String id = '';
  String nickname = '';
  String aboutMe = '';
  String photoUrl = '';
  String status ='';

  void readLocal() async {
    preferences = await SharedPreferences.getInstance();

    setState(() {
      id = preferences.getString('id');
      status = preferences.getString('status');
      nickname = preferences.getString('nickname');
      aboutMe = preferences.getString('aboutMe');
      photoUrl = preferences.getString('photoUrl');
    });
  }

  final String currentUserID;

  HomeScreenState({this.currentUserID});

  TextEditingController _search = TextEditingController();
  Future<QuerySnapshot> searchResults;

  AppLifecycleState _notify;


  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    final userRef =
    Firestore.instance.collection('Users').document(widget.currentUserID);

    setState(() {
      _notify = state;
    });

    print("This Is the App state Right now" + state.toString());

    if (_notify.toString() == 'AppLifecycleState.inactive' ||
        _notify.toString() == 'AppLifecycleState.paused') {
      await userRef.updateData({"status": "offline",
        "lastSeen": DateTime.now().millisecondsSinceEpoch.toString()});
    }

    if (_notify.toString() == 'AppLifecycleState.resumed'
    ) {
      await userRef.updateData({"status": "online"});
    }

  }


  void initState() {
    readLocal();
    WidgetsBinding.instance.addObserver(this);
    super.initState();
  }


  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    super.dispose();
  }

  homePageHeader() {
    return AppBar(
      brightness: Brightness.dark,
      backgroundColor: Colors.grey[900],
      elevation: 5,
      title: Text(
        "Home",
        style: GoogleFonts.ptSansNarrow(
            fontSize: ScreenUtil().setSp(24),
            color: Colors.white,
            fontWeight: FontWeight.bold),
      ),
      centerTitle: true,
      automaticallyImplyLeading: false,
      actions: <Widget>[
        Padding(
          padding: EdgeInsets.only(right: 8.0, top: 10),
          child: InkWell(
            onTap: () {
              Navigator.push(
                  context, MaterialPageRoute(builder: (context) => Settings()));
            },
            child: Container(
              decoration: new BoxDecoration(
                shape: BoxShape.circle,
                border: new Border.all(
                  color: Colors.white,
                  width: 1,
                ),
              ),
              child: CircleAvatar(
                radius: 22,
                backgroundColor: Colors.grey[900],
                backgroundImage: NetworkImage(photoUrl),
              ),
            ),
          ),
        ),
      ],
    );
  }

  final GoogleSignIn googleSignIn = GoogleSignIn();

  Future logoutUser() async {
    await FirebaseAuth.instance.signOut();
    await googleSignIn.disconnect();
    await googleSignIn.signOut();

    Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => MyApp()),
        (Route<dynamic> route) => false);
  }

  controlSearching(String username) {
    Future<QuerySnapshot> allFoundUsers = Firestore.instance
        .collection('Users')
        .where("nickname", isGreaterThanOrEqualTo: username)
        .getDocuments();

    setState(() {
      searchResults = allFoundUsers;
    });
  }

  results() {
    return FutureBuilder(
        future: searchResults,
        // ignore: missing_return
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData) {
            return circularProgress();
          }

          List<UserResult> searchUserResult = [];
          snapshot.data.documents.forEach((doc) {
            User eachUser = User.fromDocument(doc);
            UserResult userResult = UserResult(eachUser: eachUser,current: currentUserID,);

            if (widget.currentUserID != doc["id"]) {
              searchUserResult.add(userResult);
            }
          });
          return Container(
              height: MediaQuery.of(context).size.height * 0.7,
              child: ListView(children: searchUserResult));
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomPadding: false,
      backgroundColor: Colors.black87,
      appBar: PreferredSize(
          preferredSize:
              Size.fromHeight(MediaQuery.of(context).size.height * 0.075),
          child: homePageHeader()),
      body: Padding(
        padding: EdgeInsets.all(8.0),
        child: Container(
          child: Column(
            children: [
              Container(
                color: Colors.grey[850],
                margin: EdgeInsets.only(top: ScreenUtil().setSp(15)),
                child: TextFormField(
                  style: GoogleFonts.ptSansNarrow(
                    color: Colors.white,
                    fontSize: ScreenUtil().setSp(17),
                  ),
                  controller: _search,
                  decoration: InputDecoration(
                      hintText: " Search Here...",
                      hintStyle: TextStyle(color: Colors.white),
                      border: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      prefixIcon: Icon(
                        Icons.person_pin,
                        color: Colors.white,
                        size: ScreenUtil().setSp(30),
                      ),
                      suffixIcon: IconButton(
                        onPressed: () {
                          _search.clear();
                        },
                        icon: Icon(
                          Icons.clear,
                          color: Colors.white,
                          size: ScreenUtil().setSp(30),
                        ),
                      )),
                  onFieldSubmitted: controlSearching,
                ),
              ),
              searchResults == null ? noResults() : results(),
            ],
          ),
        ),
      ),
    );
  }

  noResults() {
    final Orientation orientation = MediaQuery.of(context).orientation;
    return Container(
      child: Center(
        child: ListView(
          shrinkWrap: true,
          children: [
            Icon(
              Icons.group,
              color: Colors.white,
              size: ScreenUtil().setSp(200),
            ),
            Text(
              "Search Users",
              textAlign: TextAlign.center,
              style: GoogleFonts.ptSansNarrow(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: ScreenUtil().setSp(50)),
            )
          ],
        ),
      ),
    );
  }
}

class UserResult extends StatelessWidget {
  final User eachUser;
  final String current;

  const UserResult({Key key, this.eachUser, this.current}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            height: ScreenUtil().setSp(10),
          ),
          GestureDetector(

            onTap: () {
              
              sendUserToChat(context);
            },
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              color: Colors.black87,
              elevation: 3,
              child: Padding(
                padding: EdgeInsets.all(ScreenUtil().setSp(2)),
                child: ListTile(
                  leading: Container(
                    decoration: new BoxDecoration(
                      shape: BoxShape.circle,
                      border: new Border.all(
                        color: Colors.white,
                        width: 1,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 27,
                      backgroundColor: Colors.black87,
                      backgroundImage:
                          CachedNetworkImageProvider(eachUser.photoUrl),
                    ),
                  ),
                  title: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        eachUser.nickname,
                        style: GoogleFonts.ptSansNarrow(
                            fontSize: ScreenUtil().setSp(16),
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),


                    ],
                  ),
                  subtitle: Text(
                    'Joined: ' +
                        DateFormat('yMMMMEEEEd').format(
                            DateTime.fromMillisecondsSinceEpoch(
                                int.parse(eachUser.createdAt))),
                    style: GoogleFonts.ptSansNarrow(
                        fontSize: ScreenUtil().setSp(16),
                        fontWeight: FontWeight.normal,
                        color: Colors.white),
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  sendUserToChat(BuildContext context) {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => Chat(
              status: eachUser.status,
                current: current,
                receiverID: eachUser.id,
                receiverImage: eachUser.photoUrl,
                receiverName: eachUser.nickname)));
  }
}
