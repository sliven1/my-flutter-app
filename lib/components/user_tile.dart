import 'package:flutter/material.dart';
import 'package:p7/components/user_avatar.dart';

class UserTile extends StatelessWidget {
  final String text;
  final String? avatarUrl;
  final String? subtitle;
  final void Function()? onTap;

  const UserTile({
    super.key,
    required this.text,
    required this.avatarUrl,
    this.subtitle,
    required this.onTap,
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
        margin: const EdgeInsets.symmetric(horizontal: 25),
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            UserAvatar(
              avatarUrl: avatarUrl,
              size: 60,
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    text,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 18,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
