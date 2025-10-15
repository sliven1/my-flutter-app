import 'package:firebase_auth/firebase_auth.dart';


class Auth{
  final _auth = FirebaseAuth.instance;

  User? getCurrentUser() => _auth.currentUser;
  String getCurrentUid() => _auth.currentUser!.uid;

  // login
  Future<UserCredential> loginEmailPassword(String email, password) async {
    try{
      final userCredital = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password
      );
      return userCredital;
    }
    on FirebaseAuthException catch(e){
      throw Exception(e.code);
    }
  }

  //register
  Future<UserCredential> registerEmailPassword(String email, password) async {

    try{
      UserCredential userCredital = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password
      );
      return userCredital;
    }
    on FirebaseAuthException catch(e){
      throw Exception(e.code);
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'no-current-user',
        message: 'No user is currently signed in.',
      );
    }

    // 1) Реаутентифицируем заново
    final cred = EmailAuthProvider.credential(
      email: user.email!,
      password: currentPassword,
    );
    await user.reauthenticateWithCredential(cred);

    // 2) Меняем пароль
    await user.updatePassword(newPassword);
  }



  // logout

  Future<void> logout() async{
    await _auth.signOut();
  }

}