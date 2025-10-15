import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:p7/models/user.dart';
import 'package:p7/service/auth.dart';

class Databases{
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;


  Future<void> saveInfoInFirebase({
    required String name,
    required String email,
    required DateTime birthDate,
  }) async {

    final uid = _auth.currentUser!.uid;


    final username = email.split("@")[0];

    // Собираем модель UserProfile
    final user = UserProfile(
      uid:      uid,
      name:     name,
      email:    email,
      username: username,
      birthDate: birthDate,
      bio:      '',
    );

    // 4) Преобразуем её в Map
    final userMap = user.toMap();

    // 5) Сохраняем в коллекцию "Users", документ с ID = uid
    await _db.collection("Users").doc(uid).set(userMap);
  }

  Future<UserProfile?> getUserFromFirebase(String uid) async {
    try {
      // 1) Получаем документ по пути User/{uid}
      final userDoc = await _db.collection("Users").doc(uid).get();

      // 2) Превращаем его в объект-модель
      return UserProfile.fromDocument(userDoc);
    } catch (e) {
      print(e);
      return null;
    }
  }

  Future<void> updateUserBio(String bio) async{
    String uid = Auth().getCurrentUid();

    try{
      await _db.collection("Users").doc(uid).update({'bio':bio});
    }
    catch(e){
      print(e);
    }
  }
}