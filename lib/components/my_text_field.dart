import 'package:flutter/material.dart';

class MyTextField extends StatelessWidget {
  final TextEditingController textEditingController;
  final String hintText;
  final bool obscureText;
  final FocusNode? focusNode;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final void Function(String)? onFieldSubmitted;
  final String? Function(String?)? validator;

  const MyTextField({
    super.key,
    required this.textEditingController,
    required this.obscureText,
    required this.hintText,
    this.focusNode,
    this.keyboardType,
    this.textInputAction,
    this.onFieldSubmitted,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(  // Изменили на TextFormField
      controller: textEditingController,
      obscureText: obscureText,
      focusNode: focusNode,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onFieldSubmitted: onFieldSubmitted,
      validator: validator,
      decoration: InputDecoration(
        //unselected
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.tertiary,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        //Selected
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.onSurface,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        // Добавили стиль для ошибок
        errorBorder: OutlineInputBorder(
          borderSide: const BorderSide(
            color: Colors.red,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderSide: const BorderSide(
            color: Colors.red,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        fillColor: Theme.of(context).colorScheme.onSecondary,
        filled: true,
        hintText: hintText,
        hintStyle: TextStyle(color: Theme.of(context).colorScheme.primary),
      ),
    );
  }
}