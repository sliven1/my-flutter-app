import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:p7/pages/home_page.dart';
import 'package:p7/pages/register_profile_page.dart';
import 'package:p7/service/databases.dart';
import 'package:p7/service/login_or_register.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // Если пользователь залогинен
          if (snapshot.hasData) {
            final user = snapshot.data!;

            // Проверяем, заполнен ли профиль
            return FutureBuilder(
              future: Databases().getUserFromFirebase(user.uid),
              builder: (context, profileSnapshot) {
                // Пока загружается
                if (profileSnapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  );
                }

                // Если есть ошибка или профиль не найден
                if (profileSnapshot.hasError || !profileSnapshot.hasData || profileSnapshot.data == null) {
                  // Профиль не заполнен - отправляем на 2-й шаг регистрации
                  return RegisterProfilePage(
                    email: user.email ?? '',
                  );
                }

                // Профиль заполнен - идем на главную
                return const HomePage();
              },
            );
          }

          // Нет пользователя - показываем логин/регистрацию
          return const LoginOrRegister();
        },
      ),
    );
  }
}