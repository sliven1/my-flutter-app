import 'package:flutter/material.dart';
import 'package:p7/models/user.dart';
import 'package:p7/service/databases.dart';

class DatabaseProvider extends ChangeNotifier{
  final _db = Databases();

  Future<UserProfile?> userProfile(String uid) => _db.getUserFromFirebase(uid);

  Future<void> updateBio(String bio){
    return _db.updateUserBio(bio);
  }

}