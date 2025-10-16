import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:p7/components/load_animation.dart';
import 'package:p7/components/my_button.dart';
import 'package:p7/components/my_text_field.dart';
import 'package:p7/service/auth.dart';
import 'register_profile_page.dart';

class RegisterPage extends StatefulWidget {
  final void Function()? onTap;
  const RegisterPage({super.key, required this.onTap});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _auth = Auth();
  final _formKey = GlobalKey<FormState>();

  final TextEditingController emailController = TextEditingController();
  final TextEditingController pwController = TextEditingController();
  final TextEditingController confirmController = TextEditingController();

  final FocusNode emailFocus = FocusNode();
  final FocusNode pwFocus = FocusNode();
  final FocusNode confirmFocus = FocusNode();

  bool _isLoading = false;

  @override
  void dispose() {
    emailController.dispose();
    pwController.dispose();
    confirmController.dispose();
    emailFocus.dispose();
    pwFocus.dispose();
    confirmFocus.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Введите email';
    }
    final emailReg = RegExp(r'^[\w\-.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailReg.hasMatch(value)) {
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

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Подтвердите пароль';
    }
    if (value != pwController.text) {
      return 'Пароли не совпадают';
    }
    return null;
  }

  void _continueToProfile() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Показываем загрузку только в UI кнопки
    setState(() => _isLoading = true);

    try {
      await _auth.registerEmailPassword(
        emailController.text.trim(),
        pwController.text,
      );

      if (mounted) {
        setState(() => _isLoading = false);

        // Переходим без анимации загрузки
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => RegisterProfilePage(
              email: emailController.text.trim(),
            ),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);

        String message;
        switch (e.code) {
          case 'email-already-in-use':
            message = 'Этот email уже используется';
            break;
          case 'invalid-email':
            message = 'Некорректный email';
            break;
          case 'weak-password':
            message = 'Слишком слабый пароль';
            break;
          default:
            message = 'Ошибка регистрации: ${e.message ?? e.code}';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Что-то пошло не так'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
                  Icons.person_add_rounded,
                  size: 72,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 30),
                Text(
                  "Создайте аккаунт",
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "Шаг 1 из 2",
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 40),

                MyTextField(
                  textEditingController: emailController,
                  obscureText: false,
                  hintText: "Email",
                  focusNode: emailFocus,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: (_) {
                    FocusScope.of(context).requestFocus(pwFocus);
                  },
                  validator: _validateEmail,
                ),

                const SizedBox(height: 15),

                MyTextField(
                  textEditingController: pwController,
                  obscureText: true,
                  hintText: "Пароль",
                  focusNode: pwFocus,
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: (_) {
                    FocusScope.of(context).requestFocus(confirmFocus);
                  },
                  validator: _validatePassword,
                ),

                const SizedBox(height: 15),

                MyTextField(
                  textEditingController: confirmController,
                  obscureText: true,
                  hintText: "Подтвердите пароль",
                  focusNode: confirmFocus,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _continueToProfile(),
                  validator: _validateConfirmPassword,
                ),

                const SizedBox(height: 30),

                MyButton(
                  onTap: _isLoading ? null : _continueToProfile,
                  text: _isLoading ? "Загрузка..." : "Далее",
                ),

                const SizedBox(height: 30),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Уже есть аккаунт?",
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: widget.onTap,
                      child: Text(
                        "Войти",
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