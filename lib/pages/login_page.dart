import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:p7/components/my_button.dart';
import 'package:p7/components/my_text_field.dart';
import 'package:p7/service/auth.dart';

import '../components/load_animation.dart';
class LoginPage extends StatefulWidget {
  final void Function()? onTap;


  const LoginPage({super.key, required this.onTap});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {

  final _auth = Auth();

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  void login() async {
    // Показываем индикатор
    showLoad(context);

    try {
      // Ждём ответ от Firebase
      await _auth.loginEmailPassword(
        emailController.text,
        passwordController.text,
      );
      // тут можно обработать успешный вход, если нужно
    } on FirebaseAuthException catch (e) {
      // обработка ошибки (например, SnackBar)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: ${e.message ?? e.code}')),
      );
    } catch (e) {
      // любая другая ошибка
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Что-то пошло не так')),
      );
    } finally {
      // Скрываем индикатор всегда, даже если упало в catch
      if (mounted) hideLoad(context);
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor: Theme.of(context).colorScheme.surface,

      body: SafeArea(
        child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 50),
              Icon(
                Icons.lock,
                size: 72,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 50),
              Text("Join us! Sign up to get started.",
              style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
                fontSize: 18,
              ),
              ),
              const SizedBox(height: 50),

              MyTextField(
                  textEditingController: emailController,
                  obscureText: false,
                  hintText: "Enter email",
              ),

              const SizedBox(height: 10),

              MyTextField(
                textEditingController: passwordController,
                obscureText: true,
                hintText: "Enter password",
              ),

              const SizedBox(height: 10),

              Align(
                child: Text("Forgot Password?", style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 25),

              MyButton(
                  onTap: login,
                  text: "Login"),

              const SizedBox(height: 50),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Not a member?", style: TextStyle(color: Theme.of(context).colorScheme.primary),),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: widget.onTap,
                    child: Text("Register now",  style: TextStyle(color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold)
                    ),

                  )
                ],
              )

            ],

          ),
        ),
      ),
    ),
    );
  }
}