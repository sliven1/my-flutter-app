import 'package:firebase_auth/firebase_auth.dart';

Future<void> changePassword({
  required String currentPassword,
  required String newPassword,
}) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) throw Exception('Not logged in');

  // 1) Реаутентифицируем
  final cred = EmailAuthProvider.credential(
    email: user.email!,
    password: currentPassword,
  );
  await user.reauthenticateWithCredential(cred);

  // 2) Меняем пароль
  await user.updatePassword(newPassword);
}