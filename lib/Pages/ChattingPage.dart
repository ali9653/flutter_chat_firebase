import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:telegramchatapp/Widgets/FullImageWidget.dart';
import 'package:telegramchatapp/Widgets/ProgressWidget.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:telegramchatapp/Widgets/date_time.dart';

import '../Widgets/FullImageWidget.dart';
import '../Widgets/ProgressWidget.dart';
import 'AccountSettingsPage.dart';

// ignore: must_be_immutable
class Chat extends StatefulWidget {
  final String receiverID;
  final String receiverImage;
  final String receiverName;
  final String status;
  final String current;

  Chat(
      {Key key,
      this.receiverID,
      this.receiverImage,
      this.receiverName,
      this.status, this.current})
      : super(key: key);
  AppLifecycleState _notify;

  @override
  _ChatState createState() => _ChatState();
}

class _ChatState extends State<Chat> with WidgetsBindingObserver {

  static int _getNumberOfMonths(DateTime d1) {
    int _daysDifference = DateTime.now().difference(d1).inDays;
    return _daysDifference ~/ 30;
  }

  static int _getNumberOfYears(DateTime d1) {
    int _daysDifference = DateTime.now().difference(d1).inDays;
    return _daysDifference ~/ 365;
  }

  static String durationFromEvent(Timestamp timestampOfEvent) {
    DateTime _date =
    DateTime.fromMillisecondsSinceEpoch(timestampOfEvent.seconds * 1000);
    int _dateYearDifference = _getNumberOfYears(_date);
    int _dateMonthDifference = _getNumberOfMonths(_date);
    int _dateDaysDifference = DateTime.now().difference(_date).inDays;
    int _dateHoursDifference = DateTime.now().difference(_date).inHours;
    int _dateMinutesDifference = DateTime.now().difference(_date).inMinutes;
    if (_dateYearDifference <= 0 &&
        _dateMonthDifference <= 0 &&
        _dateDaysDifference <= 0 &&
        _dateHoursDifference <= 0 &&
        _dateMinutesDifference < 1) {
      return 'Just Now';
    } else if (_dateYearDifference <= 0 &&
        _dateMonthDifference <= 0 &&
        _dateDaysDifference <= 0 &&
        _dateHoursDifference < 1) {
      return '$_dateMinutesDifference mins ago';
    } else if (_dateYearDifference <= 0 &&
        _dateMonthDifference <= 0 &&
        _dateDaysDifference < 1) {
      return '$_dateHoursDifference hrs ago';
    } else if (_dateYearDifference <= 0 && _dateMonthDifference <= 0) {
      return '$_dateDaysDifference days ago';
    } else if (_dateYearDifference <= 0) {
      return '$_dateMonthDifference months ago';
    } else {
      return '$_dateYearDifference year ago';
    }
  }


  AppLifecycleState _notify;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    final userRef =
        Firestore.instance.collection('Users').document(widget.current);

    setState(() {
      _notify = state;
    });

    print("This Is the App state Right now" + state.toString());

    if (_notify.toString() == 'AppLifecycleState.inactive' ||
        _notify.toString() == 'AppLifecycleState.paused') {
      await userRef.updateData({"status": "offline", "lastSeen": DateTime.now().millisecondsSinceEpoch.toString()});
    }

