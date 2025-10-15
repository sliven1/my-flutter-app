import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:p7/components/load_animation.dart';
import 'package:p7/service/auth.dart';
import 'package:p7/service/databases.dart';
import 'package:intl/intl.dart';
import '../components/my_button.dart';
import '../components/my_text_field.dart';

class RegisterPage extends StatefulWidget {
  final void Function()? onTap;
  const RegisterPage({super.key, required this.onTap});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {


  final _auth = Auth();
  final _db = Databases();



  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController pwController = TextEditingController();
  final TextEditingController confirmController = TextEditingController();

  DateTime? _birthDate;


  void register() async {
    final name    = nameController.text.trim();
    final email   = emailController.text.trim();
    final pw      = pwController.text;
    final confirm = confirmController.text;


    if ([name, email, pw, confirm].any((field) => field.isEmpty)) {
      await showDialog(
        context: context,
        builder: (_) => const AlertDialog(
          title: Text('All fields are required'),
        ),
      );
      return;
    }


    final digitReg = RegExp(r'\d');
    if (digitReg.hasMatch(name)) {
      await showDialog(
        context: context,
        builder: (_) => const AlertDialog(
          title: Text('Name cannot contain numbers'),
        ),
      );
      return;
    }


    final emailReg = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailReg.hasMatch(email)) {
      await showDialog(
        context: context,
        builder: (_) => const AlertDialog(
          title: Text('Please enter a valid email'),
        ),
      );
      return;
    }


    if (pw.length < 6) {
      await showDialog(
        context: context,
        builder: (_) => const AlertDialog(
          title: Text('Password must be at least 6 characters'),
        ),
      );
      return;
    }


    if (pw != confirm) {
      await showDialog(
        context: context,
        builder: (_) => const AlertDialog(
          title: Text('Passwords do not match'),
        ),
      );
      return;
    }

    // 5) Age must be an integer between 1 and 100
    final today = DateTime.now();
    var age = today.year - _birthDate!.year;
    if (today.month < _birthDate!.month ||
        (today.month == _birthDate!.month && today.day < _birthDate!.day)) {
      age--;
    }
    if(age<1 || age>100){
      print('Age must be between 1 and 100');
      return;
    }


    showLoad(context);
    try {
      await _auth.registerEmailPassword(email, pw);
      // On success AuthGate will switch screens automatically
    } on FirebaseAuthException catch (e) {
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Registration Error'),
          content: Text(e.message ?? e.code),
        ),
      );
    } catch (e) {
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Something Went Wrong'),
          content: Text(e.toString()),
        ),
      );
    } finally {
      if (mounted) hideLoad(context);
      await _db.saveInfoInFirebase(
          name: nameController.text,
          email: emailController.text,
          birthDate: _birthDate!);
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
                const SizedBox(height: 10),
                Icon(
                  Icons.lock,
                  size: 72,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 50),
                Text("Join the hive—build your network today",
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 50),

                MyTextField(
                  textEditingController: nameController,
                  obscureText: false,
                  hintText: "Enter name",
                ),

                const SizedBox(height: 10),

                MyTextField(
                  textEditingController: emailController,
                  obscureText: false,
                  hintText: "Enter email",
                ),

                const SizedBox(height: 10),

                MyTextField(
                  textEditingController: pwController,
                  obscureText: true,
                  hintText: "Enter password",
                ),

                const SizedBox(height: 10),

                MyTextField(
                  textEditingController: confirmController,
                  obscureText: true,
                  hintText: "Confirm password",
                ),

                const SizedBox(height: 10),

                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime(DateTime.now().year - 18),
                      firstDate: DateTime(1900),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null && mounted) {
                      setState(() => _birthDate = picked);
                    }
                  },
                  child: Container(
                    height: 50,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _birthDate == null
                          ? 'Select your birth date'
                          : DateFormat.yMMMMd().format(_birthDate!),
                      style: TextStyle(
                        color: _birthDate == null
                            ? Colors.grey
                            : Theme.of(context).colorScheme.onSurface,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                MyButton(
                    onTap: register,
                    text: "Register"),

                const SizedBox(height: 50),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Already a member?", style: TextStyle(color: Theme.of(context).colorScheme.primary),),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: widget.onTap,
                      child: Text("Login now",  style: TextStyle(color: Theme.of(context).colorScheme.primary,
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