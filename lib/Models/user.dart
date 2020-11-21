import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String id;
  final String aboutMe;
  final String nickname;
  final String photoUrl;
  final String createdAt;
  final String status;
  final String lastSeen;

  User({
    this.status, this.lastSeen,
    this.id,
    this.aboutMe,
    this.nickname,
    this.photoUrl,
    this.createdAt,
  });

  factory User.fromDocument(DocumentSnapshot doc) {
    return User(
      status : doc["status"],
      lastSeen: doc["lastSeen"],
      id: doc.documentID,
      aboutMe: doc['aboutMe'],
      photoUrl: doc['photoUrl'],
      nickname: doc['nickname'],
      createdAt: doc['createdAt'],
    );
  }
}