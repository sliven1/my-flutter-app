import 'package:flutter/material.dart';

class MyTextField extends StatelessWidget {
  final TextEditingController textEditingController;
  final String hintText;
  final bool obscureText;
  final FocusNode? focusNode;
  const MyTextField({
    super.key,
    required this.textEditingController,
    required this.obscureText,
    required this.hintText,
    this.focusNode
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: textEditingController,
      obscureText: obscureText,
      focusNode: focusNode,
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
        fillColor: Theme.of(context).colorScheme.onSecondary,
          filled: true,
          hintText: hintText,
        hintStyle: TextStyle(color: Theme.of(context).colorScheme.primary),
      ),

    );

  }
}