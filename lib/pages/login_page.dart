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
  final _formKey = GlobalKey<FormState>();

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final FocusNode emailFocus = FocusNode();
  final FocusNode passwordFocus = FocusNode();

  bool _isLoading = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    emailFocus.dispose();
    passwordFocus.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Введите email';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Некорректный email';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Введите пароль';
    }
    if (value.length < 6) {
      return 'Минимум 6 символов';
    }
    return null;
  }

  void login() async {
    // Убираем фокус с полей (закрываем клавиатуру)
    FocusScope.of(context).unfocus();

    // Валидация формы
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);
    showLoad(context);

    try {
      await _auth.loginEmailPassword(
        emailController.text.trim(),
        passwordController.text,
      );
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'user-not-found':
          message = 'Пользователь не найден';
          break;
        case 'wrong-password':
          message = 'Неверный пароль';
          break;
        case 'invalid-email':
          message = 'Некорректный email';
          break;
        case 'user-disabled':
          message = 'Аккаунт заблокирован';
          break;
        case 'too-many-requests':
          message = 'Слишком много попыток. Попробуйте позже';
          break;
        default:
          message = 'Ошибка входа: ${e.message ?? e.code}';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Что-то пошло не так. Проверьте интернет'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        hideLoad(context);
        setState(() => _isLoading = false);
      }
    }
  }

  void _showForgotPasswordDialog() {
    final resetEmailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Восстановление пароля'),
        content: TextField(
          controller: resetEmailController,
          decoration: const InputDecoration(
            hintText: 'Введите ваш email',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.emailAddress,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await FirebaseAuth.instance.sendPasswordResetEmail(
                  email: resetEmailController.text.trim(),
                );
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Письмо отправлено на почту'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Ошибка отправки'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Отправить'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 25.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 50),
                Icon(
                  Icons.lock_open_rounded,
                  size: 72,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 50),
                Text(
                  "С возвращением!",
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "Войдите, чтобы продолжить",
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 50),

                MyTextField(
                  textEditingController: emailController,
                  obscureText: false,
                  hintText: "Email",
                  focusNode: emailFocus,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: (_) {
                    FocusScope.of(context).requestFocus(passwordFocus);
                  },
                  validator: _validateEmail,
                ),

                const SizedBox(height: 10),

                MyTextField(
                  textEditingController: passwordController,
                  obscureText: true,
                  hintText: "Пароль",
                  focusNode: passwordFocus,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => login(),
                  validator: _validatePassword,
                ),

                const SizedBox(height: 10),

                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: _showForgotPasswordDialog,
                    child: Text(
                      "Забыли пароль?",
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                MyButton(
                  onTap: _isLoading ? null : login,
                  text: _isLoading ? "Вход..." : "Войти",
                ),

                const SizedBox(height: 50),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Нет аккаунта?",
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: widget.onTap,
                      child: Text(
                        "Зарегистрироваться",
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 50),
              ],
            ),
          ),
        ),
      ),
    );
  }
}