    if (_notify.toString() == 'AppLifecycleState.resumed'
       ) {
      await userRef.updateData({"status": "online"});
    }

  }

  void initState() {
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
      iconTheme: IconThemeData(color: Colors.white),
      title: Column(
        children: [
          Text(
            widget.receiverName,
            style: GoogleFonts.ptSansNarrow(
                fontSize: ScreenUtil().setSp(24),
                color: Colors.white,
                fontWeight: FontWeight.bold),
          ),
          StreamBuilder(
            stream: Firestore.instance
                .collection('Users')
                .document(widget.receiverID)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {


                print("no data");
                return Container();
              } else {
                print("has data");
              return  Text(
               snapshot.data["status"] == "online" ?

               snapshot.data["status"] :
               "last seen " + ConvertDateTime.durationFromEvent( Timestamp.fromMillisecondsSinceEpoch(
                   int.parse(snapshot.data["lastSeen"]))),
                style: GoogleFonts.ptSansNarrow(
                    fontSize: ScreenUtil().setSp(18),
                    color: Colors.white,
                    fontWeight: FontWeight.normal),

                );
              }
            },
          ),

        ],
      ),
      centerTitle: true,
      automaticallyImplyLeading: false,
      actions: <Widget>[
        Padding(
          padding: EdgeInsets.only(right: 8.0, top: 10),
          child: InkWell(
            onTap: () {
              /*  Navigator.push(
                  context, MaterialPageRoute(builder: (context) => Settings()));*/
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
                backgroundImage: NetworkImage(widget.receiverImage),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomPadding: false,
      backgroundColor: Colors.black87,
      appBar: PreferredSize(
        preferredSize:
            Size.fromHeight(MediaQuery.of(context).size.height * 0.075),
        child: homePageHeader(),
      ),
      body: ChatScreen(
          receiverID: widget.receiverID, receiverImage: widget.receiverImage),
    );
  }
}

class ChatScreen extends StatefulWidget {
  final String receiverID;
  final String receiverImage;

  ChatScreen({Key key, this.receiverID, this.receiverImage}) : super(key: key);

  @override
  State createState() =>
      ChatScreenState(receiverID: receiverID, receiverImage: receiverImage);
}

class ChatScreenState extends State<ChatScreen> {
  final String receiverID;
  final String receiverImage;

  ChatScreenState({this.receiverID, this.receiverImage});

  final TextEditingController _textMessage = TextEditingController();
  final ScrollController listScrollController = ScrollController();
  var listMessage;
  final FocusNode focusNode = FocusNode();
  bool isSticker = false;
  bool isLoading = false;
  File imageFile;
  String imageUrl;
  String chatID = "";
  SharedPreferences sharedPreferences;
  String id;

  void initState() {
    focusNode.addListener(onFocusChange);
    super.initState();

    readLocal();
  }

  readLocal() async {
    sharedPreferences = await SharedPreferences.getInstance();
    setState(() {
      id = sharedPreferences.getString('id');
    });

    if (id.hashCode <= receiverID.hashCode) {
      setState(() {
        chatID = '$id-$receiverID';
      });
    } else {
      setState(() {
        chatID = '$receiverID-$id';
      });

      Firestore.instance
          .collection('Users')
          .document(id)
          .updateData({"chattingWith": receiverID});
    }
  }

  onFocusChange() {
    //hide sticker when using keyboard
    if (focusNode.hasFocus)
      setState(() {
        isSticker = false;
      });
  }

  void getSticker() {
    focusNode.unfocus();
    setState(() {
      isSticker = !isSticker;
    });
  }

  inputController() {
    return Container(
      child: Row(
        children: [
          Material(
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 1),
              child: IconButton(
                icon: Icon(Icons.image),
                color: Colors.white,
                onPressed: () {
                  getImage();
                },
              ),
            ),
            color: Colors.grey[900],
          ),
          Material(
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 1),
              child: IconButton(
                icon: Icon(Icons.face),
                color: Colors.white,
                onPressed: () {
                  getSticker();
                },
              ),
            ),
            color: Colors.grey[900],
          ),
          Flexible(
            child: Container(
              child: TextField(
                controller: _textMessage,
                focusNode: focusNode,
                decoration: InputDecoration.collapsed(
                    hintText: "Write here..",
                    hintStyle: TextStyle(color: Colors.white)),
                style:
                    GoogleFonts.ptSansNarrow(color: Colors.white, fontSize: 15),
              ),
            ),
          ),
          Material(
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 1),
              child: IconButton(
                icon: Icon(Icons.send),
                color: Colors.white,
                onPressed: () {
                  onMessageSend(_textMessage.text, 0);
                },
              ),
            ),
            color: Colors.grey[900],
          ),
        ],
      ),
      width: double.infinity,
      height: 55,
      decoration: BoxDecoration(
          border: Border(
              top: BorderSide(
            color: Colors.grey,
            width: 0.5,
          )),
          color: Colors.grey[900]),
    );
  }

  void onMessageSend(String msg, int type) {
    if (msg != "") {
      _textMessage.clear();
      var docRef = Firestore.instance
          .collection("Messages")
          .document(chatID)
          .collection('message')
          .document(DateTime.now().millisecondsSinceEpoch.toString());

      Firestore.instance.runTransaction((transaction) async {
        await transaction.set(
          docRef,
          {
            "idFrom": id,
            "idTo": receiverID,
            "time": DateTime.now().millisecondsSinceEpoch.toString(),
            "message": msg,
            "type": type
          },
        );
      });

      listScrollController.animateTo(0,
          duration: Duration(microseconds: 300), curve: Curves.easeOut);

      print('Success');
    } else {
      Fluttertoast.showToast(msg: "Please type something");
    }
  }

  createListMessages() {
    return Flexible(
      child: chatID == ""
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(Colors.white),
              ),
            )
          : StreamBuilder(
              stream: Firestore.instance
                  .collection('Messages')
                  .document(chatID)
                  .collection('message')
                  .orderBy("time", descending: true)
                  .limit(20)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  print("no data");
                  return Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  );
                } else {
                  print("has data");
                  listMessage = snapshot.data.documents;
                  return ListView.builder(
                    padding: EdgeInsets.all(10),
                    itemBuilder: (context, index) =>
                        createIndex(index, snapshot.data.documents[index]),
                    itemCount: snapshot.data.documents.length,
                    reverse: true,
                    controller: listScrollController,
                  );
                }
              },
            ),
    );
  }

  Widget createIndex(int index, DocumentSnapshot documentSnapshot) {
    if (documentSnapshot["idFrom"] == id) {
      return Column(
        children: [
          Row(
            children: [
              documentSnapshot["type"] == 0
                  ? Container(
                      height: 40,
                      child: FittedBox(
                        fit: BoxFit.contain,
                        child: Text(
                          documentSnapshot["message"],
                          style: GoogleFonts.ptSansNarrow(
                              color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                      padding: EdgeInsets.fromLTRB(10, 10, 10, 10),
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: BorderRadius.circular(15),
                      ),
                      margin: EdgeInsets.only(
                          bottom: isLastMsg(index) ? 5 : 5, right: 5),
                    )
                  : documentSnapshot["type"] == 1
                      ? Container(
                          child: FlatButton(
                            child: Material(
                                child: CachedNetworkImage(
                                  placeholder: (context, url) => Container(
                                    child: CircularProgressIndicator(
                                      valueColor:
                                          AlwaysStoppedAnimation(Colors.white),
                                    ),
                                    width: 200,
                                    height: 200,
                                    padding: EdgeInsets.all(70),
                                    decoration: BoxDecoration(
                                        color: Colors.grey[900],
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(8))),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      Material(
                                          child: Image.asset(
                                            "images/img_not_available.jpeg",
                                            width: 200,
                                            height: 200,
                                            fit: BoxFit.cover,
                                          ),
                                          clipBehavior: Clip.hardEdge,
                                          borderRadius: BorderRadius.all(
                                            Radius.circular(8),
                                          )),
                                  imageUrl: documentSnapshot["message"],
                                  height: 200,
                                  width: 200,
                                  fit: BoxFit.cover,
                                ),
                                clipBehavior: Clip.hardEdge,
                                borderRadius: BorderRadius.all(
                                  Radius.circular(8),
                                )),
                            onPressed: () {
                            /*  Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => FullPhoto(
                                          url: documentSnapshot["message"])));*/
                            },
                          ),
                          margin: EdgeInsets.only(
                              bottom: isLastMsg(index) ? 5 : 5, right: 5),
                        )
                      : Container(
                          child: Image.asset(
                            "images/${documentSnapshot['message']}.gif",
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          ),
                          margin: EdgeInsets.only(
                              bottom: isLastMsg(index) ? 5 : 5, right: 5),
                        ),
            ],
            mainAxisAlignment: MainAxisAlignment.end,
          ),
          Container(
            child: Text(
              DateFormat("dd MMM, yyyy hh:mm:aa").format(
                  DateTime.fromMillisecondsSinceEpoch(
                      int.parse(documentSnapshot["time"]))),
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontStyle: FontStyle.italic),
            ),
            margin: EdgeInsets.only(left: 5, bottom: 5),
          ),
        ],
        crossAxisAlignment: CrossAxisAlignment.end,
      );
    } else {
      return Container(
        child: Column(
          children: [
            Row(
              children: [
                documentSnapshot["type"] == 0
                    ? Container(
                        child: FittedBox(
                          fit: BoxFit.contain,
                          child: Text(
                            documentSnapshot["message"],
                            style: GoogleFonts.ptSansNarrow(
                                color: Colors.black87,
                                fontWeight: FontWeight.bold,
                                fontSize: 40),
                          ),
                        ),
                        padding: EdgeInsets.fromLTRB(10, 10, 10, 10),
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        margin: EdgeInsets.only(left: 5),
                      )
                    : documentSnapshot["type"] == 1
                        ? Container(
                            child: FlatButton(
                              child: Material(
                                  child: CachedNetworkImage(
                                    placeholder: (context, url) => Container(
                                      child: CircularProgressIndicator(
                                        valueColor: AlwaysStoppedAnimation(
                                            Colors.white),
                                      ),
                                      width: 200,
                                      height: 200,
                                      decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(8))),
                                    ),
                                    errorWidget: (context, url, error) =>
                                        Material(
                                            child: Image.asset(
                                              "images/img_not_available.jpeg",
                                              width: 200,
                                              height: 200,
                                              fit: BoxFit.cover,
                                            ),
                                            clipBehavior: Clip.hardEdge,
                                            borderRadius: BorderRadius.all(
                                              Radius.circular(8),
                                            )),
                                    imageUrl: documentSnapshot["message"],
                                    height: 200,
                                    width: 200,
                                    fit: BoxFit.cover,
                                  ),
                                  clipBehavior: Clip.hardEdge,
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(8),
                                  )),
                              onPressed: () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => FullPhoto(
                                            url: documentSnapshot["message"])));
                              },
                            ),
                          )
                        : Container(
                            child: Image.asset(
                              "images/${documentSnapshot['message']}.gif",
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                            ),
                          ),
              ],
            ),
            Container(
              child: Text(
                DateFormat("dd MMM, yyyy hh:mm:aa").format(
                    DateTime.fromMillisecondsSinceEpoch(
                        int.parse(documentSnapshot["time"]))),
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontStyle: FontStyle.italic),
              ),
              margin: EdgeInsets.only(left: 5, top: 5, bottom: 5),
            ),
          ],
          crossAxisAlignment: CrossAxisAlignment.start,
        ),
        margin: EdgeInsets.only(bottom: 10),
      );
    }
  }

  bool isLastMsg(int index) {
    if ((index > 0 &&
            listMessage != null &&
            listMessage[index - 1]["idFrom"] != id ||
        index == 0)) {
      return true;
    } else {
      return false;
    }
  }

  bool isLastMsgLeft(int index) {
    if ((index > 0 &&
            listMessage != null &&
            listMessage[index - 1]["idFrom"] == id ||
        index == 0)) {
      return true;
    } else {
      return false;
    }
  }

  Future getImage() async {
    imageFile = await ImagePicker.pickImage(source: ImageSource.gallery);
    if (imageFile != null) {
      isLoading = true;
    }
    uploadImage();
  }

  Future uploadImage() async {
    String filename = DateTime.now().millisecondsSinceEpoch.toString();
    StorageReference storageReference =
        FirebaseStorage.instance.ref().child("ChatImages").child(filename);

    StorageUploadTask storageUploadTask = storageReference.putFile(imageFile);
    StorageTaskSnapshot storageTaskSnapshot =
        await storageUploadTask.onComplete;

    storageTaskSnapshot.ref.getDownloadURL().then((downloadUrl) {
      imageUrl = downloadUrl;
      setState(() {
        isLoading = false;
        onMessageSend(imageUrl, 1);
      });
    }, onError: (error) {
      Fluttertoast.showToast(msg: error.toString());
    });
  }

  createStickers() {
    return Container(
      height: 250,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              FlatButton(
                onPressed: () {
                  onMessageSend("mimi1", 2);
                },
                child: Image.asset(
                  'images/mimi1.gif',
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                ),
              ),
              FlatButton(
                onPressed: () {
                  onMessageSend("mimi2", 2);
                },
                child: Image.asset(
                  'images/mimi2.gif',
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                ),
              ),
              FlatButton(
                onPressed: () {
                  onMessageSend("mimi3", 2);
                },
                child: Image.asset(
                  'images/mimi3.gif',
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              FlatButton(
                onPressed: () {
                  onMessageSend("mimi4", 2);
                },
                child: Image.asset(
                  'images/mimi4.gif',
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                ),
              ),
              FlatButton(
                onPressed: () {
                  onMessageSend("mimi5", 2);
                },
                child: Image.asset(
                  'images/mimi5.gif',
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                ),
              ),
              FlatButton(
                onPressed: () {
                  onMessageSend("mimi6", 2);
                },
                child: Image.asset(
                  'images/mimi6.gif',
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              FlatButton(
                onPressed: () {
                  onMessageSend("mimi1", 2);
                },
                child: Image.asset(
                  'images/mimi7.gif',
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                ),
              ),
              FlatButton(
                onPressed: () {
                  onMessageSend("mimi1", 2);
                },
                child: Image.asset(
                  'images/mimi8.gif',
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                ),
              ),
              FlatButton(
                onPressed: () {
                  onMessageSend("mimi1", 2);
                },
                child: Image.asset(
                  'images/mimi9.gif',
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                ),
              ),
            ],
          ),
        ],
      ),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey, width: 0.5)),
        color: Colors.grey[800],
      ),
      padding: EdgeInsets.all(5),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      child: Stack(
        children: <Widget>[
          Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              createListMessages(),
              isSticker ? createStickers() : Container(),
              inputController(),
            ],
          ),
          createLoading(),
        ],
      ),
      onWillPop: onBackPress,
    );
  }

  createLoading() {
    return Positioned(
      child: isLoading ? circularProgress() : Container(),
    );
  }

  Future<bool> onBackPress() {
    if (isSticker) {
      setState(() {
        isSticker = false;
      });
    } else {
      Navigator.pop(context);
    }

    return Future.value(false);
  }
}
