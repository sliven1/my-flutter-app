import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:p7/models/messenge.dart';


class ChatService extends ChangeNotifier{
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<Map<String, dynamic>>> getUserStream() {
    return _firestore.collection('Users').snapshots().map((snapshot) {
      return snapshot.docs
          .where((doc) => doc.data()['uid'] != _auth.currentUser!.uid)
          .map((doc) => doc.data())
          .toList();
    });
  }

  Stream<List<Map<String, dynamic>>> getUsersStreamExcludingBlocked(){
    final currentUser = _auth.currentUser;
    return _firestore.collection('Users').doc(currentUser!.uid).collection('BlockedUser')
        .snapshots().asyncMap((snapshot) async {
          final blockedUserIDS = snapshot.docs.map((doc) => doc.id).toList();

          final usersSnapshot = await _firestore.collection('Users').get();

          return usersSnapshot.docs.where((doc) => doc.data()['uid'] != currentUser.uid &&
              !blockedUserIDS.contains(doc.id))
              .map((doc) => doc.data()).toList();
    });
  }

  Future<void> sendMessageWithImage({
    required String receiverId,
    required String imageUrl,
  }) async {
    final user = _auth.currentUser!;
    final ids = [user.uid, receiverId];
    ids.sort();
    final chatRoomId = ids.join('_');

    final msg = Message(
      senderID: user.uid,
      senderEmail: user.email ?? '',
      receiverID: receiverId,
      message: imageUrl,
      timestamp: Timestamp.now(),
      type: 'image',
    );

    await FirebaseFirestore.instance
        .collection('chat_room')
        .doc(chatRoomId)
        .collection('messages')
        .add(msg.toMap());
  }



  Future<void> sendMessageWithAudio({
    required String receiverId,
    required String audioUrl,
  }) async {
    final user = _auth.currentUser!;
    final ids = [user.uid, receiverId]..sort();
    final chatRoomId = ids.join('_');

    final msg = Message(
      senderID: user.uid,
      senderEmail: user.email ?? '',
      receiverID: receiverId,
      message: audioUrl,
      timestamp: Timestamp.now(),
      type: 'audio',
    );

    await FirebaseFirestore.instance
        .collection('chat_room')
        .doc(chatRoomId)
        .collection('messages')
        .add(msg.toMap());
  }


  Future<void> sendMessage(String receiverID, String message, {String type = 'text'}) async {
    final String currentUserId = _auth.currentUser!.uid;
    final String currentUserEmail = _auth.currentUser!.email ?? '';
    final Timestamp timestamp = Timestamp.now();

    Message newMessage = Message(
      senderID: currentUserId,
      senderEmail: currentUserEmail,
      receiverID: receiverID,
      message: message,
      timestamp: timestamp,
      type: type, // Добавляем тип сообщения
    );

    List<String> ids = [currentUserId, receiverID];
    ids.sort();
    String chatRoomId = ids.join('_');

    await _firestore.collection("chat_room")
        .doc(chatRoomId)
        .collection("messages")
        .add({
      ...newMessage.toMap(),
      'isRead': false,
    });
  }

  Stream<QuerySnapshot> getMessage(String userId, otherUserId){

    List<String> ids = [userId, otherUserId];
    ids.sort();
    String ChatRoomId = ids.join('_');

    return _firestore.collection("chat_room").doc(ChatRoomId).
    collection("messages").orderBy("timestamp", descending: false).snapshots();
  }

  Future<Map<String, dynamic>?> getLastMessage(String userID1, String userID2) async {
    try{
      List<String> ids = [userID1, userID2];
      ids.sort();
      String chatRoomID = ids.join('_');

      final snapshot = await _firestore
          .collection("chat_room")
          .doc(chatRoomID)
          .collection("messages")
          .orderBy("timestamp", descending: true)
          .limit(1)
          .get();
      if (snapshot.docs.isEmpty) return null;

      final doc = snapshot.docs.first;
      final data = doc.data();

       return {
         'message': data['message']??'',
         'timestamp': (data['timestamp'] as Timestamp).toDate(),
         'senderID': data['senderID']??'',
       };
    }catch(e){
      print('Ошибка сообщение не найдено: $e');
      return null;
    }
  }

  Future<int> getUnreadCount(String userID1, String userID2) async{
    try{
      List<String> ids = [userID1,userID2];
      ids.sort();
      String chatRoomID = ids.join("_");

      final snapshot = await _firestore
          .collection("chat_room")
          .doc(chatRoomID)
          .collection("message")
          .where("senderID", isEqualTo: userID2)
          .where("isRead", isEqualTo: false)
          .get();
      return snapshot.docs.length;
    }catch (e) {
      print('Ошибка получения не прочитанных сообщений $e');
      return 0;
    }
  }

  Future<void> markMessagesAsRead(String userID1, String userID2) async {
    try{
      List<String> ids = [userID1, userID1];
      ids.sort();
      String chatRoomID = ids.join("_");

      final snapshot = await _firestore
          .collection("chat_room")
          .doc(chatRoomID)
          .collection("message")
          .where("senderID", isEqualTo: userID2)
          .where("idRead", isEqualTo: false)
          .get();
      for (var doc in snapshot.docs){
        await doc.reference.update({'isRead':true});
      }
    }catch(e){
      print('Ошибка с маркером не прочитонных сообщений: $e');
    }
  }

  Future<void> reportUser(String messageID, String userID) async {
    final currentUser = _auth.currentUser;
    final report = {
      'reportedBy' : currentUser!.uid,
      'messageID' : messageID,
      'messageOwnerId': userID,
      'timestamp' : FieldValue.serverTimestamp(),
    };
    await _firestore.collection('Reports').add(report);

  }

  Future<void> blockUser (String userID) async {
    final currentUser = _auth.currentUser;
    await _firestore.collection('Users').
    doc(currentUser!.uid).collection('BlockedUser').doc(userID).set({});
    notifyListeners();
  }

  Future<void> unblockUser (String blockedUserID) async {
    final currentUser = _auth.currentUser;
    await _firestore.collection('Users').
    doc(currentUser!.uid).collection('BlockedUser').doc(blockedUserID).delete();
    notifyListeners();
  }

  Stream<List<Map<String, dynamic>>> getBlockedUsersStream(String userID){

    return _firestore.collection('Users').doc(userID)
        .collection('BlockedUser').snapshots().asyncMap((snapshot) async {
          final blockedUserIDS = snapshot.docs.map((doc) => doc.id).toList();

          final usersDocs = await Future.wait(
            blockedUserIDS.map((id) => _firestore.collection('Users').doc(id).get()));

          return usersDocs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    });

  }

}