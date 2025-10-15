import 'package:flutter/material.dart';

void showLoad(BuildContext context) {
  showDialog(
    context: context,
    builder: (_) => const Center(
      child: CircularProgressIndicator(),
    ),
  );
}
  void hideLoad(BuildContext context){
    Navigator.pop(context);
  }

