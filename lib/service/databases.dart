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
    required String city,
    required String role,
  }) async {

    final uid = _auth.currentUser!.uid;

    final username = email.split("@")[0];

    // Собираем модель UserProfile с новыми полями
    final user = UserProfile(
      uid:      uid,
      name:     name,
      email:    email,
      username: username,
      birthDate: birthDate,
      city:     city,
      role:     role,
      bio:      '',
    );

    // Преобразуем в Map
    final userMap = user.toMap();

    // Сохраняем в коллекцию "Users"
    await _db.collection("Users").doc(uid).set(userMap);
  }

  Future<UserProfile?> getUserFromFirebase(String uid) async {
    try {
      final userDoc = await _db.collection("Users").doc(uid).get();
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

  // Новый метод для обновления профиля
  Future<void> updateUserProfile({
    String? name,
    String? city,
    String? role,
    String? bio,
  }) async {
    String uid = Auth().getCurrentUid();

    try {
      Map<String, dynamic> updates = {};

      if (name != null) updates['name'] = name;
      if (city != null) updates['city'] = city;
      if (role != null) updates['role'] = role;
      if (bio != null) updates['bio'] = bio;

      if (updates.isNotEmpty) {
        await _db.collection("Users").doc(uid).update(updates);
      }
    } catch (e) {
      print(e);
    }
  }
}