import 'package:flutter/material.dart';
import 'package:p7/components/user_avatar.dart';

class  UserTile extends StatelessWidget {

  final String text;
  final String? avatarUrl;
  final void Function()? onTap;
  const UserTile({
  super.key,
    required this.text,
    required this.avatarUrl,
    required this.onTap
  });


  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
         border: Border(

             bottom: BorderSide(
             color: Theme.of(context).colorScheme.primaryContainer,
             width: 0.5,
             ),
         ),
        ),
        margin: EdgeInsets.symmetric(horizontal: 25),
        padding: EdgeInsets.all(10),
        child: Row(
          children: [
            UserAvatar(avatarUrl: avatarUrl, size: 60,),
            const SizedBox(width: 20,),
            Text(text, style: TextStyle(color: Theme.of(context).colorScheme.onSurface,
            fontSize: 18),)
          ],
        ),
      ),
    );
  }
}
