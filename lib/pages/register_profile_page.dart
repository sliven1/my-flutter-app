import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:p7/components/load_animation.dart';
import 'package:p7/components/my_button.dart';
import 'package:p7/components/my_text_field.dart';
import 'package:p7/service/databases.dart';
import 'package:p7/service/auth_gate.dart';

class RegisterProfilePage extends StatefulWidget {
  final String email;

  const RegisterProfilePage({
    super.key,
    required this.email,
  });

  @override
  State<RegisterProfilePage> createState() => _RegisterProfilePageState();
}

class _RegisterProfilePageState extends State<RegisterProfilePage> {
  final _db = Databases();
  final _formKey = GlobalKey<FormState>();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController cityController = TextEditingController();

  DateTime? _birthDate;
  String? _selectedRole;

  final List<String> _roles = [
    'Ученик',
    'Преподаватель',
  ];

  bool _isLoading = false;

  @override
  void dispose() {
    nameController.dispose();
    cityController.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Введите имя';
    }
    final digitReg = RegExp(r'\d');
    if (digitReg.hasMatch(value)) {
      return 'Имя не может содержать цифры';
    }
    if (value.length < 2) {
      return 'Имя слишком короткое';
    }
    return null;
  }

  String? _validateCity(String? value) {
    if (value == null || value.isEmpty) {
      return 'Введите город';
    }
    if (value.length < 2) {
      return 'Название города слишком короткое';
    }
    return null;
  }

  int _calculateAge(DateTime birthDate) {
    final today = DateTime.now();
    var age = today.year - birthDate.year;
    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  void _completeRegistration() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_birthDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Выберите дату рождения'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final age = _calculateAge(_birthDate!);
    if (age < 1 || age > 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Возраст должен быть от 1 до 100 лет'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Выберите роль'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    showLoad(context);

    try {
      // Сохраняем данные профиля в Firebase
      await _db.saveInfoInFirebase(
        name: nameController.text.trim(),
        email: widget.email,
        birthDate: _birthDate!,
        city: cityController.text.trim(),
        role: _selectedRole!,
      );

      if (mounted) {
        hideLoad(context);
        setState(() => _isLoading = false);

        // Показываем успешное сообщение
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Регистрация завершена!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
          ),
        );

        // Ждем немного и AuthGate автоматически перенаправит
        await Future.delayed(const Duration(milliseconds: 500));

        // Если не сработало автоматически, перезагружаем страницу
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const AuthGate()),
                (route) => false,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        hideLoad(context);
        setState(() => _isLoading = false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка сохранения: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _selectBirthDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(DateTime.now().year - 18),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).colorScheme.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      setState(() => _birthDate = picked);
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
              children: [
                const SizedBox(height: 50),
                Icon(
                  Icons.account_circle_rounded,
                  size: 72,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 30),
                Text(
                  "Расскажите о себе",
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "Шаг 2 из 2",
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 40),

                // Имя
                MyTextField(
                  textEditingController: nameController,
                  obscureText: false,
                  hintText: "Ваше имя",
                  keyboardType: TextInputType.name,
                  textInputAction: TextInputAction.next,
                  validator: _validateName,
                ),

                const SizedBox(height: 15),

                // Город
                MyTextField(
                  textEditingController: cityController,
                  obscureText: false,
                  hintText: "Ваш город",
                  keyboardType: TextInputType.text,
                  textInputAction: TextInputAction.done,
                  validator: _validateCity,
                ),

                const SizedBox(height: 15),

                // Дата рождения
                GestureDetector(
                  onTap: _selectBirthDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.onSecondary,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _birthDate == null
                            ? Theme.of(context).colorScheme.tertiary
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _birthDate == null
                              ? 'Дата рождения'
                              : DateFormat('dd.MM.yyyy').format(_birthDate!),
                          style: TextStyle(
                            color: _birthDate == null
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.onSurface,
                            fontSize: 16,
                          ),
                        ),
                        Icon(
                          Icons.calendar_today,
                          color: Theme.of(context).colorScheme.primary,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 15),

                // Роль
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.onSecondary,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _selectedRole == null
                          ? Theme.of(context).colorScheme.tertiary
                          : Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      hint: Text(
                        'Выберите роль',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      value: _selectedRole,
                      icon: Icon(
                        Icons.arrow_drop_down,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 16,
                      ),
                      dropdownColor:
                      Theme.of(context).colorScheme.onSecondary,
                      items: _roles.map((String role) {
                        return DropdownMenuItem<String>(
                          value: role,
                          child: Text(role),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() => _selectedRole = newValue);
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                MyButton(
                  onTap: _isLoading ? null : _completeRegistration,
                  text: _isLoading ? "Сохранение..." : "Завершить регистрацию",
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